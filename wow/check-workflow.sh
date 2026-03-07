#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if REPO_ROOT="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  REPO_ROOT="$(cd "$ROOT/.." >/dev/null 2>&1 && pwd)"
fi
failures=0
declare -A ORCH_CHILD_FILE_BY_NODE=()
declare -A ORCH_CHILD_DEPS_BY_NODE=()
declare -A ORCH_NODE_STATE=()
declare -A ORCH_CYCLE_REPORTED=()
declare -A COMPLETED_BUNDLE_FOLDER_BY_SLUG=()

is_markdown_doc() {
  local file="$1"
  [[ "$file" == *.md ]] && [[ ! "$(basename "$file")" =~ ^([0-9]{8}-[0-9]{4}_)?README\.md$ ]]
}

is_work_item_doc() {
  local file="$1"
  [[ "$file" == *.md ]] || return 1
  [[ "$(basename "$file")" == "README.md" ]] && return 1
  [[ "$(basename "$file")" == "AGENTS.md" ]] && return 1

  case "$file" in
    "$ROOT"/inbox/* | \
      "$ROOT"/queue/* | \
      "$ROOT"/active/* | \
      "$ROOT"/completed/* | \
      "$ROOT"/dismissed/* | \
      "$ROOT"/experiments/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

check_timestamp_prefix() {
  local file="$1"
  local base
  base="$(basename "$file")"
  if [[ ! "$base" =~ ^[0-9]{8}-[0-9]{4}_.+ ]]; then
    printf 'FAIL timestamp prefix: %s\n' "$file"
    failures=$((failures + 1))
  fi
}

get_header_field_value() {
  local file="$1"
  local field="$2"
  local line
  local line_count=0

  while IFS= read -r line; do
    line_count=$((line_count + 1))

    if [[ "$line" =~ ^##[[:space:]] ]]; then
      break
    fi

    if [[ "$line" =~ ^-[[:space:]]${field}:[[:space:]]*(.*)$ ]]; then
      printf '%s\n' "${BASH_REMATCH[1]}"
      return 0
    fi

    if ((line_count >= 40)); then
      break
    fi
  done < "$file"

  return 1
}

check_header() {
  local file="$1"
  local missing=()
  local field

  for field in Status Owner Started Updated Links; do
    get_header_field_value "$file" "$field" >/dev/null || missing+=("$field")
  done

  if ((${#missing[@]} > 0)); then
    printf 'FAIL header: %s (missing: %s)\n' "$file" "${missing[*]}"
    failures=$((failures + 1))
  fi
}

expected_status_for_file() {
  local file="$1"

  case "$file" in
    "$ROOT"/inbox/*)
      printf 'inbox\n'
      ;;
    "$ROOT"/queue/*)
      printf 'queue\n'
      ;;
    "$ROOT"/active/*)
      printf 'active\n'
      ;;
    "$ROOT"/completed/*)
      printf 'completed\n'
      ;;
    "$ROOT"/dismissed/*)
      printf 'dismissed\n'
      ;;
    "$ROOT"/experiments/*)
      printf 'experiment\n'
      ;;
    *)
      return 1
      ;;
  esac
}

completed_folder_timestamp() {
  local folder="$1"

  if [[ "$folder" =~ ^([0-9]{8}-[0-9]{4})_.+ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi

  if [[ "$folder" =~ ^([0-9]{8}-[0-9]{4})-bundle-([a-z0-9]+(-[a-z0-9]+)*)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}

completed_bundle_slug() {
  local folder="$1"

  if [[ "$folder" =~ ^([0-9]{8}-[0-9]{4})-bundle-([a-z0-9]+(-[a-z0-9]+)*)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[2]}"
    return 0
  fi

  return 1
}

should_enforce_header_and_status() {
  local file="$1"

  case "$file" in
    "$ROOT"/active/waivers/*)
      return 1
      ;;
    "$ROOT"/inbox/* | "$ROOT"/queue/* | "$ROOT"/active/* | "$ROOT"/dismissed/*)
      return 0
      ;;
    "$ROOT"/completed/* | "$ROOT"/experiments/*)
      get_header_field_value "$file" "Status" >/dev/null
      return $?
      ;;
    *)
      return 1
      ;;
  esac
}

should_enforce_triage_design() {
  local file="$1"

  case "$file" in
    "$ROOT"/active/waivers/*)
      return 1
      ;;
    "$ROOT"/queue/* | "$ROOT"/active/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

check_triage_design_classification() {
  local file="$1"
  local line
  local in_triage=0
  local triage_sections=0
  local required_count=0
  local not_needed_count=0
  local legacy_count=0

  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]+Triage[[:space:]]+Decision[[:space:]]*$ ]]; then
      triage_sections=$((triage_sections + 1))
      in_triage=1
      continue
    fi

    if [[ "$line" =~ ^##[[:space:]] ]]; then
      in_triage=0
    fi

    if ((in_triage == 0)); then
      continue
    fi

    if [[ "$line" == *"Design: required"* ]]; then
      required_count=$((required_count + 1))
    fi

    if [[ "$line" == *"Design: not needed"* ]]; then
      not_needed_count=$((not_needed_count + 1))
    fi

    if [[ "$line" == *"Design required:"* ]]; then
      legacy_count=$((legacy_count + 1))
    fi
  done < "$file"

  if ((triage_sections == 0)); then
    printf 'FAIL triage decision missing: %s (add ## Triage Decision with canonical design token)\n' "$file"
    failures=$((failures + 1))
    return
  fi

  if ((triage_sections > 1)); then
    printf 'FAIL triage decision duplicate: %s (leave exactly one ## Triage Decision section)\n' "$file"
    failures=$((failures + 1))
    return
  fi

  local token_count
  token_count=$((required_count + not_needed_count))

  if ((token_count == 0)); then
    printf 'FAIL triage design token: %s (expected exactly one: "Design: required" or "Design: not needed")\n' "$file"
    failures=$((failures + 1))
  elif ((token_count > 1)); then
    printf 'FAIL triage design token: %s (found multiple canonical design tokens in ## Triage Decision)\n' "$file"
    failures=$((failures + 1))
  fi

  if ((legacy_count > 0)); then
    printf 'FAIL triage design legacy token: %s (replace "Design required: Yes/No" with canonical "Design: required" or "Design: not needed")\n' "$file"
    failures=$((failures + 1))
  fi
}

check_status_matches_folder() {
  local file="$1"
  local expected
  local actual

  expected="$(expected_status_for_file "$file" || true)"
  if [[ -z "$expected" ]]; then
    return 0
  fi

  actual="$(get_header_field_value "$file" "Status" || true)"

  if [[ -z "$actual" ]]; then
    printf 'FAIL status missing: %s\n' "$file"
    failures=$((failures + 1))
    return 0
  fi

  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL status mismatch: %s (expected: %s, found: %s)\n' "$file" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

check_completed_structure() {
  local file="$1"
  local rel
  local base
  local folder
  local folder_ts
  local file_ts
  local folder_key
  local file_key
  rel="${file#"$ROOT/completed/"}"

  if [[ "$rel" != */* ]]; then
    printf 'FAIL completed structure: %s (expected completed/<yyyymmdd-hhmm_topic>/<file>.md)\n' "$file"
    failures=$((failures + 1))
    return
  fi

  if [[ "$rel" == */*/* ]]; then
    printf 'FAIL completed structure: %s (too deep; expected one topic folder)\n' "$file"
    failures=$((failures + 1))
    return
  fi

  folder="${rel%%/*}"
  folder_ts="$(completed_folder_timestamp "$folder" || true)"
  if [[ -z "$folder_ts" ]]; then
    printf 'FAIL completed folder timestamp: %s (expected yyyymmdd-hhmm_<topic> or yyyymmdd-hhmm-bundle-<module-slug>)\n' "$file"
    failures=$((failures + 1))
    return
  fi

  base="$(basename "$file")"

  if [[ ! "$base" =~ ^([0-9]{8}-[0-9]{4})_.+ ]]; then
    return
  fi

  file_ts="${BASH_REMATCH[1]}"
  folder_key="${folder_ts//-/}"
  file_key="${file_ts//-/}"

  if [[ "$file_key" > "$folder_key" ]]; then
    printf 'FAIL completed folder chronology: %s (file timestamp %s is newer than folder completion timestamp %s)\n' "$file" "$file_ts" "$folder_ts"
    failures=$((failures + 1))
  fi
}

check_completed_topic_folder() {
  local dir="$1"
  local folder
  local bundle_slug=""
  local existing_dir=""
  local md_files=()
  local had_nullglob=0

  folder="$(basename "$dir")"
  if ! completed_folder_timestamp "$folder" >/dev/null; then
    printf 'FAIL completed topic folder: %s (expected yyyymmdd-hhmm_<topic> or yyyymmdd-hhmm-bundle-<module-slug>)\n' "$dir"
    failures=$((failures + 1))
  fi

  bundle_slug="$(completed_bundle_slug "$folder" || true)"
  if [[ -n "$bundle_slug" ]]; then
    existing_dir="${COMPLETED_BUNDLE_FOLDER_BY_SLUG[$bundle_slug]:-}"
    if [[ -n "$existing_dir" ]] && [[ "$existing_dir" != "$dir" ]]; then
      printf 'FAIL completed bundle duplicate: %s and %s (reuse a single stable folder for module slug: %s)\n' "$dir" "$existing_dir" "$bundle_slug"
      failures=$((failures + 1))
    else
      COMPLETED_BUNDLE_FOLDER_BY_SLUG[$bundle_slug]="$dir"
    fi
  fi

  shopt -q nullglob && had_nullglob=1
  shopt -s nullglob
  md_files=("$dir"/*.md)
  if ((had_nullglob == 0)); then
    shopt -u nullglob
  fi

  if ((${#md_files[@]} == 0)); then
    printf 'FAIL completed topic folder empty: %s (expected at least one markdown artifact)\n' "$dir"
    failures=$((failures + 1))
  fi
}

check_inbox_names() {
  local file="$1"
  local base
  base="$(basename "$file")"
  if [[ ! "$base" =~ ^[0-9]{8}-[0-9]{4}_[a-z0-9-]+-(plan|issue|review|followup)\.md$ ]]; then
    printf 'FAIL inbox name: %s\n' "$file"
    failures=$((failures + 1))
  fi
}

check_dismissed_names() {
  local file="$1"
  local base
  base="$(basename "$file")"
  if [[ ! "$base" =~ ^[0-9]{8}-[0-9]{4}_[a-z0-9-]+-plan\.md$ ]]; then
    printf 'FAIL dismissed name: %s\n' "$file"
    failures=$((failures + 1))
  fi
}

check_dismissal_reason() {
  local file="$1"
  if ! grep -q "^## Dismissal Reason" "$file"; then
    printf 'FAIL dismissal reason: %s\n' "$file"
    failures=$((failures + 1))
  fi
}

check_legacy_completed_placeholder() {
  local file="$1"
  if grep -qE 'wow/completed/<topic>/|completed/<topic>/' "$file"; then
    printf 'FAIL legacy completed placeholder: %s (replace completed/<topic>/ with completed/yyyymmdd-hhmm_<topic>/)\n' "$file"
    failures=$((failures + 1))
  fi
}

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

get_section_field_value() {
  local file="$1"
  local section="$2"
  local field="$3"
  local line
  local in_section=0

  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]+${section}[[:space:]]*$ ]]; then
      in_section=1
      continue
    fi

    if ((in_section == 0)); then
      continue
    fi

    if [[ "$line" =~ ^##[[:space:]] ]]; then
      break
    fi

    if [[ "$line" =~ ^-[[:space:]]*${field}:[[:space:]]*(.*)$ ]]; then
      trim_value "${BASH_REMATCH[1]}"
      return 0
    fi

    if [[ "$line" =~ ^${field}:[[:space:]]*(.*)$ ]]; then
      trim_value "${BASH_REMATCH[1]}"
      return 0
    fi
  done < "$file"

  return 1
}

has_section_heading() {
  local file="$1"
  local section="$2"
  grep -q "^##[[:space:]]\+${section}[[:space:]]*$" "$file"
}

is_program_plan_doc() {
  local file="$1"
  local base
  base="$(basename "$file")"
  [[ "$base" == *-program-plan.md ]]
}

resolve_repo_path() {
  local value="$1"
  value="${value//\`/}"
  value="$(trim_value "$value")"

  if [[ "$value" == /* ]]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$REPO_ROOT/$value"
  fi
}

check_program_plan_sections() {
  local file="$1"
  local missing=()
  local section

  is_program_plan_doc "$file" || return 0

  for section in "Program Scope" "Global Invariants" "Workstreams" "Integration Cadence"; do
    has_section_heading "$file" "$section" || missing+=("$section")
  done

  if ((${#missing[@]} > 0)); then
    printf 'FAIL orchestration program sections: %s (missing: %s)\n' "$file" "${missing[*]}"
    failures=$((failures + 1))
  fi
}

check_orchestration_metadata() {
  local file="$1"
  local required_keys=("Program" "Workstream-ID" "Depends-On" "Touch-Set" "Merge-Gate" "Branch" "Worktree")
  local missing=()
  local key
  local program=""
  local workstream=""
  local depends=""
  local merge_gate=""
  local worktree=""
  local branch=""
  local program_abs=""
  local node_key=""
  local depends_normalized=""
  local dep

  has_section_heading "$file" "Orchestration Metadata" || return 0

  for key in "${required_keys[@]}"; do
    get_section_field_value "$file" "Orchestration Metadata" "$key" >/dev/null || missing+=("$key")
  done

  if ((${#missing[@]} > 0)); then
    printf 'FAIL orchestration metadata: %s (missing: %s)\n' "$file" "${missing[*]}"
    failures=$((failures + 1))
  fi

  program="$(get_section_field_value "$file" "Orchestration Metadata" "Program" || true)"
  workstream="$(get_section_field_value "$file" "Orchestration Metadata" "Workstream-ID" || true)"
  depends="$(get_section_field_value "$file" "Orchestration Metadata" "Depends-On" || true)"
  merge_gate="$(get_section_field_value "$file" "Orchestration Metadata" "Merge-Gate" || true)"
  branch="$(get_section_field_value "$file" "Orchestration Metadata" "Branch" || true)"
  worktree="$(get_section_field_value "$file" "Orchestration Metadata" "Worktree" || true)"

  if [[ -n "$program" ]]; then
    program_abs="$(resolve_repo_path "$program")"
    if [[ ! -f "$program_abs" ]]; then
      printf 'FAIL orchestration program path: %s (Program does not exist: %s)\n' "$file" "$program"
      failures=$((failures + 1))
    elif ! is_program_plan_doc "$program_abs"; then
      printf 'FAIL orchestration program path: %s (Program is not a -program-plan.md file: %s)\n' "$file" "$program"
      failures=$((failures + 1))
    fi
  fi

  if [[ -n "$workstream" ]] && [[ ! "$workstream" =~ ^WS-[0-9]{2,}$ ]]; then
    printf 'FAIL orchestration workstream id: %s (expected WS-<nn>, found: %s)\n' "$file" "$workstream"
    failures=$((failures + 1))
  fi

  if [[ -n "$merge_gate" ]] && [[ ! "$merge_gate" =~ ^(minimal|module|integration)$ ]]; then
    printf 'FAIL orchestration merge gate: %s (expected minimal|module|integration, found: %s)\n' "$file" "$merge_gate"
    failures=$((failures + 1))
  fi

  if [[ -z "$branch" ]]; then
    printf 'FAIL orchestration branch: %s (Branch must be non-empty)\n' "$file"
    failures=$((failures + 1))
  fi

  if [[ -n "$worktree" ]] && [[ "$worktree" != "none" ]] && [[ "$worktree" != /* ]]; then
    printf 'FAIL orchestration worktree: %s (expected absolute path or none, found: %s)\n' "$file" "$worktree"
    failures=$((failures + 1))
  fi

  depends_normalized="${depends// /}"
  if [[ -n "$depends_normalized" ]] && [[ "$depends_normalized" != "none" ]]; then
    IFS=',' read -r -a dep_arr <<< "$depends_normalized"
    for dep in "${dep_arr[@]}"; do
      if [[ ! "$dep" =~ ^WS-[0-9]{2,}$ ]]; then
        printf 'FAIL orchestration depends format: %s (invalid dependency token: %s)\n' "$file" "$dep"
        failures=$((failures + 1))
      fi
    done
  fi

  if [[ -n "$program_abs" ]] && [[ -n "$workstream" ]]; then
    node_key="$program_abs|$workstream"
    if [[ -n "${ORCH_CHILD_FILE_BY_NODE[$node_key]:-}" ]] && [[ "${ORCH_CHILD_FILE_BY_NODE[$node_key]}" != "$file" ]]; then
      printf 'FAIL orchestration duplicate workstream: %s and %s (same Program + Workstream-ID: %s)\n' "$file" "${ORCH_CHILD_FILE_BY_NODE[$node_key]}" "$workstream"
      failures=$((failures + 1))
    else
      ORCH_CHILD_FILE_BY_NODE[$node_key]="$file"
      ORCH_CHILD_DEPS_BY_NODE[$node_key]="${depends_normalized:-none}"
    fi
  fi
}

check_orchestration_relationships() {
  local node_key
  local program
  local workstream
  local deps
  local dep
  local dep_key

  for node_key in "${!ORCH_CHILD_FILE_BY_NODE[@]}"; do
    program="${node_key%%|*}"
    workstream="${node_key#*|}"
    deps="${ORCH_CHILD_DEPS_BY_NODE[$node_key]:-none}"

    if [[ "$deps" == "none" ]] || [[ -z "$deps" ]]; then
      continue
    fi

    IFS=',' read -r -a dep_arr <<< "$deps"
    for dep in "${dep_arr[@]}"; do
      dep_key="$program|$dep"
      if [[ "$dep" == "$workstream" ]]; then
        printf 'FAIL orchestration dependency self-reference: %s (%s depends on itself)\n' "${ORCH_CHILD_FILE_BY_NODE[$node_key]}" "$workstream"
        failures=$((failures + 1))
      elif [[ -z "${ORCH_CHILD_FILE_BY_NODE[$dep_key]:-}" ]]; then
        printf 'FAIL orchestration dependency missing: %s (Depends-On references unknown workstream %s for program %s)\n' "${ORCH_CHILD_FILE_BY_NODE[$node_key]}" "$dep" "${program#"$REPO_ROOT/"}"
        failures=$((failures + 1))
      fi
    done
  done

  ORCH_NODE_STATE=()
  ORCH_CYCLE_REPORTED=()
  for node_key in "${!ORCH_CHILD_FILE_BY_NODE[@]}"; do
    check_orchestration_cycle_from_node "$node_key"
  done
}

check_orchestration_cycle_from_node() {
  local node_key="$1"
  local state="${ORCH_NODE_STATE[$node_key]:-0}"
  local program
  local deps
  local dep
  local dep_key

  if [[ "$state" == "2" ]]; then
    return 0
  fi

  if [[ "$state" == "1" ]]; then
    if [[ -z "${ORCH_CYCLE_REPORTED[$node_key]:-}" ]]; then
      printf 'FAIL orchestration dependency cycle: %s (cycle detected around %s)\n' "${ORCH_CHILD_FILE_BY_NODE[$node_key]}" "${node_key#*|}"
      failures=$((failures + 1))
      ORCH_CYCLE_REPORTED[$node_key]=1
    fi
    return 0
  fi

  ORCH_NODE_STATE[$node_key]=1
  program="${node_key%%|*}"
  deps="${ORCH_CHILD_DEPS_BY_NODE[$node_key]:-none}"

  if [[ "$deps" != "none" ]] && [[ -n "$deps" ]]; then
    IFS=',' read -r -a dep_arr <<< "$deps"
    for dep in "${dep_arr[@]}"; do
      dep_key="$program|$dep"
      if [[ -n "${ORCH_CHILD_FILE_BY_NODE[$dep_key]:-}" ]]; then
        check_orchestration_cycle_from_node "$dep_key"
      fi
    done
  fi

  ORCH_NODE_STATE[$node_key]=2
}

while IFS= read -r file; do
  is_work_item_doc "$file" || continue
  check_timestamp_prefix "$file"
done < <(find "$ROOT" -type f | sort)

while IFS= read -r file; do
  is_markdown_doc "$file" || continue
  check_inbox_names "$file"
done < <(find "$ROOT/inbox" -type f | sort)

while IFS= read -r file; do
  is_work_item_doc "$file" || continue
  should_enforce_header_and_status "$file" || continue
  check_header "$file"
  check_status_matches_folder "$file"
done < <(find "$ROOT" -type f | sort)

while IFS= read -r file; do
  is_work_item_doc "$file" || continue
  should_enforce_triage_design "$file" || continue
  check_triage_design_classification "$file"
done < <(find "$ROOT" -type f | sort)

while IFS= read -r file; do
  is_markdown_doc "$file" || continue
  check_completed_structure "$file"
done < <(find "$ROOT/completed" -type f | sort)

while IFS= read -r dir; do
  check_completed_topic_folder "$dir"
done < <(find "$ROOT/completed" -mindepth 1 -maxdepth 1 -type d | sort)

while IFS= read -r file; do
  is_markdown_doc "$file" || continue
  check_dismissed_names "$file"
  check_dismissal_reason "$file"
done < <(find "$ROOT/dismissed" -type f | sort)

while IFS= read -r file; do
  is_work_item_doc "$file" || continue
  check_legacy_completed_placeholder "$file"
done < <(find "$ROOT" -type f | sort)

while IFS= read -r file; do
  is_work_item_doc "$file" || continue
  check_program_plan_sections "$file"
  check_orchestration_metadata "$file"
done < <(find "$ROOT" -type f | sort)

check_orchestration_relationships

if ((failures > 0)); then
  printf '\nWorkflow check failed with %d issue(s).\n' "$failures"
  exit 1
fi

printf 'Workflow check passed.\n'
