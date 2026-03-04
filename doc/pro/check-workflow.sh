#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
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

  local folder
  folder="${rel%%/*}"
  if [[ ! "$folder" =~ ^[0-9]{8}-[0-9]{4}_.+ ]]; then
    printf 'FAIL completed folder timestamp: %s (expected yyyymmdd-hhmm_<topic>)\n' "$file"
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

while IFS= read -r file; do
  is_markdown_doc "$file" || continue
  check_dismissed_names "$file"
  check_dismissal_reason "$file"
done < <(find "$ROOT/dismissed" -type f | sort)

if ((failures > 0)); then
  printf '\nWorkflow check failed with %d issue(s).\n' "$failures"
  exit 1
fi

printf 'Workflow check passed.\n'
