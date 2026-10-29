#!/usr/bin/env python3
"""Reuse genuine Duo/device evidence only for identical native and data inputs."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil

spec = importlib.util.spec_from_file_location("browser_reuse", Path(__file__).with_name("reuse-browser.py"))
common = importlib.util.module_from_spec(spec)
spec.loader.exec_module(common)
common.WORK = common.ROOT / "unit-creator/cloud-ui/work/native-reuse"
common.ARTIFACT_NAME = "unit-creator-native-latest"
common.LABEL = "Duo native"
common.INPUTS = [
    "unit-creator/v2/ui", "unit-creator/web/src", "unit-creator/web/build.py",
    "unit-creator/ios-objc", "unit-creator/ios/App/Assets.xcassets",
    "unit-creator/cloud-ui/project.yml", "unit-creator/cloud-ui/run.sh",
    "unit-creator/cloud-ui/package-device.sh", "unit-creator/cloud-ui/reconstruct-data.py",
    "unit-creator/cloud-ui/Tests", "offline-dokkan/core", "offline-dokkan/adapter",
    "offline-dokkan/content", "offline-dokkan/creator-ui", "offline-dokkan/gameplay", "offline-dokkan/mobile/ios", "offline-dokkan/mobile/setup-sqlite.py",
]


def digest(path):
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def verify():
    common.output("accepted", "false")
    candidate = json.loads((common.WORK / "candidate.json").read_text())
    if candidate["current_commit"] != common.head() or candidate["source_inputs"] != common.identities():
        raise RuntimeError("Native source changed during proof reuse")
    data = common.WORK / "artifact"
    def read(name):
        return json.loads((data / name).read_text())
    required = ["native-result.json", "standalone-file-check.json", "offline-native-result.json", "toolchain.json", "data-provenance.json", "genuine-device-bootstrap.json", "offline-device-candidate.json", "UnitCreator-genuine-device-bootstrap.zip", "Offline-Dokkan-Save-Manager-Development-0.1.0.ipa", "native-web.png", "native-window.png", "standalone-file.png", "offline-native-window.png", "offline-creator-result.json", "offline-creator.png", "offline-collection.png"]
    if not all((data / name).is_file() and not (data / name).is_symlink() for name in required):
        raise RuntimeError("Incomplete genuine native evidence; existing proof is preserved")
    native, standalone, offline, toolchain, provenance, device, offline_device = [read(name) for name in required[:7]]
    baseline = candidate["source_commit"]
    if device["source_commit"] != baseline:
        prior = read("reused-native-check.json")
        if prior["current_commit"] != baseline or prior["verified_compile_commit"] != device["source_commit"] or prior["source_inputs"] != candidate["source_inputs"] or prior["checks_rerun"] is not False:
            raise RuntimeError("Native compilation provenance differs")
    if toolchain["sdk"] != "27.1" or not toolchain["xcode"].startswith("Xcode 27.1\n") or device["actual_sdk"] != "iPhoneOS27.1" or device["macho_sdk"] != "27.1.0" or device["version"] != "2.36.3" or str(device["build"]) != "128":
        raise RuntimeError("Genuine SDK/version evidence differs")
    if digest(common.ROOT / "test-page/UnitCreator-test.html") != provenance["source_html_sha256"]:
        print("Native browser/data input changed; run the actual Duo check.")
        return
    counts = {name: provenance[name]["cards"] for name in ("eclipse", "sparking")}
    eclp = native["eclp_production_roundtrip"]
    if native["geometry"]["startup"] != "ready" or not native["native_file_roundtrip"] or native["native_card_counts"] != counts or not eclp["same"] or not eclp["subtle"] or eclp["workerKeyReplies"] != 2 or eclp["workerErrors"] != 0:
        raise RuntimeError("Native SQL/file/production ECLP checks did not pass")
    movie = standalone["movie_worker_wasm"]
    if standalone["scheme"] != "file:" or not standalone["homeVisible"] or standalone["nativeBridgeInjected"] or not standalone["network_blocked"] or standalone["eclipse"] != counts["eclipse"] or standalone["sparking"] != counts["sparking"] or not all(movie[key] for key in ("ready", "vp9", "hca", "version")):
        raise RuntimeError("Actual file-loaded WebKit evidence did not pass")
    if not all(offline[key] for key in ("actual_master_import_and_reselection", "profile_persisted", "reopened_profile_equal", "single_original_game_profile", "incompatible_source_preserves_player", "source_mode_picker_absent", "actual_owned_collection_screen", "rooted_content_darwin_resolved", "unverified_game_wire_rejected")):
        raise RuntimeError("Offline native checks did not pass")
    creator = read("offline-creator-result.json")
    if not all(creator[key] for key in ("imported", "newest", "replayEqual", "staleRejected", "forgedProjectionRejected", "arbitrarySqlRejected", "savedVersion", "master_unchanged", "isolatedBattleProtected", "ownedReplayEqual", "owned_edit_retained_instance_and_team")) or creator.get("bannerDrawable") or creator.get("scheme") != "app:" or creator["native_store_reopened"].get("source") != "eclipse":
        raise RuntimeError("Embedded Offline Creator native checks did not pass")
    if offline_device["contains_game_data"] or offline_device["fixture_compile_flag"] != 0 or offline_device["actual_sdk"] != "iPhoneOS27.1":
        raise RuntimeError("Offline product is not the checked data-free device candidate")
    if digest(data / "UnitCreator-genuine-device-bootstrap.zip") != device["sha256"] or digest(data / "Offline-Dokkan-Save-Manager-Development-0.1.0.ipa") != offline_device["sha256"]:
        raise RuntimeError("Native device artifact hash differs")
    destination = common.ROOT / "unit-creator/cloud-ui/work/evidence"
    destination.mkdir(parents=True, exist_ok=True)
    for source in data.iterdir():
        if not source.is_file() or source.is_symlink() or source.suffix not in (".json", ".png", ".txt", ".log", ".zip", ".ipa"):
            raise RuntimeError("Unexpected native evidence entry")
        shutil.copyfile(source, destination / source.name)
    proof = {"current_commit": common.head(), "verified_compile_commit": device["source_commit"], "source_inputs": candidate["source_inputs"], "html_sha256": provenance["source_html_sha256"], "run_id": candidate["run_id"], "artifact_id": candidate["artifact_id"], "checks_rerun": False, "physical_checks_claimed": False}
    (destination / "reused-native-check.json").write_text(json.dumps(proof, indent=2) + "\n")
    common.output("accepted", "true")
    print("Reused genuine passed Duo/device evidence: exact native/UI/data inputs match. No tests or compilation repeated; original compilation provenance retained.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["select", "verify"])
    action = parser.parse_args().action
    common.select() if action == "select" else verify()
