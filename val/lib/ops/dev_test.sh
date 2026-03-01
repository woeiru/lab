#!/bin/bash
# Development Operations Library Tests
# Tests for lib/ops/dev OpenCode session management helpers

# Test configuration
TEST_NAME="Development Operations Library"
TEST_CATEGORY="lib"

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"

# Lightweight aux function stubs for isolated module testing
aux_tec() { :; }
aux_use() { :; }
aux_info() { :; }
aux_warn() { :; }
aux_err() { :; }
aux_dbg() { :; }

if [[ -f "${LAB_ROOT}/lib/gen/aux" ]]; then
    source "${LAB_ROOT}/lib/gen/aux"
fi

# Load the library being tested
source "${LAB_ROOT}/lib/ops/dev"

_create_mock_opencode() {
    local test_env="$1"
    local db_path="$2"

    mkdir -p "$test_env/bin"
    cat > "$test_env/bin/opencode" << EOF
#!/bin/bash
if [[ "\$1" == "db" && "\$2" == "path" ]]; then
    echo "$db_path"
    exit 0
fi
exit 1
EOF
    chmod +x "$test_env/bin/opencode"
}

_create_test_db() {
    local db_path="$1"

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("CREATE TABLE project (id TEXT PRIMARY KEY, worktree TEXT)")
cur.execute("""
CREATE TABLE session (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    directory TEXT,
    title TEXT,
    time_updated INTEGER
)
""")

conn.commit()
PY
}

# Test: Development functions exist
test_dev_functions_exist() {
    declare -f dev_osv >/dev/null 2>&1 || return 1
    declare -f dev_omi >/dev/null 2>&1 || return 1
    declare -f dev_olb >/dev/null 2>&1 || return 1
    declare -f dev_oqu >/dev/null 2>&1 || return 1
    declare -f dev_oas >/dev/null 2>&1 || return 1
    return 0
}

# Test: Session overview lists rows from OpenCode DB
test_dev_overview_output() {
    local test_env
    test_env=$(create_test_env "dev_overview")
    local db_path="$test_env/opencode.db"

    _create_test_db "$db_path" || {
        cleanup_test_env "$test_env"
        return 1
    }

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("INSERT INTO project (id, worktree) VALUES (?, ?)", ("project_lab", "/home/es/lab"))
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_1111111111111111111111xyz", "project_lab", "/home/es/lab", "Sample Session", 1771759739789),
)
conn.commit()
PY

    _create_mock_opencode "$test_env" "$db_path"

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    local output
    output=$(dev_osv -x)
    local status=$?

    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$output" == *"suffix"* ]] || return 1
    [[ "$output" == *"xyz"* ]] || return 1
    [[ "$output" == *"Sample Session"* ]] || return 1
    return 0
}

# Test: Session overview attributes user from provider-scoped events
test_dev_overview_user_attribution() {
    local test_env
    test_env=$(create_test_env "dev_overview_user")
    local db_path="$test_env/opencode.db"

    _create_test_db "$db_path" || {
        cleanup_test_env "$test_env"
        return 1
    }

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("""
CREATE TABLE message (
    id TEXT PRIMARY KEY,
    session_id TEXT,
    time_created INTEGER,
    time_updated INTEGER,
    data TEXT
)
""")
    cur.execute("""
CREATE TABLE opencode_account_event (
    time_ms INTEGER,
    provider_id TEXT,
    account_key TEXT,
    account_label TEXT,
    source TEXT
)
""")

cur.execute("INSERT INTO project (id, worktree) VALUES (?, ?)", ("project_lab", "/home/es/lab"))

cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_aaaaaaaaaaaaaaaaaaaaaa11a", "project_lab", "/home/es/lab", "Session A", 1771759739789),
)
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_bbbbbbbbbbbbbbbbbbbbbb22b", "project_lab", "/home/es/lab", "Session B", 1771759749789),
)

cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_a_user", "ses_aaaaaaaaaaaaaaaaaaaaaa11a", 1771759000000, 1771759000000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_a_assistant", "ses_aaaaaaaaaaaaaaaaaaaaaa11a", 1771759001000, 1771759001000, '{"role":"assistant","providerID":"antigravity","modelID":"ag-model"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_b_user", "ses_bbbbbbbbbbbbbbbbbbbbbb22b", 1771760000000, 1771760000000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_b_assistant", "ses_bbbbbbbbbbbbbbbbbbbbbb22b", 1771760001000, 1771760001000, '{"role":"assistant","providerID":"openai","modelID":"oa-model"}'),
)

cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, source) VALUES (?, ?, ?, ?, ?)",
    (1771758000000, "antigravity", "alice@example.com", "alice@example.com", "opencode_event"),
)
cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, source) VALUES (?, ?, ?, ?, ?)",
    (1771759500000, "openai", "bob@example.com", "bob@example.com", "opencode_event"),
)

conn.commit()
PY

    _create_mock_opencode "$test_env" "$db_path"
    cat > "$test_env/bin/column" <<'EOF'
#!/bin/bash
cat
EOF
    chmod +x "$test_env/bin/column"

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    local output
    output=$(dev_osv -x)
    local status=$?

    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1

    local parsed
    parsed=$(python3 - "$output" <<'PY'
import csv
import io
import sys

txt = sys.argv[1]
reader = csv.DictReader(io.StringIO(txt), delimiter='\t')
rows = {row.get('title', ''): row for row in reader}

ok = (
    rows.get('Session A', {}).get('user') == 'alice@example.com' and
    rows.get('Session B', {}).get('user') == 'bob@example.com' and
    rows.get('Session A', {}).get('src') == 'opencode_event' and
    rows.get('Session B', {}).get('conf') == 'high' and
    'first_prompt_local' in (reader.fieldnames or [])
)
print('OK' if ok else 'FAIL')
PY
)

    [[ "$parsed" == "OK" ]]
}

# Test: Strict mode hides low-confidence fallback unless --best-effort is set
test_dev_overview_best_effort_flag() {
    local test_env
    test_env=$(create_test_env "dev_overview_best_effort")
    local db_path="$test_env/opencode.db"

    _create_test_db "$db_path" || {
        cleanup_test_env "$test_env"
        return 1
    }

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("""
CREATE TABLE message (
    id TEXT PRIMARY KEY,
    session_id TEXT,
    time_created INTEGER,
    time_updated INTEGER,
    data TEXT
)
""")
cur.execute("""
CREATE TABLE opencode_account_event (
    time_ms INTEGER,
    provider_id TEXT,
    account_key TEXT,
    account_label TEXT,
    source TEXT
)
""")

cur.execute("INSERT INTO project (id, worktree) VALUES (?, ?)", ("project_lab", "/home/es/lab"))
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_cccccccccccccccccccccc33c", "project_lab", "/home/es/lab", "Session C", 1771759749789),
)

cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_c_user", "ses_cccccccccccccccccccccc33c", 1771760000000, 1771760000000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_c_assistant", "ses_cccccccccccccccccccccc33c", 1771760001000, 1771760001000, '{"role":"assistant","providerID":"openai","modelID":"oa-model"}'),
)

cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, source) VALUES (?, ?, ?, ?, ?)",
    (1771761000000, "openai", "charlie@example.com", "charlie@example.com", "opencode_event"),
)

conn.commit()
PY

    _create_mock_opencode "$test_env" "$db_path"
    cat > "$test_env/bin/column" <<'EOF'
