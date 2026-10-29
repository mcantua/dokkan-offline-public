# Tech & Game-Dev Knowledge Base reference

Tin explicitly requested this reference on October 29, 2026:
https://drive.google.com/drive/folders/1hmaKOZMIBVAVBLXuGcvkPANbGzM5Ye7t

Read the current **00 - README + Playbooks** first. Retrieve relevant sections rather than repeatedly reading the whole library. This is reference material: Tin's latest instructions, this repository's approved design and actual client evidence take precedence. Do not copy The Breaking's project-specific gates, save paths or Windows instructions into Offline Dokkan. Keep Duo as the only active target, reuse the actual supplied engine, and retain the minimum meaningful verification policy.

## Access and reading log — October 29, 2026

The README was retrieved before the other documents. Five Google Docs were retrieved successfully; the sections actually reviewed for this task are listed below. Retrieval of a complete container does not mean every unrelated chapter was reviewed.

| Document | Reviewed sections |
|---|---|
| [00 - README + Playbooks](https://docs.google.com/document/d/1bKLCSnPPmMuNOk2qamOw1_MTzT2Q1MMfkP5LFYXGrt8/edit) | `README.md`; `playbooks/_index.md`; `playbooks/ios-mac-builds.md`; `playbooks/common-app-builds.md`. Other playbooks were visible during retrieval but are not adopted as this project's instructions. |
| [01 - Engines](https://docs.google.com/document/d/18HRTXffGq0HmTdVag-CjSaQpiyrvcjCfuCHuqSxkBC4/edit) | `engines/cocos.md`; `engines/proprietary-engines.md`. Distinguish Cocos Creator from the supplied native client's Cocos2d-x-derived implementation; generic references do not establish that client's exact version or ABI. |
| [02 - Platforms](https://docs.google.com/document/d/1gJ9sljSnaIaPKhyBR1ydMYk1TkriTguYhb7TzT_Um5g/edit) | `platforms/iphone-ipad.md`; `platforms/compatibility-matrix.md`. Use scene/lifecycle, safe-area and native packaging concepts; hardware/version/policy claims require official verification before reliance. |
| [06 - Workflows](https://docs.google.com/document/d/16L7fqPweeMWC0EY9-dR0bI8YDDQclJKJ0GIUv1vssGY/edit) | `workflows/project-architecture.md`; `asset-pipelines.md`; `quality-assurance.md`; `team-coordination.md`; `continuous-integration.md`; `modding-support.md`. |
| [08 - General Topics (summaries)](https://docs.google.com/document/d/1RrNGCcwDXj8JdjZp5uREUe-qMQuYbJIOYFkrHrWPFKQ/edit) | `modding-and-file-formats.md`; `app-building-playbook.md`; `project-management.md`; `coding-practices.md`. |

No access failures occurred for these five documents. **03 - Graphics**, **04 - Programming**, **05 - Academics**, **07 - AI Dev**, unrelated chapters and the duplicate quickstart PDF were listed but not read; they are not reported as inaccessible. Linked external manuals were not exhaustively retrieved. No private source, signing material or additional personal-machine access was requested.

## Official-source checks actually performed

These targeted reference checks were made from the cloud, not Tin's Mac or personal connection:

- [Apple: Managing your app's life cycle](https://developer.apple.com/documentation/uikit/managing-your-app-s-life-cycle), retrieved through Apple's documentation JSON, HTTP 200. Confirms scene delegates handle lifecycle events for scene-enabled iOS apps. This supports the current scene bridge; it does not prove Duo layout/device behavior.
- [Apple Platform Security: App code signing process](https://support.apple.com/guide/security/app-code-signing-process-sec7c917bf14/web), HTTP 200. Signing remains a native execution requirement; private distribution does not make an unsigned engine loadable.
- [Official Cocos2d-x repository, v4 README](https://github.com/cocos2d/cocos2d-x/blob/v4/README.md), HTTP 200. Confirms the native C++ framework and iOS support. This is a versioned reference, not a claim that the supplied client uses v4 or can be replaced by current Cocos Creator.

No new Apple model specifications, current pricing, distribution deadlines, latest Cocos release claims or blanket JIT claims were adopted from the reference. Check changing facts against current official sources when an implementation decision needs them.

## How this applies to the active work

- Keep the existing engine and asset formats. Connect local data/services and the embedded Creator through explicit native interfaces.
- Separate immutable source data, derived per-save runtime data, Creator drafts and accepted custom-unit versions. Preserve original files and exact provenance.
- Keep agent ownership explicit; integrate related changes before the next necessary native check. A compiled component or passing test is not a playable game.
- Preserve save integrity, native secret storage and data-format boundaries while avoiding repetitive checks or paused-platform builds.

This file persists the reference for future sessions that read the repository. The original reference stays in its existing Drive folder. There is no automatic synchronization with other chats, no unattended refresh and no claim that account-level memory was saved.
