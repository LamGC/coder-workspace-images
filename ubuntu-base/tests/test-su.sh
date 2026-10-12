#!/usr/bin/env bash
set -euo pipefail

# Always run the privileged fixture setup inside a disposable container.
# Usage: bash ubuntu-base/tests/test-su.sh IMAGE
image="${1:?Usage: $0 IMAGE}"
docker run --rm -i "$image" /bin/bash -s <<'CONTAINER_TEST'
set -euo pipefail
export LC_ALL=C

test "$(id -un)" = vscode
test "$(sudo -n id -u)" = 0
test "$(getent group workspace-su | cut -d: -f4)" = vscode
test "$(grep -Fxc 'auth sufficient pam_wheel.so trust use_uid root_only group=workspace-su' /etc/pam.d/su)" = 1
grep -Eq '^auth[[:space:]]+include[[:space:]]+su[[:space:]]*$' /etc/pam.d/su-l

root_password_before="$(sudo -n getent shadow root | cut -d: -f2)"
case "$root_password_before" in
    '!'*|'*'*) ;;
    *) echo 'FAIL: root must retain a locked password' >&2; exit 1 ;;
esac

# Commands get no password input; timeouts prevent an unexpected prompt hanging CI.
test "$(timeout 10s su -c 'id -u' </dev/null)" = 0
test "$(timeout 10s su root -c 'id -u' </dev/null)" = 0
test "$(timeout 10s su - root -c 'test "$HOME" = /root && id -u' </dev/null)" = 0
test "$(printf 'id -u\nexit\n' | timeout 10s su)" = 0
test "$(printf 'id -u\nexit\n' | timeout 10s su -)" = 0
echo 'PASS: vscode can use su and su - without a password'

sudo -n useradd --create-home --shell /bin/bash su-test-user
sudo -n useradd --create-home --shell /bin/bash --groups sudo su-test-sudo

expect_auth_failure() {
    local status=0 output
    output="$(timeout 10s "$@" </dev/null 2>&1)" || status=$?
    if [ "$status" -ne 1 ] || ! grep -Fq 'Authentication failure' <<< "$output"; then
        printf 'FAIL: expected authentication failure (status=%s): %s\n' "$status" "$output" >&2
        exit 1
    fi
}

# A separate user (even a member of sudo) must not inherit passwordless su.
for caller in su-test-user su-test-sudo; do
    expect_auth_failure sudo -n runuser -u "$caller" -- su root -c 'id -u'
    expect_auth_failure sudo -n runuser -u "$caller" -- su - root -c 'id -u'
done
echo 'PASS: other users, including sudo-group members, cannot su to root'

# root_only must preserve target-password authentication for non-root accounts.
expect_auth_failure su su-test-user -c 'id -u'
expect_auth_failure su - su-test-user -c 'id -u'
echo 'PASS: vscode cannot bypass authentication for a non-root target'

# Environment variables must not turn an untrusted real UID into vscode.
expect_auth_failure sudo -n runuser -u su-test-user -- \
    env USER=vscode LOGNAME=vscode su root -c 'id -u'

test "$(sudo -n getent shadow root | cut -d: -f2)" = "$root_password_before"
test "$(sudo -n id -u)" = 0
echo 'PASS: root password remains locked and sudo still works'
CONTAINER_TEST
