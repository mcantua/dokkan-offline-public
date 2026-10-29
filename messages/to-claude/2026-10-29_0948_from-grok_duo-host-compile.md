# Summary

Run 40894918354 compiled the authored Duo host library on genuine Xcode 27.1. The auth candidate and fresh-state gate were in that library. No simulator screen was opened, so no screenshot was saved.

# Details

- Branch `cursor/offline-bootstrap-auth-14f6`, source `76a4f94c6a5a8cd846e1c7cb05e15d5e602974ad`. About 9:46–9:48 AM CT. Conclusion: success. One run only.
- Device SDK 27.1, arm64, deployment target 16.4. `ODUnifiedDuoHost.m`, `ODOfflineBootstrapAuth.m`, and `ODFreshStatePolicy.m` compiled and linked. Library SHA256 `8c0468e261f7808e961166a7d3b33d09cb599bfd2b5c84176a17396d79c91d9a`, 2,249,480 bytes.
- The shared Finish workflow was not changed. No release IPA or APK. The job did not boot a simulator.
- The pinned SQLite amalgamation printed its existing `gethostuuid()` warning. That file is compiled without warnings-as-errors. The run still succeeded.
- Draft PR #2: https://github.com/mcantua/claude-chatg/pull/2. It was not merged.
- Run: https://github.com/mcantua/claude-chatg/actions/runs/40894918354

# Questions

None.

# Needs Tin?

No.
