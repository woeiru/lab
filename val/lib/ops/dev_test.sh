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

_create_openai_auth_json() {
    local auth_path="$1"
    local account_id="$2"
    local email="$3"

    mkdir -p "$(dirname "$auth_path")"
    python3 - "$auth_path" "$account_id" "$email" <<'PY'
import base64
import json
import sys

auth_path = sys.argv[1]
account_id = sys.argv[2]
email = sys.argv[3]

header = {"alg": "none", "typ": "JWT"}
payload = {
    "https://api.openai.com/auth": {
        "chatgpt_account_id": account_id,
        "user_id": "user-test-123",
    },
    "https://api.openai.com/profile": {
        "email": email,
    },
}

def b64url(obj):
    raw = json.dumps(obj, separators=(",", ":")).encode("utf-8")
    return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")

token = f"{b64url(header)}.{b64url(payload)}.sig"

data = {
    "openai": {
        "type": "oauth",
        "access": token,
        "accountId": account_id,
    }
}

with open(auth_path, "w", encoding="utf-8") as f:
    json.dump(data, f)
PY
}

# Test: Development functions exist
test_dev_functions_exist() {
    declare -f dev_osv >/dev/null 2>&1 || return 1
    declare -f dev_omi >/dev/null 2>&1 || return 1
    declare -f dev_oac >/dev/null 2>&1 || return 1
    declare -f dev_oae >/dev/null 2>&1 || return 1
    declare -f dev_orr >/dev/null 2>&1 || return 1
    declare -f dev_otr >/dev/null 2>&1 || return 1
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

# Test: Session-bound attribution takes precedence over provider-wide fallback
test_dev_overview_session_bound_event_precedence() {
    local test_env
    test_env=$(create_test_env "dev_overview_session_bound")
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
    event_type TEXT,
    source TEXT,
    session_id TEXT
)
""")

cur.execute("INSERT INTO project (id, worktree) VALUES (?, ?)", ("project_lab", "/home/es/lab"))
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_sessionbound0000000001", "project_lab", "/home/es/lab", "Session Bound", 1771760100000),
)
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_providerwide0000000002", "project_lab", "/home/es/lab", "Session Provider Wide", 1771760200000),
)

cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_sb_user", "ses_sessionbound0000000001", 1771760000000, 1771760000000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_sb_assistant", "ses_sessionbound0000000001", 1771760001000, 1771760001000, '{"role":"assistant","providerID":"openai","modelID":"oa-model"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_pw_user", "ses_providerwide0000000002", 1771760005000, 1771760005000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_pw_assistant", "ses_providerwide0000000002", 1771760006000, 1771760006000, '{"role":"assistant","providerID":"openai","modelID":"oa-model"}'),
)

cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, event_type, source, session_id) VALUES (?, ?, ?, ?, ?, ?, ?)",
    (1771759999000, "openai", "puhachka@proton.me", "puhachka@proton.me", "account_selected", "opencode_runtime", "ses_sessionbound0000000001"),
)
cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, event_type, source, session_id) VALUES (?, ?, ?, ?, ?, ?, ?)",
    (1771759999500, "openai", "ometesu@proton.me", "ometesu@proton.me", "account_selected", "opencode_runtime", NULL),
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
    rows.get('Session Bound', {}).get('user') == 'puhachka@proton.me' and
    rows.get('Session Bound', {}).get('src') == 'runtime' and
    rows.get('Session Bound', {}).get('conf') == 'high' and
    rows.get('Session Provider Wide', {}).get('user') == 'ometesu@proton.me' and
    rows.get('Session Provider Wide', {}).get('conf') == 'high'
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

# Test: Google provider sessions map to antigravity attribution events
test_dev_overview_google_provider_maps_to_antigravity() {
    local test_env
    test_env=$(create_test_env "dev_overview_google_provider")
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
    ("ses_iiiiiiiiiiiiiiiiiiiiii99i", "project_lab", "/home/es/lab", "Session I", 1771764500000),
)

cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_i_user", "ses_iiiiiiiiiiiiiiiiiiiiii99i", 1771764000000, 1771764000000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_i_assistant", "ses_iiiiiiiiiiiiiiiiiiiiii99i", 1771764001000, 1771764001000, '{"role":"assistant","providerID":"google","modelID":"antigravity-claude-opus-4-6-thinking"}'),
)

cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, source) VALUES (?, ?, ?, ?, ?)",
    (1771763500000, "antigravity", "mapped@example.com", "mapped@example.com", "shell_wrapper"),
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
    rows.get('Session I', {}).get('user') == 'mapped@example.com' and
    rows.get('Session I', {}).get('src') == 'shell_wrapper' and
    rows.get('Session I', {}).get('conf') == 'high'
)
print('OK' if ok else 'FAIL')
PY
)

    [[ "$parsed" == "OK" ]]
}

# Test: Latest event before first prompt wins for repeated provider events
test_dev_overview_latest_event_before_prompt() {
    local test_env
    test_env=$(create_test_env "dev_overview_latest_event")
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
    ("ses_ffffffffffffffffffffff66f", "project_lab", "/home/es/lab", "Session F", 1771761000000),
)

cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_f_user", "ses_ffffffffffffffffffffff66f", 1771760000000, 1771760000000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_f_assistant", "ses_ffffffffffffffffffffff66f", 1771760001000, 1771760001000, '{"role":"assistant","providerID":"openai","modelID":"oa-model"}'),
)

cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, source) VALUES (?, ?, ?, ?, ?)",
    (1771758000000, "openai", "alice@example.com", "alice@example.com", "opencode_event"),
)
cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, source) VALUES (?, ?, ?, ?, ?)",
    (1771759500000, "openai", "bob@example.com", "bob@example.com", "opencode_event"),
)
cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, source) VALUES (?, ?, ?, ?, ?)",
    (1771760500000, "openai", "carol@example.com", "carol@example.com", "opencode_event"),
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
    rows.get('Session F', {}).get('user') == 'bob@example.com' and
    rows.get('Session F', {}).get('src') == 'opencode_event' and
    rows.get('Session F', {}).get('conf') == 'high'
)
print('OK' if ok else 'FAIL')
PY
)

    [[ "$parsed" == "OK" ]]
}

# Test: Mixed account_selected/token_refreshed timeline remains deterministic across providers
test_dev_overview_mixed_event_replay_deterministic() {
    local test_env
    test_env=$(create_test_env "dev_overview_mixed_event_replay")
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
    event_type TEXT,
    source TEXT,
    trace_id TEXT
)
""")

