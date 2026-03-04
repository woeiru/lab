#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$ROOT/../.." >/dev/null 2>&1 && pwd)"
failures=0

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

get_updated_key() {
  local file="$1"
  local updated

  updated="$(get_header_field_value "$file" "Updated" || true)"
  if [[ -z "$updated" ]]; then
    return 1
  fi

  if [[ "$updated" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})[[:space:]]+([0-9]{2}):([0-9]{2}) ]]; then
    printf '%s%s%s%s%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}"
    return 0
  fi

  if [[ "$updated" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2}) ]]; then
    printf '%s%s%s0000\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
    return 0
  fi

  return 1
}

get_git_last_update_key() {
  local file="$1"
  local rel
  local key

  rel="${file#"$REPO_ROOT/"}"
  key="$(git -C "$REPO_ROOT" log --follow --diff-filter=AM -1 --format=%cd --date=format:%Y%m%d%H%M -- "$rel" 2>/dev/null || true)"

  if [[ "$key" =~ ^[0-9]{12}$ ]]; then
    printf '%s\n' "$key"
    return 0
  fi

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
  local updated_key
  local git_key
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
  if [[ ! "$folder" =~ ^([0-9]{8}-[0-9]{4})_.+ ]]; then
    printf 'FAIL completed folder timestamp: %s (expected yyyymmdd-hhmm_<topic>)\n' "$file"
    failures=$((failures + 1))
    return
  fi

  folder_ts="${BASH_REMATCH[1]}"
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

  updated_key="$(get_updated_key "$file" || true)"
  if [[ -n "$updated_key" ]] && [[ "$updated_key" > "$folder_key" ]]; then
    printf 'FAIL completed folder stale timestamp: %s (Updated header is newer than folder timestamp %s)\n' "$file" "$folder_ts"
    failures=$((failures + 1))
  fi

  git_key="$(get_git_last_update_key "$file" || true)"
  if [[ -n "$git_key" ]] && [[ "$git_key" > "$folder_key" ]]; then
    printf 'FAIL completed folder git timestamp: %s (last content update commit is newer than folder timestamp %s)\n' "$file" "$folder_ts"
    failures=$((failures + 1))
  fi
}

check_completed_topic_folder() {
  local dir="$1"
  local folder
  local md_files=()
  local had_nullglob=0

  folder="$(basename "$dir")"
  if [[ ! "$folder" =~ ^[0-9]{8}-[0-9]{4}_.+ ]]; then
    printf 'FAIL completed topic folder: %s (expected yyyymmdd-hhmm_<topic>)\n' "$dir"
    failures=$((failures + 1))
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
  if grep -qE 'doc/pro/completed/<topic>/|completed/<topic>/' "$file"; then
    printf 'FAIL legacy completed placeholder: %s (replace completed/<topic>/ with completed/yyyymmdd-hhmm_<topic>/)\n' "$file"
    failures=$((failures + 1))
  fi
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

if ((failures > 0)); then
  printf '\nWorkflow check failed with %d issue(s).\n' "$failures"
  exit 1
fi

printf 'Workflow check passed.\n'
