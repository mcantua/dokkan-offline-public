# Refresh integration notes

Implemented in ios/RefreshCoordinator.h and .m. These notes describe code, not device-verified behavior.

## Integration
- During application launch on the main thread, call `AIRefreshCoordinator.shared registerTasks` before the launch callback returns.
- Supply `refreshHandler` with a completion block that returns YES only after every requested real refresh finishes. Supply `cancelHandler` to stop that engine operation.
- Supply `canRefreshWithoutInteraction` explicitly. It must return NO for a locked/expired biometric session, pending 2FA, unavailable pairing/VPN, or any state requiring UI. The coordinator never tries to bypass Face ID.
- After profile expiry/app records change, call `updateAppRecords:` with dictionaries containing name, bundleId, and NSNumber expiry in Unix seconds. Include this installer's actual provisioning expiry. No guessed seven-day dates.
- A Settings button can call `requestNotificationAuthorization:`. It is never invoked by background work or initialization.
- On sign out, call `cancelScheduledWork` to cancel its pending task and reminders and clear its non-secret metadata.
- Info.plist needs BGTaskSchedulerPermittedIdentifiers = [org.tin.appinstaller.refresh] and UIBackgroundModes = [fetch]. Link BackgroundTasks and UserNotifications.

## Behavior
A refresh opportunity is requested for about six hours later, or sooner when an actual profile is nearing the two-day warning period, with a 15-minute minimum to avoid a resubmission loop. iOS decides whether and when to run it. No task is requested when there are no known profile records.

A run UUID and main-queue serialization ensure iOS task completion happens once when expiration, cancellation and engine completion race. The next opportunity is requested when a task starts. If interaction is needed, the task fails honestly and may remind the user to open the app when known expiry is within two days.

Notifications are scheduled from real profile expiry, replacing this coordinator's existing pending requests. The nearest 60 expirations are prioritized to stay below iOS's pending-notification limit. Reminder text contains no account name, Apple ID or signing material. Only sanitized app name/bundle ID/expiry metadata is persisted; no credentials, pairing records, session tokens or signing keys go into UserDefaults. Foreground user authorization is required for notifications; denied permission does not break refresh.

## Remaining verification
Native compilation is delegated to the shared builds agent. No live notification prompt, BGTask launch, Face ID/Keychain interaction, VPN, Apple account, or physical-device install was tested. iOS scheduling is opportunistic; Shortcuts also cannot guarantee unattended daily refresh or biometric unlocking. Expired installer recovery can still require a computer. These limits need Tin/Claude review.