cur.execute("INSERT INTO project (id, worktree) VALUES (?, ?)", ("project_lab", "/home/es/lab"))
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_gggggggggggggggggggggg77g", "project_lab", "/home/es/lab", "Session G", 1771762000000),
)
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_hhhhhhhhhhhhhhhhhhhhhh88h", "project_lab", "/home/es/lab", "Session H", 1771763000000),
)

cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_g_user", "ses_gggggggggggggggggggggg77g", 1771761000000, 1771761000000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_g_assistant", "ses_gggggggggggggggggggggg77g", 1771761001000, 1771761001000, '{"role":"assistant","providerID":"openai","modelID":"oa-model"}'),
)

cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_h_user", "ses_hhhhhhhhhhhhhhhhhhhhhh88h", 1771762500000, 1771762500000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_h_assistant", "ses_hhhhhhhhhhhhhhhhhhhhhh88h", 1771762501000, 1771762501000, '{"role":"assistant","providerID":"antigravity","modelID":"ag-model"}'),
)

cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, event_type, source, trace_id) VALUES (?, ?, ?, ?, ?, ?, ?)",
    (1771760000000, "openai", "oa-old@example.com", "oa-old@example.com", "account_selected", "opencode_runtime", "trace-oa-1"),
)
cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, event_type, source, trace_id) VALUES (?, ?, ?, ?, ?, ?, ?)",
    (1771760500000, "openai", "oa-refresh@example.com", "oa-refresh@example.com", "token_refreshed", "connector_event", "trace-oa-2"),
)
cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, event_type, source, trace_id) VALUES (?, ?, ?, ?, ?, ?, ?)",
    (1771761500000, "openai", "oa-post@example.com", "oa-post@example.com", "account_selected", "opencode_runtime", "trace-oa-3"),
)

cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, event_type, source, trace_id) VALUES (?, ?, ?, ?, ?, ?, ?)",
    (1771761800000, "antigravity", "ag-old@example.com", "ag-old@example.com", "account_selected", "manual_switch", "trace-ag-1"),
)
cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, event_type, source, trace_id) VALUES (?, ?, ?, ?, ?, ?, ?)",
    (1771762400000, "antigravity", "ag-refresh@example.com", "ag-refresh@example.com", "token_refreshed", "connector_event", "trace-ag-2"),
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
    rows.get('Session G', {}).get('user') == 'oa-refresh@example.com' and
    rows.get('Session G', {}).get('src') == 'connector_event' and
    rows.get('Session G', {}).get('conf') == 'high' and
    rows.get('Session H', {}).get('user') == 'ag-refresh@example.com' and
    rows.get('Session H', {}).get('src') == 'connector_event' and
    rows.get('Session H', {}).get('conf') == 'high'
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

# Test: dev_olb applies denylist before rendering dashboard
test_dev_olb_applies_denylist_before_render() {
    local test_env
    test_env=$(create_test_env "dev_olb_denylist")

    mkdir -p "$test_env/.config/opencode"
    cat > "$test_env/.config/opencode/antigravity-accounts.json" <<'JSON'
{
  "accounts": [
    {"email": "alice@example.com", "enabled": true},
    {"email": "bob@example.com", "enabled": true}
  ],
  "activeIndex": 0,
  "activeIndexByFamily": {
    "claude": 0
  }
}
JSON

    cat > "$test_env/.config/opencode/antigravity-account-denylist.txt" <<'EOF'
alice@example.com
EOF

    local old_home="$HOME"
    export HOME="$test_env"

    dev_olb -x >/dev/null 2>&1
    local status=$?

    local state=""
    if [[ $status -eq 0 ]]; then
        state=$(python3 - "$test_env/.config/opencode/antigravity-accounts.json" <<'PY'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)

accounts = data.get('accounts', [])
print('{}|{}|{}'.format(
    accounts[0].get('enabled', True),
    data.get('activeIndex', -1),
    data.get('activeIndexByFamily', {}).get('claude', -1),
))
PY
)
    fi

    export HOME="$old_home"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$state" == "True|0|0" ]] || return 1
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

# Test: dev_oac requires explicit -x execution flag
test_dev_oac_requires_execute_flag() {
    dev_oac >/dev/null 2>&1
    [[ $? -eq 1 ]]
}

# Test: dev_oac remains stable across repeated external repopulation cycles
test_dev_oac_reconciles_repopulation_cycles() {
    local test_env
    test_env=$(create_test_env "dev_oac_repopulation")

    mkdir -p "$test_env/.config/opencode"
    cat > "$test_env/.config/opencode/antigravity-account-denylist.txt" <<'EOF'
# one blocked account per line
alice@example.com
EOF

    local old_home="$HOME"
    export HOME="$test_env"

    local status=0
    local cycle=0
    local output=""
    local state=""
    for cycle in 1 2 3; do
        _create_mock_accounts_json "$test_env/.config/opencode/antigravity-accounts.json"

        output=$(dev_oac -x 2>/dev/null)
        status=$?
        [[ $status -eq 0 ]] || break

        state=$(python3 - "$test_env/.config/opencode/antigravity-accounts.json" <<'PY'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)

accounts = data.get('accounts', [])
print('{}|{}|{}|{}'.format(
    len(accounts),
    accounts[0].get('email', '') if accounts else '',
    data.get('activeIndex', -1),
    data.get('activeIndexByFamily', {}).get('claude', -1),
))
PY
)

        [[ "$output" == *"status=UPDATED"* ]] || {
            status=1
            break
        }
        [[ "$state" == "1|bob@example.com|0|0" ]] || {
            status=1
            break
        }
    done

    local backup_count
    backup_count=$(ls "$test_env/.config/opencode"/antigravity-accounts.json.backup.* 2>/dev/null | wc -l)

    export HOME="$old_home"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ $backup_count -ge 3 ]] || return 1
    return 0
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

