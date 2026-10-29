# Pairing handshake: exact continuation after the cloud account block

## Current truth

- New source: **8e602da9110f58fa4a3e550b07f8aa83a6713fe6**, committed and pushed.
- Real bug reproduced: noncanonical254-byte TLV continuations in pairing M3/M5 plus oversized logical length truncated to u8. Fixed255-byte fragmentation, strictM2/M4/trailing-TLV validation, full M6 signature/pin enforcement retained.
- Five focused final successes: actual synthetic SRP→signed/encryptedM6 and fragmentation/tamper2, typed helper diagnostics1, live sanitized progress/bounded-output/owned-child deadline2. Exact source/log receipts are in `downloads/completion-verification/remote-pairing-working/`.
- The new helper reports fixed live subphases and distinguishes timeout, rejection, proof, protocol, transport and identity failures. Parent bounds captured output and the helper after process creation to600seconds; OS launch assessment may precede that deadline. Existing exports remain for review on an unknown/interrupted outcome.
- **No new Mac helper, IPA or setup kit was compiled/delivered.** Current verified cloud distribution remains **2a31**,43,111,535byte kit SHA`1cda0defbcf540ffd68d8eb743be9f9e618da01e4ed2e4f9f359aa81779cfe93`. It lacks this newer wire fix; do not describe it as the corrected handshake release.

## Actual blocker and evidence

Run https://github.com/mcantua/claude-chatg/actions/runs/40895784566 was refused before runner start. Job123524375920 has **steps=[]**, no checkout/compiler/test/transfer. Check-run annotation:

> The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings

This is the service's generic account restriction, not proof of which particular billing condition applies. Do not request account/card details or claim an application/test failure. Exact receipt: `downloads/completion-verification/remote-pairing-working/handshake-cloud-runner-block-40895784566.json`. Log404 was expected because no log was created. No blind retry, budget/payment change or credential action was performed.

Current tool/runtime discovery found managed cloud Linux with no additional Mac executor, VPN route or attached computer-control tool. The configured genuine-SDK Mac runner is the blocked GitHub service. Existing Mac/Xcode could provide a local alternative, but direct access is unavailable here and its Rust tooling/dependencies have not been inspected. Do not invent a new cloud account, expose the private repository, create another repo, fake SDK/signature results or bypass service restrictions. Tin already authorized routine Mac/USB/network work; a local route would require a concrete manual tooling step, not another blanket permission request. Large Xcode or Apple-credential changes retain their separate approval boundary.

## Minimum user action for the cloud route

Open GitHub profile → Settings → **Billing & Licensing** and inspect the Actions restriction. Payment/budget changes are Tin's decision and stay inside GitHub. No financial details are needed in chat. If no account alert or exhausted budget explains the restriction, GitHub Support may need to investigate; do not prescribe an arbitrary spend increase.

Official documentation checked October29: [Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions), [payment/billing settings](https://docs.github.com/en/billing/how-tos/set-up-payment/manage-payment-info). These document the owner controls; they do not establish Tin's private billing state.

## Resume without repeating passed work

1. After Tin reports that Actions can run again, retry only the blocked run's failed job at its frozen source:

   ```bash
   gh run rerun 40895784566 --repo mcantua/claude-chatg --failed
   ```

   Inputs remain `package_candidates=true`, `native_checks=false`, `rust_test_scope=pairing-handshake`. It must require exact existing engine2/helper1 proofs and run zero native/old core tests. Python2 already passed with exact pre/post source hashes. A source change requires reviewing only affected evidence.
2. Verify actual successful run, outer artifact size/SHA before extraction, then the existing full inner stage gate: both IPAs, complete corresponding source/relink, helper architectures/signature/source/notices, kit/library/native bindings. No new pin may be invented from an unsuccessful run.
3. Read current private draft's actual9 asset IDs/digests, stage all7 replacements and fill/review the next promotion contract. Preserve fixture IDs686008738/686008776 and private unpublished status. Run transfer-only promotion after staging verification; independently verify server9, target/tag/draft and downloaded receipt.
4. Only then replace sole local builds, remove owned obsolete staging/artifacts and update actual download pins. Do not delete current2a31 distribution in advance.
5. For this USB setup correction, merge the new verified kit and choose **Pair only**. **No phone app reinstall is required to export/import this file.** Version2 record shape is unchanged and generated host UUID is36bytes. Installed2a31 uses pinned pair-VERIFY, whose outgoing fields/ciphertext fit≤255bytes; it does not call new pair-SETUP. Tunnel/PSK/RSD and native import paths are unchanged. Read-only source comparison established compatibility, not real phone success.
6. Transfer the private new file directly, import on the phone with Wi-Fi/LocalDevVPN, then check actual connection and continue the remaining signing/install/update/refresh/recovery/fold/touch requirements. Share only fixed public codes/outcomes, never private records or raw account/device logs. A new Mac verification warning is handled only through the supported per-tool UI for its actual warning category, never quarantine removal or local re-signing.

The exact prior physical authentication cause and future success remain unconfirmed. The reproduced wire defect matches the failing area; the synthetic result is not a physical-device result. `release_ready=false`; no100% claim.
