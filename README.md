# coder-workspace-images

## Workspace root shells

The `ubuntu-base` image and its derived language images let the `vscode`
workspace user run `su` or `su -` to enter a root shell without a password,
alongside the existing passwordless `sudo` support.

This is scoped to the dedicated `workspace-su` group, whose only image member
is `vscode`, and targets with UID 0. Other users and non-root targets retain
normal authentication. Root's password is not set, emptied, or unlocked, and
the distribution's PAM account and session checks are preserved. Membership
in `workspace-su` grants root access; do not add untrusted users to it.

The policy is installed in the image, so it also works with an existing home
volume. Existing workspaces need to be recreated using a newly built image
for the change to take effect; no home-directory reset is needed.

### Test locally

```sh
docker build -t coder-ubuntu-base:su-test ubuntu-base
bash ubuntu-base/tests/test-su.sh coder-ubuntu-base:su-test
```

The test creates users only inside a disposable container. It checks both
root-shell forms, preserves locked root passwords and passwordless sudo, and
rejects unauthorized callers and non-root targets. The pull-request workflow
runs it against the newly built base image before testing dependent images.