# Test: dev_oas rejects disabled target account
test_dev_oas_rejects_disabled_account() {
    local test_env
    test_env=$(create_test_env "dev_oas_disabled")

    mkdir -p "$test_env/.config/opencode"
    cat > "$test_env/.config/opencode/antigravity-accounts.json" <<'JSON'
{
  "version": 4,
  "accounts": [
    {
      "email": "alice@example.com",
      "enabled": true,
      "cachedQuota": {
        "claude": {
          "remainingFraction": 0.5,
          "resetTime": "2099-12-31T23:59:59Z",
          "modelCount": 1
        }
      }
    },
    {
      "email": "bob@example.com",
      "enabled": false,
      "cachedQuota": {
        "claude": {
          "remainingFraction": 0.8,
          "resetTime": "2099-12-31T23:59:59Z",
          "modelCount": 1
        }
      }
    }
  ],
  "activeIndex": 0,
  "activeIndexByFamily": {
    "claude": 0
  }
}
JSON

    local old_home="$HOME"
    export HOME="$test_env"

    dev_oas "claude" "2" >/dev/null 2>&1
    local status=$?

    local current_index
    current_index=$(python3 -c "
import json
with open('$test_env/.config/opencode/antigravity-accounts.json') as f:
    data = json.load(f)
print(data.get('activeIndexByFamily', {}).get('claude', -1))
")

    export HOME="$old_home"
    cleanup_test_env "$test_env"

    [[ $status -eq 1 ]] || return 1
    [[ "$current_index" == "0" ]] || return 1
    return 0
}

# Test: dev_oas rejects denylisted targets after automatic prune
test_dev_oas_rejects_denylisted_account() {
    local test_env
    test_env=$(create_test_env "dev_oas_denylisted")

    mkdir -p "$test_env/.config/opencode"
    _create_mock_accounts_json "$test_env/.config/opencode/antigravity-accounts.json"

    cat > "$test_env/.config/opencode/antigravity-account-denylist.txt" <<'EOF'
bob@example.com
EOF

    local old_home="$HOME"
    export HOME="$test_env"

    dev_oas "claude" "2" >/dev/null 2>&1
    local status=$?

    local state
    state=$(python3 - "$test_env/.config/opencode/antigravity-accounts.json" <<'PY'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)

accounts = data.get('accounts', [])
print('{}|{}'.format(
    len(accounts),
    data.get('activeIndexByFamily', {}).get('claude', -1),
))
PY
)

    export HOME="$old_home"
    cleanup_test_env "$test_env"

    [[ $status -eq 1 ]] || return 1
    [[ "$state" == "1|0" ]] || return 1
    return 0
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

# Test: dev_oae supports runtime hook mode via OPENCODE_ATTR_* env vars
test_dev_oae_runtime_hook_mode() {
    local test_env
    test_env=$(create_test_env "dev_oae_runtime")
    local db_path="$test_env/opencode.db"

    _create_mock_opencode "$test_env" "$db_path"

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
conn.commit()
conn.close()
PY

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    OPENCODE_ATTR_PROVIDER_ID="openai"
    OPENCODE_ATTR_ACCOUNT_KEY="runtime@example.com"
    OPENCODE_ATTR_ACCOUNT_LABEL="runtime@example.com"
    OPENCODE_ATTR_EVENT_TYPE="account_selected"
    OPENCODE_ATTR_SOURCE="opencode_runtime"
    OPENCODE_ATTR_TRACE_ID="trace-runtime-1"
    OPENCODE_ATTR_SESSION_ID="ses_runtimebound00000000001"
    dev_oae -x >/dev/null 2>&1
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
    SELECT provider_id, account_key, account_label, event_type, source, trace_id, session_id
    FROM opencode_account_event
    ORDER BY time_ms DESC
    LIMIT 1
    """
)
row = cur.fetchone()
conn.close()
print("|".join((x or "") for x in row) if row else "")
PY
)
    fi

    PATH="$old_path"
    unset OPENCODE_ATTR_PROVIDER_ID OPENCODE_ATTR_ACCOUNT_KEY OPENCODE_ATTR_ACCOUNT_LABEL
    unset OPENCODE_ATTR_EVENT_TYPE OPENCODE_ATTR_SOURCE OPENCODE_ATTR_TRACE_ID OPENCODE_ATTR_SESSION_ID
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$event_row" == "openai|runtime@example.com|runtime@example.com|account_selected|opencode_runtime|trace-runtime-1|ses_runtimebound00000000001" ]] || return 1
    return 0
}

# Test: dev_oae supports token_refreshed event persistence
test_dev_oae_token_refreshed_event() {
    local test_env
    test_env=$(create_test_env "dev_oae_token_refresh")
    local db_path="$test_env/opencode.db"

    _create_mock_opencode "$test_env" "$db_path"

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
conn.commit()
conn.close()
PY

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    dev_oae "antigravity" "refresh@example.com" "token_refreshed" "connector_event" "refresh@example.com" >/dev/null 2>&1
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
print("|".join((x or "") for x in row) if row else "")
PY
)
    fi

    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$event_row" == "antigravity|refresh@example.com|refresh@example.com|token_refreshed|connector_event" ]] || return 1
    return 0
}

# Test: _dev_get_openai_account_identity resolves account from auth state
test_dev_openai_identity_resolver_from_auth_state() {
    local test_env
    test_env=$(create_test_env "dev_openai_identity_auth_state")

    _create_openai_auth_json \
        "$test_env/.local/share/opencode/auth.json" \
        "acct-1234567890" \
        "openai-operator@example.net"

    local old_home="$HOME"
    export HOME="$test_env"

    local identity
    identity=$(_dev_get_openai_account_identity)
    local status=$?

    export HOME="$old_home"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$identity" == "acct-1234567890|openai-operator@example.net|auth_state" ]] || return 1
    return 0
}

# Test: _dev_get_openai_account_identity ignores synthetic runtime labels
test_dev_openai_identity_resolver_ignores_synthetic_runtime_env() {
    local test_env
    test_env=$(create_test_env "dev_openai_identity_runtime_synthetic")

    _create_openai_auth_json \
        "$test_env/.local/share/opencode/auth.json" \
        "acct-openai-auth-fallback" \
        "openai-fallback@example.net"

    local old_home="$HOME"
    local old_provider=""
    local old_key=""
    local old_label=""
    local had_provider=0
    local had_key=0
    local had_label=0

    if [[ ${OPENCODE_ATTR_PROVIDER_ID+x} ]]; then
        had_provider=1
        old_provider="$OPENCODE_ATTR_PROVIDER_ID"
    fi
    if [[ ${OPENCODE_ATTR_ACCOUNT_KEY+x} ]]; then
        had_key=1
        old_key="$OPENCODE_ATTR_ACCOUNT_KEY"
    fi
    if [[ ${OPENCODE_ATTR_ACCOUNT_LABEL+x} ]]; then
        had_label=1
        old_label="$OPENCODE_ATTR_ACCOUNT_LABEL"
    fi

    export HOME="$test_env"
    OPENCODE_ATTR_PROVIDER_ID="openai"
    OPENCODE_ATTR_ACCOUNT_KEY="audit-session@example.com"
    OPENCODE_ATTR_ACCOUNT_LABEL="audit-session@example.com"

    local identity
    identity=$(_dev_get_openai_account_identity)
    local status=$?

    if [[ $had_provider -eq 1 ]]; then
        OPENCODE_ATTR_PROVIDER_ID="$old_provider"
    else
        unset OPENCODE_ATTR_PROVIDER_ID
    fi
    if [[ $had_key -eq 1 ]]; then
        OPENCODE_ATTR_ACCOUNT_KEY="$old_key"
    else
        unset OPENCODE_ATTR_ACCOUNT_KEY
    fi
    if [[ $had_label -eq 1 ]]; then
        OPENCODE_ATTR_ACCOUNT_LABEL="$old_label"
    else
        unset OPENCODE_ATTR_ACCOUNT_LABEL
    fi

    export HOME="$old_home"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$identity" == "acct-openai-auth-fallback|openai-fallback@example.net|auth_state" ]] || return 1
    return 0
}

# Test: _dev_auto_attribute is silent when OpenAI identity is unavailable
test_dev_auto_attribute_silent_on_missing_openai_identity() {
    local test_env
    test_env=$(create_test_env "dev_auto_attribute_openai_missing")
    local db_path="$test_env/opencode.db"

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

    local output
    output=$(_dev_auto_attribute 2>&1)
    local status=$?

    local event_count
    event_count=$(python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='opencode_account_event'")
exists = cur.fetchone()[0]
if exists:
    cur.execute("SELECT COUNT(*) FROM opencode_account_event")
    print(cur.fetchone()[0])
else:
    print(0)
conn.close()
PY
)

    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ -z "$output" ]] || return 1
    [[ "$event_count" == "0" ]] || return 1
    return 0
}

# Test: _dev_auto_attribute emits OpenAI shell_wrapper event from resolver output
test_dev_auto_attribute_emits_openai_shell_wrapper_event() {
    local test_env
    test_env=$(create_test_env "dev_auto_attribute_openai_emit")
    local db_path="$test_env/opencode.db"

    _create_openai_auth_json \
        "$test_env/.local/share/opencode/auth.json" \
        "acct-openai-1" \
        "openai-real@example.net"

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

    _dev_auto_attribute >/dev/null 2>&1
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
    WHERE provider_id = 'openai'
    ORDER BY time_ms DESC
    LIMIT 1
    """
)
row = cur.fetchone()
conn.close()
print("|".join((x or "") for x in row) if row else "")
PY
)
    fi

    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$event_row" == "openai|acct-openai-1|openai-real@example.net|account_selected|shell_wrapper" ]] || return 1
    return 0
}

