# Apple portal resource API reference

Source: https://github.com/limrun-inc/typescript-sdk/tree/9ddd13589c03e4f34382f2f80eb5b2b4c05f3a6b
Commit: 9ddd13589c03e4f34382f2f80eb5b2b4c05f3a6b
License: Apache-2.0 (see LICENSE).
Purpose: inspect exact current container/merchant/push APIs and auth-scheme compatibility; no credentials/account requests used. Factual protocol schema only; no code copied into engine.
Files: packages/apple-auth/src/portal-resources.ts and LICENSE.
Additional files: packages/apple-auth/src/portal.ts and internal/portal.ts from the same pinned commit. They show separate web-session/CSRF resource priming through a third-party relay; that relay and SDK are NOT used by this project. Facts only; no account credentials/tokens/network requests used.
