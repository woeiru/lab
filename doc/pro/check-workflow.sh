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

check_header() {
  local file="$1"
  local missing=()

  grep -q "^- Status:" "$file" || missing+=("Status")
  grep -q "^- Owner:" "$file" || missing+=("Owner")
  grep -q "^- Started:" "$file" || missing+=("Started")
  grep -q "^- Updated:" "$file" || missing+=("Updated")
  grep -q "^- Links:" "$file" || missing+=("Links")

  if ((${#missing[@]} > 0)); then
    printf 'FAIL header: %s (missing: %s)\n' "$file" "${missing[*]}"
    failures=$((failures + 1))
  fi
}

check_inbox_names() {
  local file="$1"
  local base
  base="$(basename "$file")"
  if [[ ! "$base" =~ ^[0-9]{8}-[0-9]{4}_[a-z0-9-]+-(plan|review|followup)\.md$ ]]; then
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
  check_header "$file"
done < <(find "$ROOT/inbox" -type f | sort)

while IFS= read -r file; do
  is_markdown_doc "$file" || continue
  check_dismissed_names "$file"
  check_header "$file"
  check_dismissal_reason "$file"
done < <(find "$ROOT/dismissed" -type f | sort)

if ((failures > 0)); then
  printf '\nWorkflow check failed with %d issue(s).\n' "$failures"
  exit 1
fi

printf 'Workflow check passed.\n'