# Test: _dev_auto_attribute forwards runtime session binding metadata when available
test_dev_auto_attribute_passes_runtime_session_id() {
    local test_env
    test_env=$(create_test_env "dev_auto_attribute_session_id")
    local db_path="$test_env/opencode.db"

    _create_openai_auth_json \
        "$test_env/.local/share/opencode/auth.json" \
        "acct-openai-bound" \
        "openai-bound@example.net"

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
    local old_session_id="${OPENCODE_ATTR_SESSION_ID:-}"
    local old_trace_id="${OPENCODE_ATTR_TRACE_ID:-}"
    local had_session_id=0
    local had_trace_id=0

    if [[ ${OPENCODE_ATTR_SESSION_ID+x} ]]; then
        had_session_id=1
    fi
    if [[ ${OPENCODE_ATTR_TRACE_ID+x} ]]; then
        had_trace_id=1
    fi

    export HOME="$test_env"
    PATH="$test_env/bin:$PATH"
    OPENCODE_ATTR_SESSION_ID="ses_bound_openai_0001"
    OPENCODE_ATTR_TRACE_ID="trace-bound-openai-0001"

    _dev_auto_attribute >/dev/null 2>&1
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
    SELECT provider_id, account_key, account_label, event_type, source, trace_id, session_id
    FROM opencode_account_event
    WHERE provider_id = 'openai'
    ORDER BY time_ms DESC
    LIMIT 1
    """
)
row = cur.fetchone()
conn.close()
print("|".join((x or "") for x in row) if row else "")
PY
)
    fi

    if [[ $had_session_id -eq 1 ]]; then
        OPENCODE_ATTR_SESSION_ID="$old_session_id"
    else
        unset OPENCODE_ATTR_SESSION_ID
    fi
    if [[ $had_trace_id -eq 1 ]]; then
        OPENCODE_ATTR_TRACE_ID="$old_trace_id"
    else
        unset OPENCODE_ATTR_TRACE_ID
    fi

    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$event_row" == "openai|acct-openai-bound|openai-bound@example.net|account_selected|shell_wrapper|trace-bound-openai-0001|ses_bound_openai_0001" ]] || return 1
    return 0
}

# Test: _dev_auto_attribute prefers auth-state OpenAI identity over synthetic runtime label
test_dev_auto_attribute_ignores_synthetic_openai_runtime_identity() {
    local test_env
    test_env=$(create_test_env "dev_auto_attribute_openai_runtime_synthetic")
    local db_path="$test_env/opencode.db"

    _create_openai_auth_json \
        "$test_env/.local/share/opencode/auth.json" \
        "acct-openai-auth" \
        "openai-auth@example.net"

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
    local old_provider=""
    local old_key=""
    local old_label=""
    local had_provider=0
    local had_key=0
    local had_label=0

    if [[ ${OPENCODE_ATTR_PROVIDER_ID+x} ]]; then
        had_provider=1
        old_provider="$OPENCODE_ATTR_PROVIDER_ID"
    fi
    if [[ ${OPENCODE_ATTR_ACCOUNT_KEY+x} ]]; then
        had_key=1
        old_key="$OPENCODE_ATTR_ACCOUNT_KEY"
    fi
    if [[ ${OPENCODE_ATTR_ACCOUNT_LABEL+x} ]]; then
        had_label=1
        old_label="$OPENCODE_ATTR_ACCOUNT_LABEL"
    fi

    export HOME="$test_env"
    PATH="$test_env/bin:$PATH"
    OPENCODE_ATTR_PROVIDER_ID="openai"
    OPENCODE_ATTR_ACCOUNT_KEY="audit-session@example.com"
    OPENCODE_ATTR_ACCOUNT_LABEL="audit-session@example.com"

    _dev_auto_attribute >/dev/null 2>&1
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
    WHERE provider_id = 'openai'
    ORDER BY time_ms DESC
    LIMIT 1
    """
)
row = cur.fetchone()
conn.close()
print("|".join((x or "") for x in row) if row else "")
PY
)
    fi

    if [[ $had_provider -eq 1 ]]; then
        OPENCODE_ATTR_PROVIDER_ID="$old_provider"
    else
        unset OPENCODE_ATTR_PROVIDER_ID
    fi
    if [[ $had_key -eq 1 ]]; then
        OPENCODE_ATTR_ACCOUNT_KEY="$old_key"
    else
        unset OPENCODE_ATTR_ACCOUNT_KEY
    fi
    if [[ $had_label -eq 1 ]]; then
        OPENCODE_ATTR_ACCOUNT_LABEL="$old_label"
    else
        unset OPENCODE_ATTR_ACCOUNT_LABEL
    fi

    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$event_row" == "openai|acct-openai-auth|openai-auth@example.net|account_selected|shell_wrapper" ]] || return 1
    return 0
}