#!/bin/bash
cat
EOF
    chmod +x "$test_env/bin/column"

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    local strict_output best_output
    strict_output=$(dev_osv -x)
    local strict_status=$?
    best_output=$(dev_osv -x --best-effort)
    local best_status=$?

    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $strict_status -eq 0 ]] || return 1
    [[ $best_status -eq 0 ]] || return 1

    local parsed
    parsed=$(python3 - "$strict_output" "$best_output" <<'PY'
import csv
import io
import sys

strict_txt = sys.argv[1]
best_txt = sys.argv[2]

def row_map(text):
    reader = csv.DictReader(io.StringIO(text), delimiter='\t')
    return {row.get('title', ''): row for row in reader}

strict_rows = row_map(strict_txt)
best_rows = row_map(best_txt)

ok = (
    strict_rows.get('Session C', {}).get('user') == '(unknown)' and
    strict_rows.get('Session C', {}).get('conf') == 'none' and
    best_rows.get('Session C', {}).get('user') == 'charlie@example.com' and
    best_rows.get('Session C', {}).get('conf') == 'low'
)
print('OK' if ok else 'FAIL')
PY
)

    [[ "$parsed" == "OK" ]]
}

# Test: Provider mismatch does not cross-attribute users
test_dev_overview_provider_mismatch_no_cross_attribution() {
    local test_env
    test_env=$(create_test_env "dev_overview_provider_mismatch")
    local db_path="$test_env/opencode.db"

    _create_test_db "$db_path" || {
        cleanup_test_env "$test_env"
        return 1
    }

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("""
CREATE TABLE message (
    id TEXT PRIMARY KEY,
    session_id TEXT,
    time_created INTEGER,
    time_updated INTEGER,
    data TEXT
)
""")
cur.execute("""
CREATE TABLE opencode_account_event (
    time_ms INTEGER,
    provider_id TEXT,
    account_key TEXT,
    account_label TEXT,
    source TEXT
)
""")

cur.execute("INSERT INTO project (id, worktree) VALUES (?, ?)", ("project_lab", "/home/es/lab"))
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_dddddddddddddddddddddd44d", "project_lab", "/home/es/lab", "Session D", 1771759749789),
)

cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_d_user", "ses_dddddddddddddddddddddd44d", 1771760000000, 1771760000000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_d_assistant", "ses_dddddddddddddddddddddd44d", 1771760001000, 1771760001000, '{"role":"assistant","providerID":"openai","modelID":"oa-model"}'),
)

cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, source) VALUES (?, ?, ?, ?, ?)",
    (1771759000000, "antigravity", "alice@example.com", "alice@example.com", "opencode_event"),
)

conn.commit()
PY

    _create_mock_opencode "$test_env" "$db_path"
    cat > "$test_env/bin/column" <<'EOF'
#!/bin/bash
cat
EOF
    chmod +x "$test_env/bin/column"

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    local output
    output=$(dev_osv -x)
    local status=$?

    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1

    local parsed
    parsed=$(python3 - "$output" <<'PY'
import csv
import io
import sys

txt = sys.argv[1]
reader = csv.DictReader(io.StringIO(txt), delimiter='\t')
rows = {row.get('title', ''): row for row in reader}

ok = (
    rows.get('Session D', {}).get('user') == '(unknown)' and
    rows.get('Session D', {}).get('conf') == 'none'
)
print('OK' if ok else 'FAIL')
PY
)

    [[ "$parsed" == "OK" ]]
}

# Test: Best-effort mode can use legacy control_account timeline
test_dev_overview_best_effort_legacy_control_account() {
    local test_env
    test_env=$(create_test_env "dev_overview_best_effort_legacy")
    local db_path="$test_env/opencode.db"

    _create_test_db "$db_path" || {
        cleanup_test_env "$test_env"
        return 1
    }

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("""
CREATE TABLE message (
    id TEXT PRIMARY KEY,
    session_id TEXT,
    time_created INTEGER,
    time_updated INTEGER,
    data TEXT
)
""")
cur.execute("""
CREATE TABLE control_account (
    email TEXT,
    active INTEGER,
    time_updated INTEGER
)
""")

cur.execute("INSERT INTO project (id, worktree) VALUES (?, ?)", ("project_lab", "/home/es/lab"))
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_eeeeeeeeeeeeeeeeeeeeee55e", "project_lab", "/home/es/lab", "Session E", 1771759749789),
)

cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_e_user", "ses_eeeeeeeeeeeeeeeeeeeeee55e", 1771760000000, 1771760000000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_e_assistant", "ses_eeeeeeeeeeeeeeeeeeeeee55e", 1771760001000, 1771760001000, '{"role":"assistant","providerID":"openai","modelID":"oa-model"}'),
)

cur.execute(
    "INSERT INTO control_account (email, active, time_updated) VALUES (?, ?, ?)",
    ("legacy@example.com", 1, 1771759000000),
)

conn.commit()
PY

    _create_mock_opencode "$test_env" "$db_path"
    cat > "$test_env/bin/column" <<'EOF'
#!/bin/bash
cat
EOF
    chmod +x "$test_env/bin/column"

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    local strict_output best_output
    strict_output=$(dev_osv -x)
    local strict_status=$?
    best_output=$(dev_osv -x --best-effort)
    local best_status=$?

    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $strict_status -eq 0 ]] || return 1
    [[ $best_status -eq 0 ]] || return 1

    local parsed
    parsed=$(python3 - "$strict_output" "$best_output" <<'PY'
import csv
import io
import sys

strict_txt = sys.argv[1]
best_txt = sys.argv[2]

def row_map(text):
    reader = csv.DictReader(io.StringIO(text), delimiter='\t')
    return {row.get('title', ''): row for row in reader}

strict_rows = row_map(strict_txt)
best_rows = row_map(best_txt)

ok = (
    strict_rows.get('Session E', {}).get('user') == '(unknown)' and
    strict_rows.get('Session E', {}).get('conf') == 'none' and
    best_rows.get('Session E', {}).get('user') == 'legacy@example.com' and
    best_rows.get('Session E', {}).get('src') == 'control_account' and
    best_rows.get('Session E', {}).get('conf') == 'low'
)
print('OK' if ok else 'FAIL')
PY
)

    [[ "$parsed" == "OK" ]]
}

# Test: Session move updates project scope using ID suffix
test_dev_move_session_by_suffix() {
    local test_env
    test_env=$(create_test_env "dev_move")
    local db_path="$test_env/opencode.db"
    local target_scope="$test_env/labscope"

    mkdir -p "$target_scope"
    _create_test_db "$db_path" || {
        cleanup_test_env "$test_env"
        return 1
    }

    python3 - "$db_path" "$target_scope" <<'PY'
import sqlite3
import sys

db_path, target_scope = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("INSERT INTO project (id, worktree) VALUES (?, ?)", ("global", "/"))
cur.execute("INSERT INTO project (id, worktree) VALUES (?, ?)", ("project_lab", target_scope))
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_aaaaaaaaaaaaaaaaaaaaaabc", "global", "/home/es", "To Move", 1771759963324),
)
conn.commit()
PY

    _create_mock_opencode "$test_env" "$db_path"

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    dev_omi "$target_scope" "abc" >/dev/null 2>&1
    local move_status=$?

    PATH="$old_path"

    [[ $move_status -eq 0 ]] || {
        cleanup_test_env "$test_env"
        return 1
    }

    local check
    check=$(python3 - "$db_path" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
cur = conn.cursor()
cur.execute("SELECT project_id, directory FROM session WHERE id = ?", ("ses_aaaaaaaaaaaaaaaaaaaaaabc",))
row = cur.fetchone()
print(f"{row[0]}|{row[1]}")
PY
)

    cleanup_test_env "$test_env"
    [[ "$check" == "project_lab|$target_scope" ]]
}

