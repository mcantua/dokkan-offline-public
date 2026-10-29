# Signing dependencies: license selection and source/relink delivery

This record covers the exact three signing-support packages below. It is a documented compliance implementation based on their published grants and source evidence, not a warranty about every possible third-party ownership claim. A missing standalone LICENSE file is assessed separately from an explicit license grant in the checksum-identified publication.

| Exact package | Published grant | Distribution selection | Evidence and implemented obligations |
|---|---|---|---|
| apple-codesign-quick 0.1.0 | LGPL-2.1-or-later | LGPL version 3 option, retaining the upstream or-later grant | Exact package/workspace manifests, upstream README/source lineage, full original library source, original LGPL2.1 text and selected LGPL3/GPL3 terms, attribution/rights notice, required corresponding-source/relink delivery gate. |
| isideload-p12-keystore 0.3.0-rc4 | MIT/Apache-2.0; exact-commit README explicitly says MIT **or** Apache | Apache-2.0 | Exact publication manifests/VCS metadata and fork README, actual package-author credit, canonical complete Apache2 terms. Existing source unmodified; no absent copyright line is invented. |
| isideload-vfs 0.0.1 | MIT OR Apache-2.0 in the exact published manifest | Apache-2.0 | Exact checksum-bound published manifests/VCS metadata, actual package-author credit, canonical complete Apache2 terms. The VCS commit is not publicly recoverable; the published crate, not a guessed repository, supplies the grant. Existing source unmodified. |

All evidence is under `downloads/license-notices/<name>-<version>/`. SOURCE.json binds the package checksum, declared/selected license, complete terms, supplied notice material and explicit obligations. `complete_upstream_notice` means the selected grant and all actually supplied notices have been accounted for with full canonical terms; it does not claim a nonexistent upstream LICENSE or copyright notice was discovered. Package authors are credited as package authors, without converting that into an invented legal copyright assertion.

## apple-codesign-quick lineage and version choice

The exact `Dadoum/apple-crates` revision 91fad87099663252dec23e4b5332a8ca979986f4 declares `LGPL-2.1-or-later` for this crate. Its workspace README identifies the author's Rust port of Sideloader's D signer. The workspace root has only a Lucide icon license, which does not apply to this library and is not substituted as its license. The related Sideloader project has a GPL3 license; that lineage license is preserved as evidence, not used to erase the crate's explicit published LGPL grant. The library source/package do not supply a separate author/copyright header; none is invented.

The upstream **or-later** grant authorizes using GNU LGPL version 3. That version incorporates GPL3, and its additional permissions govern combining this library with the AGPL3 App Installer. Preserve all original license declarations and notices, the original LGPL2.1 grant text, LGPL3 and GPL3 texts, and the application's AGPL3 text. Selecting an authorized later version does not remove the original grant or restrict recipients' original rights.

## Actual distribution requirement, including static/LTO builds

A statically linked, LTO-produced IPA must not be released with notices alone or merely a URL to this private repository. The release pipeline must supply a **matching corresponding-source/relink bundle alongside the IPA** and verify its identity/hash in the release manifest. The bundle must contain:

- The actual App Installer Objective-C and Rust source and interfaces, build scripts, app assets/metadata, the exact Cargo.lock, local dependency patches and their source.
- Complete apple-codesign-quick library source for the selected publication, including its public certificate assets. SOURCE-FILES.json verifies this exact source; these are public CA certificates, not private signing keys.
- The exact transitive registry package source/archives needed to rebuild, with original notices and checksums, and the complete license/attribution supplements. Build tools/system SDKs may be obtained under their own licenses; they are not silently relicensed or redistributed by this project.
- Build, replacement, relink and installation instructions allowing a recipient to use a modified LGPL library. Providing the complete corresponding application source enables rebuilding/relinking even though original optimization used LTO; do not rely on extracting objects from the LTO executable.
- No signing keys, Apple account secrets, pairing records or authenticated download URLs. A recipient provides their own lawful signing identity and approves their own device trust. No project rule, license notice or EULA may forbid modifying/replacing the library or reverse engineering the combined work to debug modifications.

The build agent owns assembling and verifying that actual bundle and binding its hash/source fingerprint to the IPA/release manifest. `required_distribution_artifacts: ["corresponding-source/relink-bundle"]` is a mandatory condition, **not** a claim already fulfilled by the small library source copy. A failed/missing source bundle must block release packaging. No separate written offer or inaccessible private link is substituted.

## Recipient replacement/relink procedure

1. Unpack the matching source bundle delivered with the IPA. Read its source manifest, compiler/SDK acquisition instructions and package checksums. Keep the provided licenses and notices. The source archive omits the original `.git` history. Initialize your own local metadata from its root with `git init`, `git add .`, and `git -c user.name="Source recipient" -c user.email="recipient@localhost" commit -m "Imported corresponding source"`. Its supplied `.gitignore` excludes tools, caches and private material. No original GitHub account, remote or token is required. Commit your modified source/lock locally before packaging so the build scripts record your own clean snapshot; they do not require the original commit or library binary.
2. Extract the bundled exact Cargo crate archives into a private vendor directory or use the supplied offline vendor configuration. Edit the apple-codesign-quick source as desired. Point Cargo's `[patch.crates-io]` entry for `apple-codesign-quick` to that modified directory; both the direct and isideload transitive edges must resolve to the replacement. Use `cargo tree --offline -i apple-codesign-quick` to check there is a single selected library instance.
3. After adding the local-path patch, run `cargo update --offline -p apple-codesign-quick` so the lock records that replacement; keep the modified lock/source together, then rebuild using the included Linux `app-installer/build/build-ipa.sh` recipe (or a documented compatible toolchain). The script recompiles and relinks the Rust static library from source, then links the native application. It must not force an unmodified prebuilt LGPL library or verify an original-library-only binary hash.
4. Use the resulting unsigned IPA with your own lawful Apple development signing identity/provisioning workflow and device trust approval. The project supplies no anti-modification lock, original signing secret or mandatory authorization token. Apple platform/account requirements are external to the project's license permissions.
5. If redistributing that modified build, preserve the notices, identify the modifications and provide its matching corresponding source/relink bundle. App Installer's own source remains AGPL3; these library grants remain intact.

These instructions do not authorize this cloud session to use Tin's Mac or personal internet or install anything on his phone. Those steps still require Tin's separate explicit approval under README.

## Verification and limits

The supplement verifier checks the three package checksums against Cargo.lock, the license/attribution evidence hashes, the selected grant and LGPL source-copy hashes. The global distribution gate must separately verify the actual matching IPA/source bundle/release manifest. This resolves the mechanical notice/source/relink delivery work when those gates pass; it is not a claim that an unaudited future release automatically complies.