# Test: dev_osv strict mode resolves OpenAI wrapper event with high confidence
test_dev_overview_openai_wrapper_event_strict_high_confidence() {
    local test_env
    test_env=$(create_test_env "dev_overview_openai_wrapper_strict")
    local db_path="$test_env/opencode.db"

    _create_openai_auth_json \
        "$test_env/.local/share/opencode/auth.json" \
        "acct-openai-2" \
        "strict-openai@example.net"

    _create_test_db "$db_path" || {
        cleanup_test_env "$test_env"
        return 1
    }

    _create_mock_opencode "$test_env" "$db_path"
    cat > "$test_env/bin/column" <<'EOF'
#!/bin/bash
cat
EOF
    chmod +x "$test_env/bin/column"

    local old_home="$HOME"
    local old_path="$PATH"
    export HOME="$test_env"
    PATH="$test_env/bin:$PATH"

    _dev_auto_attribute >/dev/null 2>&1
    local attr_status=$?

    if [[ $attr_status -ne 0 ]]; then
        export HOME="$old_home"
        PATH="$old_path"
        cleanup_test_env "$test_env"
        return 1
    fi

    local event_time
    event_time=$(python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute("SELECT time_ms FROM opencode_account_event WHERE provider_id='openai' ORDER BY time_ms DESC LIMIT 1")
row = cur.fetchone()
conn.close()
print(row[0] if row else "")
PY
)

    python3 - "$db_path" "$event_time" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]
event_time = int(sys.argv[2])
first_user_ms = event_time + 1000
assistant_ms = first_user_ms + 100
updated_ms = assistant_ms + 100

conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("INSERT INTO project (id, worktree) VALUES (?, ?)", ("project_lab", "/home/es/lab"))
cur.execute(
    "INSERT INTO session (id, project_id, directory, title, time_updated) VALUES (?, ?, ?, ?, ?)",
    ("ses_openaiwrapperstrict000001", "project_lab", "/home/es/lab", "OpenAI Strict", updated_ms),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_openai_user", "ses_openaiwrapperstrict000001", first_user_ms, first_user_ms, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_openai_assistant", "ses_openaiwrapperstrict000001", assistant_ms, assistant_ms, '{"role":"assistant","providerID":"openai","modelID":"oa-model"}'),
)

conn.commit()
conn.close()
PY

    local output
    output=$(dev_osv -x)
    local status=$?

    export HOME="$old_home"
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
    rows.get('OpenAI Strict', {}).get('user') == 'strict-openai@example.net' and
    rows.get('OpenAI Strict', {}).get('src') == 'shell_wrapper' and
    rows.get('OpenAI Strict', {}).get('conf') == 'high'
)
print('OK' if ok else 'FAIL')
PY
)

    [[ "$parsed" == "OK" ]]
}

# Test: dev_osv prefers non-synthetic OpenAI identity over later placeholder event
test_dev_overview_openai_prefers_non_synthetic_identity() {
    local test_env
    test_env=$(create_test_env "dev_overview_openai_prefer_non_synthetic")
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
    ("ses_openaiprefernon000001", "project_lab", "/home/es/lab", "OpenAI Prefer Non Synthetic", 1771760002000),
)