# Test: Ambiguous suffix is rejected
test_dev_move_suffix_ambiguity() {
    local test_env
    test_env=$(create_test_env "dev_ambiguity")
    local db_path="$test_env/opencode.db"
    local target_scope="$test_env/labscope"

    mkdir -p "$target_scope"
    _create_test_db "$db_path" || {
        cleanup_test_env "$test_env"
        return 1
    }

    python3 - "$db_path" "$target_scope" <<'PY'
import sqlite3
import sys

db_path, target_scope = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("INSERT INTO project (id, worktree) VALUES (?, ?)", ("project_lab", target_scope))
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_xxxxxxxxxxxxxxxxxxxxxxyyz", "project_lab", "/home/es", "A", 1771759963324),
)
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_yyyyyyyyyyyyyyyyyyyyyyyz", "project_lab", "/home/es", "B", 1771759963325),
)
conn.commit()
PY

    _create_mock_opencode "$test_env" "$db_path"

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    dev_omi "$target_scope" "yyz" >/dev/null 2>&1
    local status=$?

    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 1 ]]
}

_create_mock_accounts_json() {
    local accounts_path="$1"

    cat > "$accounts_path" <<'JSON'
{
  "version": 4,
  "accounts": [
    {
      "email": "alice@example.com",
      "addedAt": 1771698399512,
      "lastUsed": 1771778285222,
      "enabled": true,
      "rateLimitResetTimes": {},
      "cachedQuota": {
        "gemini-pro": {
          "remainingFraction": 1,
          "resetTime": "2099-12-31T23:59:59Z",
          "modelCount": 5
        },
        "claude": {
          "remainingFraction": 0.4,
          "resetTime": "2099-12-31T23:59:59Z",
          "modelCount": 2
        }
      },
      "cachedQuotaUpdatedAt": 1771778286288
    },
    {
      "email": "bob@example.com",
      "addedAt": 1771758176986,
      "lastUsed": 1771778313369,
      "enabled": true,
      "rateLimitResetTimes": {},
      "cachedQuota": {
        "gemini-pro": {
          "remainingFraction": 0.8,
          "resetTime": "2099-12-31T23:59:59Z",
          "modelCount": 5
        },
        "claude": {
          "remainingFraction": 1,
          "resetTime": "2099-12-31T23:59:59Z",
          "modelCount": 2
        }
      },
      "cachedQuotaUpdatedAt": 1771778293299
    }
  ],
  "activeIndex": 0,
  "activeIndexByFamily": {
    "claude": 0,
    "gemini": 0
  }
}
JSON
}

_create_test_db_with_messages() {
    local db_path="$1"

    python3 - "$db_path" <<'PY'
import sqlite3
import sys
import json

db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("CREATE TABLE IF NOT EXISTS project (id TEXT PRIMARY KEY, worktree TEXT)")
cur.execute("""
CREATE TABLE IF NOT EXISTS session (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    directory TEXT,
    title TEXT,
    time_updated INTEGER
)
""")
cur.execute("""
CREATE TABLE IF NOT EXISTS message (
    id TEXT PRIMARY KEY,
    session_id TEXT,
    time_created INTEGER,
    time_updated INTEGER,
    data TEXT
)
""")

for i in range(3):
    msg_data = json.dumps({
        "role": "assistant",
        "modelID": "antigravity-claude-opus-4-6-thinking",
        "providerID": "google",
        "tokens": {"input": 1000, "output": 200, "cache": {"read": 500, "write": 0}}
    })
    cur.execute(
        "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
        (f"msg_test_{i}", "ses_test", 1771778282110 + i, 1771778282110 + i, msg_data)
    )

conn.commit()
PY
}

# Test: dev_olb rejects missing -x flag
test_dev_olb_requires_flag() {
    dev_olb >/dev/null 2>&1
    [[ $? -eq 1 ]]
}

