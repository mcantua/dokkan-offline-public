# License/source distribution validation

The published license grants are evaluated independently of standalone LICENSE filenames. The exact immutable Cargo publications, applicable full terms, actually supplied notices and author credits are retained; no missing copyright holder/year is fabricated.

- cms 0.2.3 selects its explicitly offered Apache 2.0 alternative.
- plist-macro 0.1.6 retains its published MIT grant, standard permission/condition/disclaimer body and actual package-author credit; its publication supplies no copyright line to invent.
- unicode-casefold 0.2.0 selects the published Apache 2.0 alternative and additionally includes Unicode-DFS-2016 terms and the actual Unicode 9 data notice. Regenerating tables from the identified Unicode 9 CaseFolding source matched the published table bytes exactly.
- Signing-support supplements select the documented permissible branches; apple-codesign-quick’s LGPL 3 source/relink delivery remains conditional until the actual matching source bundle is supplied.

The notice generator audited the current 307-package locked iOS graph with zero unresolved grant/terms/notice obligations. It reports LGPL source delivery as a separate required condition, rather than clearing it with a document alone. The candidate builder verifies the real corresponding-source archive before recording that condition as fulfilled. The strict final-release gate separately requires live Apple and physical phone evidence; an unsigned candidate is never relabelled final.

## Actual source-closure smoke check

The first creation attempt completed archive/file/vendor integrity validation but correctly rejected promotion when another agent changed source during its final fingerprint guard. It was not reported as successful or retained.

A second stable-source creation completed all guards. This was an explicitly dirty/uncommitted validation snapshot, not a final distribution artifact or a claim about a clean release commit.

- Snapshot source commit base: 37cac64e3fa4abf39928d2f8bc8ae96b0a9aaf6e
- Snapshot source fingerprint: 465cc2e0de0d90f5ca8ce4eb976607a6bf07d4619af7e52f1cc4f539d79b738d
- Locked graph hash: 28d6828268adaa9378e9da51b14fd26c0825befaf256a25d79ba12268d802430
- Validation archive bytes: 78241860
- Validation archive SHA-256: f9bec769d6ea7119e14db04c015328b1fe0cf73fc9e58cf5b38b8b9a9a40676e

The actual archive was safely extracted and its Rust application compiled with `cargo check --offline --locked --target aarch64-apple-ios` using an EMPTY Cargo home and new target directory. The check passed in 25.41 seconds using only delivered vendored/path sources plus declared compiler/SDK prerequisites. No original registry index/package cache was borrowed. Exact public Apple trust anchors were delivered; actual dependency paths in the compiler output were inside the extracted source tree. Two dead-code warnings in that snapshot did not prevent compilation; no runtime or phone behavior is inferred from this check.

The source archive contains complete application/path dependency source, all exact locked registry source plus original crate archives, public Apple trust anchors, matching Rust standard-library source and notices, build recipes, offline vendor config and explicit recipient library-replacement/relink/installation instructions. Per-file hashes, publication checksums, source fingerprint and graph hash are checked. A recipient’s locally modified LGPL library is supported; an original-library-only binary hash is not enforced.

Package-specific licensing tests passed for the three notice cases, immutable publication hashes, Unicode data attribution, tampered evidence and version drift. Source-delivery tests passed for full closure, missing/tampered source, mismatched graph and recipient-modified library support. Test-only synthetic source fixtures are explicitly marked and rejected by production distribution verification.

All validation archives, extracted sources, empty Cargo home, target output and temporary reports were removed after recording this evidence. Only source code/tests, license/provenance material and this record remain. No final IPA was built for this smoke check. No Tin MacBook, personal internet, Apple account or physical phone was used.
