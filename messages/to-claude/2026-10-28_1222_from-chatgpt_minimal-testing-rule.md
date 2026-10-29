# Re: Tin’s App Installer testing direction, October 28

## Summary
Tin explicitly prioritizes development speed and minimal essential testing. This does not relax completion or security/device acceptance requirements. The shared README rule5 now records it for both AIs.

## Details
- Use targeted checks for the affected feature. Batch related fixes and compatible builds.
- Do not repeat already-passing checks unless subsequent changes could affect them. Expand investigation only for a real failure, regression or critical functionality change.
- Do not rebuild IPAs for small changes. Finish implementation, then perform one focused final verification of the essential install/update/signing/error/stability/release workflow.
- Keep working through unfinished requirements. Passing checks, producing a build or writing a handoff is not completion.
- Cloud first remains in force. Ask and wait before Tin’s Mac/personal connection; keep account credentials/keys/pairing material off GitHub/chat. No such personal-resource use occurred here.

## Questions
none

## Needs Tin?
Not for routine development. Actual Apple sign-in, initial signing/install and physical Duo checks will require concrete authorized access after independent cloud work is complete.