first_user_ms = 1771760000000
assistant_ms = 1771760001000

cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_openai_prefer_user", "ses_openaiprefernon000001", first_user_ms, first_user_ms, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_openai_prefer_assistant", "ses_openaiprefernon000001", assistant_ms, assistant_ms, '{"role":"assistant","providerID":"openai","modelID":"oa-model"}'),
)

cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, source) VALUES (?, ?, ?, ?, ?)",
    (1771759998000, "openai", "acct-openai-real", "real-openai@example.net", "shell_wrapper"),
)
cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, source) VALUES (?, ?, ?, ?, ?)",
    (1771759999000, "openai", "audit-session@example.com", "audit-session@example.com", "opencode_runtime"),
)

conn.commit()
conn.close()
PY

    local output
    output=$(_dev_osv_render "$db_path" "-x" "0" "0")
    local status=$?

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
    rows.get('OpenAI Prefer Non Synthetic', {}).get('user') == 'real-openai@example.net' and
    rows.get('OpenAI Prefer Non Synthetic', {}).get('src') == 'shell_wrapper' and
    rows.get('OpenAI Prefer Non Synthetic', {}).get('conf') == 'high'
)
print('OK' if ok else 'FAIL')
PY
)

    [[ "$parsed" == "OK" ]]
}

# Test: dev_osv table mode keeps real-domain USER labels visible
test_dev_overview_table_mode_user_visibility_openai() {
    local test_env
    test_env=$(create_test_env "dev_overview_table_user_visibility")
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
    ("ses_tablevisibilityopenai00001", "project_lab", "/home/es/lab", "OpenAI Table", 1771760002000),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_table_user", "ses_tablevisibilityopenai00001", 1771760000000, 1771760000000, '{"role":"user"}'),
)
cur.execute(
    "INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)",
    ("msg_table_assistant", "ses_tablevisibilityopenai00001", 1771760001000, 1771760001000, '{"role":"assistant","providerID":"openai","modelID":"oa-model"}'),
)
cur.execute(
    "INSERT INTO opencode_account_event (time_ms, provider_id, account_key, account_label, source) VALUES (?, ?, ?, ?, ?)",
    (1771759999000, "openai", "acct-table-openai", "real-user@openai.dev", "shell_wrapper"),
)

conn.commit()
conn.close()
PY

    local table_output
    table_output=$(_dev_osv_render "$db_path" "-t" "0" "0")
    local status=$?

    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$table_output" == *"real-user@openai.dev"* ]] || return 1
    return 0
}

# Test: _dev_auto_attribute emits shell_wrapper events for active families
test_dev_auto_attribute_emits_for_active_families() {
    local test_env
    test_env=$(create_test_env "dev_auto_attribute_emit")
    local db_path="$test_env/opencode.db"

    mkdir -p "$test_env/.config/opencode"
    cat > "$test_env/.config/opencode/antigravity-accounts.json" <<'JSON'
{
  "accounts": [
    {"email": "alice@example.com", "enabled": true},
    {"email": "bob@example.com", "enabled": true}
  ],
  "activeIndexByFamily": {
    "claude": 0,
    "gemini": 1
  }
}
JSON

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

    _dev_auto_attribute >/dev/null 2>&1
    local status=$?

    local event_rows=""
    if [[ $status -eq 0 ]]; then
        event_rows=$(python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute(
    """
    SELECT provider_id, account_key, event_type, source
    FROM opencode_account_event
    ORDER BY account_key ASC
    """
)
rows = cur.fetchall()
conn.close()
print("\n".join("|".join(x or "" for x in row) for row in rows))
PY
)
    fi

    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    local expected=$'antigravity|alice@example.com|account_selected|shell_wrapper\nantigravity|bob@example.com|account_selected|shell_wrapper'
    [[ "$event_rows" == "$expected" ]] || return 1
    return 0
}

# Test: _dev_auto_attribute is silent when accounts file is missing
test_dev_auto_attribute_silent_on_missing_accounts_file() {
    local test_env
    test_env=$(create_test_env "dev_auto_attribute_missing")
    local db_path="$test_env/opencode.db"

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

    local output
    output=$(_dev_auto_attribute 2>&1)
    local status=$?

    local event_count
    event_count=$(python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='opencode_account_event'")
exists = cur.fetchone()[0]
if exists:
    cur.execute("SELECT COUNT(*) FROM opencode_account_event")
    print(cur.fetchone()[0])
else:
    print(0)
conn.close()
PY
)

    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ -z "$output" ]] || return 1
    [[ "$event_count" == "0" ]] || return 1
    return 0
}

# Test: _dev_auto_attribute emits nothing when no active families are configured
test_dev_auto_attribute_silent_on_empty_active_families() {
    local test_env
    test_env=$(create_test_env "dev_auto_attribute_empty")
    local db_path="$test_env/opencode.db"

    mkdir -p "$test_env/.config/opencode"
    cat > "$test_env/.config/opencode/antigravity-accounts.json" <<'JSON'
{
  "accounts": [
    {"email": "alice@example.com", "enabled": true}
  ],
  "activeIndexByFamily": {}
}
JSON

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

    _dev_auto_attribute >/dev/null 2>&1
    local status=$?

    local event_count
    event_count=$(python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='opencode_account_event'")
exists = cur.fetchone()[0]
if exists:
    cur.execute("SELECT COUNT(*) FROM opencode_account_event")
    print(cur.fetchone()[0])
else:
    print(0)
conn.close()
PY
)

    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$event_count" == "0" ]] || return 1
    return 0
}

