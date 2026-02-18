#!/bin/bash
# create_blocking.sh - Creates a blocking session scenario for demo purposes
# One session locks a row with SELECT FOR UPDATE, the second session tries to
# update the same row and gets blocked. Lock is held for 3 minutes then released.

DURATION=${1:-180}  # Default 3 minutes

echo "=== Oracle Blocking Session Demo ==="
echo "Creating a blocking session scenario for ${DURATION} seconds..."
echo ""

# Ensure the target row exists
sqlplus -s demo_user/oracle@//localhost:1521/XEPDB1 <<'EOF'
MERGE INTO sales s
USING (SELECT 1 AS id FROM dual) d ON (s.id = -1)
WHEN NOT MATCHED THEN INSERT (id, product, amount, sale_date)
VALUES (-1, 'LOCK_TARGET', 100, SYSDATE);
COMMIT;
EOF

# Session 1 (blocker): Lock the row and hold it
sqlplus -s demo_user/oracle@//localhost:1521/XEPDB1 <<EOF &
SET SERVEROUTPUT ON
DECLARE
    v_sid NUMBER;
    v_dummy NUMBER;
BEGIN
    SELECT sys_context('USERENV', 'SID') INTO v_sid FROM dual;
    DBMS_OUTPUT.PUT_LINE('Blocker SID: ' || v_sid);

    -- Lock the row
    SELECT amount INTO v_dummy FROM sales WHERE id = -1 FOR UPDATE;
    DBMS_OUTPUT.PUT_LINE('Blocker: row locked, holding for ${DURATION}s...');

    DBMS_LOCK.SLEEP(${DURATION});

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Blocker: lock released.');
END;
/
EOF
BLOCKER_PID=$!

sleep 3

echo "Blocker session started (PID: $BLOCKER_PID)"
echo "Starting blocked session..."
echo ""

# Session 2 (blocked): Try to update the same row - will block
sqlplus -s demo_user/oracle@//localhost:1521/XEPDB1 <<'EOF' &
SET SERVEROUTPUT ON
DECLARE
    v_sid NUMBER;
BEGIN
    SELECT sys_context('USERENV', 'SID') INTO v_sid FROM dual;
    DBMS_OUTPUT.PUT_LINE('Blocked SID: ' || v_sid);

    -- This will block until Session 1 commits
    UPDATE sales SET amount = 200 WHERE id = -1;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Blocked session: lock acquired and released.');
END;
/
EOF
BLOCKED_PID=$!

echo "Blocked session started (PID: $BLOCKED_PID)"
echo ""
echo "Blocking scenario active for ${DURATION} seconds."
echo "Check Grafana: oracledb_blocking_sessions_value{instance=\"oracle-demo\"}"
echo ""

wait $BLOCKER_PID 2>/dev/null
wait $BLOCKED_PID 2>/dev/null

echo ""
echo "=== Blocking scenario complete ==="
