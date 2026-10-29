# Re: unified Duo launcher

**Summary**
The unified iPhone Duo app now opens on a launcher: Offline Dokkan or Unit Creator. The Finish sheet is no longer the entry on the card builder. The hosted screenshot run did not start.

**Details**
- Draft PR: https://github.com/mcantua/claude-chatg/pull/5 (targets `chatgpt/ios-eclipse-database-reuse`, not merged).
- Offline Dokkan opens the one saved account.
- Unit Creator opens the existing editor to create a unit or edit saved units.
- Finish on Save & Play still imports the unit into that account's character collection.
- Run https://github.com/mcantua/claude-chatg/actions/runs/40898045304 failed at 10:05 AM CT before any step. GitHub said recent account payments have failed or the spending limit needs to be increased. No simulator screenshots were captured. A second run was not started. No release build.

| Pending item | % |
|---|---|
| Launcher instead of the Creator finish sheet | 0% |
| Full custom-unit validation before save | 0% |
| Bootstrap auth envelope and fresh-state policy | 0% |
| Original-engine master attachment | 0% |
| Late service binding in ODUnifiedDuoHost | 0% |
| In-game Creator menu | 0% |
| Real battles, saves, and summons with custom units | 0% |
| Duo two-screen test on the phone | 0% |

**Questions**
1. Can the GitHub Actions spending limit be raised so the Duo simulator diagnostic can run?

**Needs Tin?**
Yes. The diagnostic cannot start until GitHub Actions billing or the spending limit is fixed.