# Test: dev_olb renders dashboard with mock accounts JSON
test_dev_olb_renders_dashboard() {
    local test_env
    test_env=$(create_test_env "dev_olb_render")
    local accounts_path="$test_env/config/opencode/antigravity-accounts.json"
    local db_path="$test_env/opencode.db"

    mkdir -p "$test_env/config/opencode"
    _create_mock_accounts_json "$accounts_path"
    _create_test_db_with_messages "$db_path"
    _create_mock_opencode "$test_env" "$db_path"

    local old_home="$HOME"
    local old_path="$PATH"
    export HOME="$test_env"
    PATH="$test_env/bin:$PATH"

    # Override the config path by pointing HOME to test_env
    # The accounts file is at $HOME/.config/opencode/antigravity-accounts.json
    mkdir -p "$test_env/.config/opencode"
    cp "$accounts_path" "$test_env/.config/opencode/antigravity-accounts.json"

    local output
    output=$(dev_olb -x 2>/dev/null)
    local status=$?

    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$output" == *"alice@example.com"* ]] || return 1
    [[ "$output" == *"bob@example.com"* ]] || return 1
    [[ "$output" == *"ROUTING"* ]] || return 1
    [[ "$output" == *"claude"* ]] || return 1
    return 0
}

# Test: dev_olb includes model usage from database
test_dev_olb_shows_model_usage() {
    local test_env
    test_env=$(create_test_env "dev_olb_usage")
    local db_path="$test_env/opencode.db"

    mkdir -p "$test_env/.config/opencode"
    _create_mock_accounts_json "$test_env/.config/opencode/antigravity-accounts.json"
    _create_test_db_with_messages "$db_path"
    _create_mock_opencode "$test_env" "$db_path"

    local old_home="$HOME"
    local old_path="$PATH"
    export HOME="$test_env"
    PATH="$test_env/bin:$PATH"

    local output
    output=$(dev_olb -x 2>/dev/null)
    local status=$?

    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$output" == *"MODEL USAGE"* ]] || return 1
    [[ "$output" == *"antigravity-claude-opus-4-6-thinking"* ]] || return 1
    return 0
}

# Test: dev_olb --watch rejects missing interval
test_dev_olb_watch_requires_interval() {
    dev_olb --watch >/dev/null 2>&1
    [[ $? -eq 1 ]]
}

# Test: dev_olb --watch rejects non-numeric interval
test_dev_olb_watch_rejects_bad_interval() {
    dev_olb --watch abc >/dev/null 2>&1
    [[ $? -eq 1 ]]
}

# Test: dev_oas rejects wrong parameter count
test_dev_oas_requires_params() {
    dev_oas >/dev/null 2>&1
    [[ $? -eq 1 ]]
}

# Test: dev_oas rejects non-numeric account
test_dev_oas_rejects_bad_account() {
    dev_oas "claude" "abc" >/dev/null 2>&1
    [[ $? -eq 1 ]]
}