# Test: _dev_auto_attribute applies denylist and reroutes to enabled fallback
test_dev_auto_attribute_applies_denylist() {
    local test_env
    test_env=$(create_test_env "dev_auto_attribute_denylist")
    local db_path="$test_env/opencode.db"

    mkdir -p "$test_env/.config/opencode"
    cat > "$test_env/.config/opencode/antigravity-accounts.json" <<'JSON'
{
  "accounts": [
    {"email": "alice@example.com", "enabled": true},
    {"email": "bob@example.com", "enabled": true}
  ],
  "activeIndex": 0,
  "activeIndexByFamily": {
    "claude": 0
  }
}
JSON

    cat > "$test_env/.config/opencode/antigravity-account-denylist.txt" <<'EOF'
# one blocked account per line
alice@example.com
EOF

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

    _dev_auto_attribute >/dev/null 2>&1
    local status=$?

    local state=""
    local event_row=""
    if [[ $status -eq 0 ]]; then
        state=$(python3 - "$test_env/.config/opencode/antigravity-accounts.json" <<'PY'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)

accounts = data.get('accounts', [])
print('{}|{}'.format(
    accounts[0].get('enabled', True),
    data.get('activeIndexByFamily', {}).get('claude', -1),
))
PY
)

        event_row=$(python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute(
    """
    SELECT provider_id, account_key, event_type, source
    FROM opencode_account_event
    ORDER BY time_ms DESC
    LIMIT 1
    """
)
row = cur.fetchone()
conn.close()
print("|".join((x or "") for x in row) if row else "")
PY
)
    fi

    local backup_count
    backup_count=$(ls "$test_env/.config/opencode"/antigravity-accounts.json.backup.* 2>/dev/null | wc -l)

    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$state" == "True|0" ]] || return 1
    [[ "$event_row" == "antigravity|bob@example.com|account_selected|shell_wrapper" ]] || return 1
    [[ $backup_count -ge 1 ]] || return 1
    return 0
}

# Test: opencode shell wrapper invokes _dev_auto_attribute before command execution
test_opencode_wrapper_calls_auto_attribute() {
    local test_env
    test_env=$(create_test_env "opencode_wrapper_auto_attr")
    local db_path="$test_env/opencode.db"

    mkdir -p "$test_env/.config/opencode"
    cat > "$test_env/.config/opencode/antigravity-accounts.json" <<'JSON'
{
  "accounts": [
    {"email": "alice@example.com", "enabled": true},
    {"email": "bob@example.com", "enabled": true}
  ],
  "activeIndexByFamily": {
    "claude": 0,
    "gemini": 1
  }
}
JSON

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

    source "${LAB_ROOT}/cfg/ali/sta"
    opencode db path >/dev/null 2>&1
    local status=$?

    local event_count
    event_count=$(python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM opencode_account_event WHERE source='shell_wrapper' AND event_type='account_selected'")
count = cur.fetchone()[0]
conn.close()
print(count)
PY
)

    unset -f opencode
    export HOME="$old_home"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$event_count" == "2" ]] || return 1
    return 0
}

# Test: opencode wrapper lazy-dispatches auto-attribute when helper is not loaded
test_opencode_wrapper_lazy_dispatches_auto_attribute() {
    local test_env
    test_env=$(create_test_env "opencode_wrapper_lazy_dispatch")
    local db_path="$test_env/opencode.db"

    _create_mock_opencode "$test_env" "$db_path"

    cat > "$test_env/dev" <<'EOF'
#!/bin/bash
_dev_auto_attribute() { :; }
EOF

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"
    source "${LAB_ROOT}/cfg/ali/sta"

    local old_lib_ops_dir="${LIB_OPS_DIR:-}"
    LIB_OPS_DIR="$test_env"

    local dispatch_log="$test_env/dispatch.log"
    _orc_lazy_dispatch() {
        if [[ $# -lt 3 ]]; then
            return 1
        fi
        printf "%s|%s|%s\n" "$1" "$2" "$3" > "$dispatch_log"
        return 0
    }

    unset -f _dev_auto_attribute

    opencode db path >/dev/null 2>&1
    local status=$?

    local dispatched=""
    if [[ -f "$dispatch_log" ]]; then
        dispatched=$(python3 - "$dispatch_log" <<'PY'
import sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(f.read().strip())
PY
)
    fi

    unset -f _orc_lazy_dispatch
    unset -f opencode
    LIB_OPS_DIR="$old_lib_ops_dir"
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$dispatched" == "$test_env/dev|_dev_auto_attribute|ops:dev" ]] || return 1
    return 0
}

# Test: dev_orr emits account_selected and forwards args to opencode run
test_dev_orr_emits_event_and_runs_opencode() {
    local test_env
    test_env=$(create_test_env "dev_orr_run")
    local db_path="$test_env/opencode.db"

    _create_mock_opencode "$test_env" "$db_path"

    cat > "$test_env/bin/opencode" << EOF
#!/bin/bash
if [[ "\$1" == "db" && "\$2" == "path" ]]; then
    echo "$db_path"
    exit 0
fi
if [[ "\$1" == "run" ]]; then
    shift
    printf "%s\n" "\$*" > "$test_env/run_args.log"
    exit 0
fi
exit 1
EOF
    chmod +x "$test_env/bin/opencode"

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
conn.commit()
conn.close()
PY

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    dev_orr "openai" "run@example.com" -- "hello attributed run" >/dev/null 2>&1
    local status=$?

    local event_row=""
    local run_args=""
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
print("|".join((x or "") for x in row) if row else "")
PY
)
        run_args=$(python3 - "$test_env/run_args.log" <<'PY'
import sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(f.read().strip())
PY
)
    fi

    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$event_row" == "openai|run@example.com|run@example.com|account_selected|opencode_runtime" ]] || return 1
    [[ "$run_args" == "hello attributed run" ]] || return 1
    return 0
}

# Test: dev_orr dry-run emits event without invoking opencode run
test_dev_orr_dry_run_emits_without_run() {
    local test_env
    test_env=$(create_test_env "dev_orr_dry_run")
    local db_path="$test_env/opencode.db"

    cat > "$test_env/bin/opencode" << EOF
#!/bin/bash
if [[ "\$1" == "db" && "\$2" == "path" ]]; then
    echo "$db_path"
    exit 0
fi
if [[ "\$1" == "run" ]]; then
    touch "$test_env/run_invoked.flag"
    exit 0
fi
exit 1
EOF
    chmod +x "$test_env/bin/opencode"

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
conn.commit()
conn.close()
PY

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    dev_orr "openai" "dryrun@example.com" --dry-run -- "should not execute" >/dev/null 2>&1
    local status=$?

    local event_row=""
    local run_invoked="0"
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
print("|".join((x or "") for x in row) if row else "")
PY
)

        if [[ -f "$test_env/run_invoked.flag" ]]; then
            run_invoked="1"
        fi
    fi

    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$event_row" == "openai|dryrun@example.com|dryrun@example.com|account_selected|opencode_runtime" ]] || return 1
    [[ "$run_invoked" == "0" ]] || return 1
    return 0
}

