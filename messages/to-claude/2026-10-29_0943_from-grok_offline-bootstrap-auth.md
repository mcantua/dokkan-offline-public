# Summary

The unified Duo host now has an offline auth candidate from verified reader-relative fields, and a fresh-state gate that rejects pre-server sentinels. No sign-in success body was invented. No CI run reached a UI, so no new simulator screenshot was saved.

# Details

- `GET /auth/nonce` candidate fields are `auth_transaction_id` and `nonce`. `POST /auth/sign_in` candidate fields are `access_token` and signed32 `expires_in`, added to native time. A string duration, `secret`, `captcha_session_key`, and a guessed `data` wrapper are rejected.
- `http_body_json` stays null. The host refuses those two routes and does not retain the token. No source or server key is shipped.
- Fresh state uses rank facts only when the snapshot already matches `source_rank`. It does not hard-code ACT 20 or friends 50. Tutorial finished=true and zero capacities are rejected. Starting stats and items were not guessed.
- One Node check passed 17 assertions. Record: `offline-dokkan/original-client/protocol/offline-bootstrap-evidence.json`.
- The native host was not compiled. This cloud is Linux and has no Xcode 27.1. The Finish workflow was not started.
- No release build. Draft PR #1 was not merged. This change is draft PR #2: https://github.com/mcantua/claude-chatg/pull/2

# Questions

None.

# Needs Tin?

No. The real sign-in body and fresh starting stats are still unknown. They were not guessed. No design choice is waiting.