# Test: dev_oas switches account for a family
test_dev_oas_switches_family() {
    local test_env
    test_env=$(create_test_env "dev_oas_switch")

    mkdir -p "$test_env/.config/opencode"
    _create_mock_accounts_json "$test_env/.config/opencode/antigravity-accounts.json"

    local old_home="$HOME"
    export HOME="$test_env"

    local output
    output=$(dev_oas "claude" "2" 2>/dev/null)
    local status=$?

    # Verify the JSON was updated
    local new_index=""
    if [[ $status -eq 0 ]]; then
        new_index=$(python3 -c "
import json
with open('$test_env/.config/opencode/antigravity-accounts.json') as f:
    data = json.load(f)
print(data.get('activeIndexByFamily', {}).get('claude', -1))
")
    fi

    export HOME="$old_home"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$output" == *"bob@example.com"* ]] || return 1
    [[ "$new_index" == "1" ]] || return 1
    return 0
}

# Test: dev_oas rejects out-of-range account number
test_dev_oas_rejects_out_of_range() {
    local test_env
    test_env=$(create_test_env "dev_oas_range")

    mkdir -p "$test_env/.config/opencode"
    _create_mock_accounts_json "$test_env/.config/opencode/antigravity-accounts.json"

    local old_home="$HOME"
    export HOME="$test_env"

    dev_oas "claude" "5" >/dev/null 2>&1
    local status=$?

    export HOME="$old_home"
    cleanup_test_env "$test_env"

    [[ $status -eq 1 ]]
}

# Test: dev_oas rejects unknown family
test_dev_oas_rejects_unknown_family() {
    local test_env
    test_env=$(create_test_env "dev_oas_unknown")

    mkdir -p "$test_env/.config/opencode"
    _create_mock_accounts_json "$test_env/.config/opencode/antigravity-accounts.json"

    local old_home="$HOME"
    export HOME="$test_env"

    dev_oas "nonexistent" "1" >/dev/null 2>&1
    local status=$?

    export HOME="$old_home"
    cleanup_test_env "$test_env"

    [[ $status -eq 1 ]]
}

# Test: dev_oas creates a backup before modifying
test_dev_oas_creates_backup() {
    local test_env
    test_env=$(create_test_env "dev_oas_backup")

    mkdir -p "$test_env/.config/opencode"
    _create_mock_accounts_json "$test_env/.config/opencode/antigravity-accounts.json"

    local old_home="$HOME"
    export HOME="$test_env"

    dev_oas "claude" "2" >/dev/null 2>&1
    local status=$?

    local backup_count
    backup_count=$(ls "$test_env/.config/opencode"/antigravity-accounts.json.backup.* 2>/dev/null | wc -l)

    export HOME="$old_home"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ $backup_count -ge 1 ]] || return 1
    return 0
}

# Test: dev_oas records account attribution event when OpenCode DB is available
test_dev_oas_records_account_event() {
    local test_env
    test_env=$(create_test_env "dev_oas_account_event")
    local db_path="$test_env/opencode.db"

    mkdir -p "$test_env/.config/opencode"
    _create_mock_accounts_json "$test_env/.config/opencode/antigravity-accounts.json"
    _create_mock_opencode "$test_env" "$db_path"

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
conn.commit()
conn.close()
PY

    local old_home="$HOME"
    local old_path="$PATH"
    export HOME="$test_env"
    PATH="$test_env/bin:$PATH"

    dev_oas "claude" "2" >/dev/null 2>&1
    local status=$?

    local event_row=""
    if [[ $status -eq 0 ]]; then
        event_row=$(python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute(
    """
    SELECT provider_id, account_key, account_label, event_type, source
    FROM opencode_account_event
    ORDER BY time_ms DESC
    LIMIT 1
    """
)
row = cur.fetchone()
conn.close()
print("|".join(row) if row else "")
PY
)
    fi

    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$event_row" == "antigravity|bob@example.com|bob@example.com|account_selected|manual_switch" ]] || return 1
    return 0
}

# Main test execution
main() {
    test_header "$TEST_NAME"

    run_test test_dev_functions_exist
    run_test test_dev_overview_output
    run_test test_dev_overview_user_attribution
    run_test test_dev_overview_best_effort_flag
    run_test test_dev_overview_provider_mismatch_no_cross_attribution
    run_test test_dev_overview_best_effort_legacy_control_account
    run_test test_dev_move_session_by_suffix
    run_test test_dev_move_suffix_ambiguity
    run_test test_dev_olb_requires_flag
    run_test test_dev_olb_renders_dashboard
    run_test test_dev_olb_shows_model_usage
    run_test test_dev_olb_watch_requires_interval
    run_test test_dev_olb_watch_rejects_bad_interval
    run_test test_dev_oqu_requires_flag
    run_test test_dev_oqu_renders_dashboard
    run_test test_dev_oqu_watch_requires_interval
    run_test test_dev_oqu_watch_rejects_bad_interval
    run_test test_dev_oas_requires_params
    run_test test_dev_oas_rejects_bad_account
    run_test test_dev_oas_switches_family
    run_test test_dev_oas_rejects_out_of_range
    run_test test_dev_oas_rejects_unknown_family
    run_test test_dev_oas_creates_backup
    run_test test_dev_oas_records_account_event

    test_footer
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