# Test: dev_orr bypasses shell wrapper to avoid duplicate run-time emission
test_dev_orr_no_double_emission() {
    local test_env
    test_env=$(create_test_env "dev_orr_no_double")
    local db_path="$test_env/opencode.db"

    cat > "$test_env/bin/opencode" << EOF
#!/bin/bash
if [[ "\$1" == "db" && "\$2" == "path" ]]; then
    echo "$db_path"
    exit 0
fi
if [[ "\$1" == "run" ]]; then
    printf "%s\n" "\$*" > "$test_env/run_args.log"
    exit 0
fi
exit 1
EOF
    chmod +x "$test_env/bin/opencode"

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
conn.commit()
conn.close()
PY

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    opencode() {
        if [[ "$1" == "run" ]]; then
            touch "$test_env/wrapper_called.flag"
        fi
        command opencode "$@"
    }

    dev_orr "openai" "nodouble@example.com" -- "no wrapper recursion" >/dev/null 2>&1
    local status=$?

    local wrapper_called="0"
    local event_count="0"
    if [[ -f "$test_env/wrapper_called.flag" ]]; then
        wrapper_called="1"
    fi

    if [[ $status -eq 0 ]]; then
        event_count=$(python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM opencode_account_event")
count = cur.fetchone()[0]
conn.close()
print(count)
PY
)
    fi

    unset -f opencode
    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$wrapper_called" == "0" ]] || return 1
    [[ "$event_count" == "1" ]] || return 1
    return 0
}

# Test: dev_otr emits token_refreshed with optional source
test_dev_otr_emits_token_refresh_event() {
    local test_env
    test_env=$(create_test_env "dev_otr_emit")
    local db_path="$test_env/opencode.db"

    _create_mock_opencode "$test_env" "$db_path"

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
conn.commit()
conn.close()
PY

    local old_path="$PATH"
    PATH="$test_env/bin:$PATH"

    dev_otr "antigravity" "rotated@example.com" "rotated@example.com" "connector_event" >/dev/null 2>&1
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
print("|".join((x or "") for x in row) if row else "")
PY
)
    fi

    PATH="$old_path"
    cleanup_test_env "$test_env"

    [[ $status -eq 0 ]] || return 1
    [[ "$event_row" == "antigravity|rotated@example.com|rotated@example.com|token_refreshed|connector_event" ]] || return 1
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
    run_test test_dev_overview_session_bound_event_precedence
    run_test test_dev_overview_best_effort_flag
    run_test test_dev_overview_provider_mismatch_no_cross_attribution
    run_test test_dev_overview_google_provider_maps_to_antigravity
    run_test test_dev_overview_latest_event_before_prompt
    run_test test_dev_overview_mixed_event_replay_deterministic
    run_test test_dev_overview_best_effort_legacy_control_account
    run_test test_dev_move_session_by_suffix
    run_test test_dev_move_suffix_ambiguity
    run_test test_dev_olb_requires_flag
    run_test test_dev_olb_renders_dashboard
    run_test test_dev_olb_shows_model_usage
    run_test test_dev_olb_applies_denylist_before_render
    run_test test_dev_olb_watch_requires_interval
    run_test test_dev_olb_watch_rejects_bad_interval
    run_test test_dev_oqu_requires_flag
    run_test test_dev_oqu_renders_dashboard
    run_test test_dev_oqu_watch_requires_interval
    run_test test_dev_oqu_watch_rejects_bad_interval
    run_test test_dev_oac_requires_execute_flag
    run_test test_dev_oac_reconciles_repopulation_cycles
    run_test test_dev_oas_requires_params
    run_test test_dev_oas_rejects_bad_account
    run_test test_dev_oas_switches_family
    run_test test_dev_oas_rejects_out_of_range
    run_test test_dev_oas_rejects_unknown_family
    run_test test_dev_oas_rejects_disabled_account
    run_test test_dev_oas_rejects_denylisted_account
    run_test test_dev_oas_creates_backup
    run_test test_dev_oae_runtime_hook_mode
    run_test test_dev_oae_token_refreshed_event
    run_test test_dev_openai_identity_resolver_from_auth_state
    run_test test_dev_openai_identity_resolver_ignores_synthetic_runtime_env
    run_test test_dev_auto_attribute_silent_on_missing_openai_identity
    run_test test_dev_auto_attribute_emits_openai_shell_wrapper_event
    run_test test_dev_auto_attribute_passes_runtime_session_id
    run_test test_dev_auto_attribute_ignores_synthetic_openai_runtime_identity
    run_test test_dev_overview_openai_wrapper_event_strict_high_confidence
    run_test test_dev_overview_openai_prefers_non_synthetic_identity
    run_test test_dev_overview_table_mode_user_visibility_openai
    run_test test_dev_auto_attribute_emits_for_active_families
    run_test test_dev_auto_attribute_silent_on_missing_accounts_file
    run_test test_dev_auto_attribute_silent_on_empty_active_families
    run_test test_dev_auto_attribute_applies_denylist
    run_test test_opencode_wrapper_calls_auto_attribute
    run_test test_opencode_wrapper_lazy_dispatches_auto_attribute
    run_test test_dev_orr_emits_event_and_runs_opencode
    run_test test_dev_orr_dry_run_emits_without_run
    run_test test_dev_orr_no_double_emission
    run_test test_dev_otr_emits_token_refresh_event
    run_test test_dev_oas_records_account_event

    test_footer
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
