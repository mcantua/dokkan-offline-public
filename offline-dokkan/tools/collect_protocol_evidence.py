#!/usr/bin/env python3
"""Offline-only protocol evidence tools. Never emits raw bodies, secrets, or application bytes."""
import argparse
import hashlib
import json
import pathlib
import plistlib
import re
import zipfile
from urllib.parse import urlsplit
from macho_metadata import macho_metadata

ROOT = pathlib.Path(__file__).resolve().parents[2]
PATCHERS = ("EclipsePatcher.dylib", "DokkanSparkingPatcher.dylib")
HOOKS = ("HttpAsynConnection", "startRequest:", "responseData", "responseCode",
         "connectionDidFinishLoading:", "EclipseOfflineMode", "EclipseOfflineProtocol",
         "OfflineCache", "_buildOfflineLoginResponse", "LocalResponseHandler")
MAX_JSON = 8 * 1024 * 1024
# Explicit field-name allowlist reviewed from the pinned historical schema inventory.
# Arbitrary alphabetic map keys can be usernames or opaque tokens and must never pass through.
PROTOCOL_FIELDS = frozenset("""
achievement_id act act_at act_items act_max amount announcement_id announcement_tab_id
announcement_tabs announcements apologies awakening_items awakening_route_id awakenings
banner_image banners battle_at battle_energy bonus_schedules boost_at boost_point boosted
budokai card_capacity card_decoration_id card_id card_sticker_items card_tags cards
chain_battles clear_time_ms cleared_difficulties comeback comeback_campaigns content
contents_lv continue_count cooperation_campaigns created_at daily_refresh_at day description
dice difficulty dragonball_sets dragonballs dummy_card_id end_at energy equipment_skill_item_id
equipment_skill_items event_image eventkagi_area_ids eventkagi_events eventkagi_items
eventkagi_z_battle_stage_ids eventkagi_z_battle_stages events exchange_point exchangeable_item_id
exp expire_at expires_at first_focus_step friend_status friends_capacity friendships gasha_point
gashas genkai_battle_reward_acceptable genkai_battles gifts id image interval_reset_visited_days
is_boost is_favorite is_finished is_ondemand is_opening_finished is_potential_releaseable
is_released_potential is_reviewable is_support_item_capacity_extended item_cards item_id
item_type items joint_campaigns link_skill_lvs link_to listbutton_image lock login_bonuses
login_movies mainpage_card_id mainpage_user_card_id map max_accepts_at_once max_recovery_count
minibanner_image mission_categories mission_end_at mission_ids missions missions_data
mydata_subpage_visible name next_reset_at num nums optimal_awakening_step pending_friendships
popups potential_board_id potential_items potential_parameters prev_record_time_ms processed_at
progress quantity quest_clear_rewards quests random_login_bonuses rank recommend recover_point_with_stone
recovered_count released_rate required_zeni result_end_at rmbattles script_id sd_map_id seconds_per_cure
secret_treasure_boxes selected_team_num skill_lv sns_campaign stages_in_progress start_at stone
sugoroku support_film_id support_film_max_quantity support_films support_item_capacity support_item_id
support_items support_leader_ids support_leaders support_memories team_bgm_filename teams token
total_card_capacity training_fields training_item_id training_items treasure_item_switching_banners
treasure_items tutorial type unlocked_square_statuses updated_at user user_areas user_card_id_updates
user_card_ids user_card_teams user_dragonball_sessions user_exp user_items user_potential_items
user_quest user_subscription user_treasure_items user_z_battles visit_count_max visited_count
wallpaper_item_id wallpaper_items wday wday_end_at wday_start_at weight z_battle_stages zeni
cpu_friend_id is_playing_script potential_squares
""".split())
STATIC_PATHS = frozenset("""
/auth/nonce /auth/sign_in /resources/login /resources/home /user/mydata /user_areas
/user_cards/ /cards /teams /events /quests /sugoroku_maps/start /sugoroku_maps/finish
/missions /missions/put_forward /potentials /potentials/release /equip /dragonball_sets
/db_stories /genkai_battles /joint_campaigns /cooperation_campaigns /announcements
/briefing /support_leaders /client_assets /ondemand_assets /assets/database /sd/battle
/sd/characters /sd/packs /unrelease /item_reverse_resolutions /iap_rails
/client_assets/database /item_reverse_resolutions/achievements /iap_rails/googleplay_products
""".split())
PATH_TEMPLATES = (
    "/quests/{id}/sugoroku_maps/start", "/quests/{id}/sugoroku_maps/finish",
    "/quests/{id}/sugoroku_maps/continue_info", "/quests/{id}/sugoroku_maps/continue",
    "/quests/{id}/briefing", "/quests/{id}/supporters",
    "/user_cards/{id}/potentials", "/user_cards/{id}/potentials/release",
    "/user_cards/{id}/potentials/{id}/unrelease", "/cards/{id}/equip",
)


def findings_routes():
    plan = (ROOT / "projects/OFFLINE-DOKKAN-PLAN.md").read_text()
    block = plan.split("Server endpoints our local server must answer", 1)[1].split("- Still open:", 1)[0]
    routes = re.findall(r"`(/[^`]+)`", block)
    if len(routes) != 35:
        raise ValueError("Endpoint inventory changed; review the findings before collecting")
    return routes


def structure(value, depth=0):
    """Schema only. No string, numeric, boolean or null sample values are copied."""
    if depth > 16:
        return {"type": "not_expanded", "reason": "depth_limit"}
    if value is None:
        return {"type": "null"}
    if isinstance(value, bool):
        return {"type": "boolean"}
    if isinstance(value, (int, float)):
        return {"type": "integer" if isinstance(value, int) else "number"}
    if isinstance(value, str):
        return {"type": "string"}
    if isinstance(value, list):
        variants = {}
        for item in value[:64]:
            s = structure(item, depth + 1)
            variants[json.dumps(s, sort_keys=True)] = s
        return {"type": "array", "items": list(variants.values()), "sampled": len(value) > 64}
    if isinstance(value, dict):
        fields = {}
        redacted = []
        for key, item in list(value.items())[:256]:
            s = structure(item, depth + 1)
            if key in PROTOCOL_FIELDS:
                fields[key] = s
            else:
                redacted.append(s)
        if redacted:
            variants = {json.dumps(s, sort_keys=True): s for s in redacted}
            fields["[redacted-key]"] = next(iter(variants.values())) if len(variants) == 1 else {"type": "union", "variants": list(variants.values())}
        return {"type": "object", "properties": fields, "sampled": len(value) > 256,
                "redacted_key_count": len(redacted), "redaction_collisions": len(redacted) > 1}
    raise ValueError("Unsupported JSON value")


def canonical_path(raw):
    if not isinstance(raw, str) or len(raw) > 2048:
        raise ValueError("Invalid fixture path")
    p = urlsplit(raw).path
    if p in STATIC_PATHS:
        return p
    for template in PATH_TEMPLATES:
        pattern = re.escape(template).replace(re.escape("{id}"), r"[^/]+")
        if re.fullmatch(pattern, p):
            # Every variable segment is removed, including usernames, UUIDs and opaque strings.
            return template
    return "/[unrecognized-route]"


def schema_fixture(file):
    if file.stat().st_size > MAX_JSON:
        raise ValueError("Fixture exceeds 8 MiB")
    x = json.loads(file.read_text())
    if not isinstance(x, dict):
        raise ValueError("Fixture must be a JSON object")
    method = x.get("method")
    if method not in ("GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"):
        raise ValueError("Unsupported method")
    status = x.get("response_status")
    if isinstance(status, bool) or not isinstance(status, int) or not 100 <= status <= 599:
        raise ValueError("Invalid response status")
    if "request" not in x or "response" not in x:
        raise ValueError("Both decoded request and response are required")
    return {"kind": "observed-structure", "method": method, "path": canonical_path(x.get("path")),
            "response_status": status, "request": structure(x["request"]), "response": structure(x["response"]),
            "scalar_values_removed": True, "unknown_field_names_removed": True,
            "limits": "Array/object/depth sampling and redaction collisions are explicit; does not prove optional-field behavior"}


def sha_entry(z, name):
    h = hashlib.sha256()
    with z.open(name) as stream:
        while True:
            chunk = stream.read(1024 * 1024)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def safe_identifier(value):
    return value if isinstance(value, str) and re.fullmatch(r"[A-Za-z_0-9.-]{1,120}", value) else "not-recorded"


def ipa_metadata(file):
    """Reads selected ZIP entries; does not extract or modify the IPA, run apps, or use the network."""
    with zipfile.ZipFile(file) as z:
        infos = [i for i in z.infolist() if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", i.filename)]
        if len(infos) != 1 or infos[0].file_size > 2 * 1024 * 1024:
            raise ValueError("Expected one application Info.plist")
        app = infos[0].filename.rsplit("/", 1)[0]
        info = plistlib.loads(z.read(infos[0]))
        exe = info.get("CFBundleExecutable")
        if not isinstance(exe, str) or not re.fullmatch(r"[A-Za-z_0-9.-]{1,120}", exe):
            raise ValueError("Unexpected executable name")
        main = z.getinfo(app + "/" + exe)
        if main.file_size > 2 * 1024 * 1024 * 1024:
            raise ValueError("Executable exceeds collection limit")
        out = {"kind": "ipa-metadata-only", "bundle_id": safe_identifier(info.get("CFBundleIdentifier")),
               "version": safe_identifier(info.get("CFBundleShortVersionString")),
               "build": safe_identifier(info.get("CFBundleVersion")),
               "executable_sha256": sha_entry(z, main.filename), "executable_bytes": main.file_size,
               "patchers": [], "wire_payloads_collected": False}
        with z.open(main) as stream:
            out["executable_macho"] = macho_metadata(stream, main.file_size)
        for library in PATCHERS:
            name = app + "/Frameworks/" + library
            try:
                entry = z.getinfo(name)
            except KeyError:
                continue
            if entry.file_size > 32 * 1024 * 1024:
                raise ValueError("Patcher exceeds collection limit")
            data = z.read(entry)
            # Only allowlisted static labels are returned. Never dump strings or key-bearing bytes.
            out["patchers"].append({"name": library, "sha256": hashlib.sha256(data).hexdigest(),
                                    "bytes": len(data), "hooks_present": [h for h in HOOKS if h.encode() in data]})
            with z.open(entry) as stream:
                out["patchers"][-1]["macho"] = macho_metadata(stream, entry.file_size)
        return out


def inventory():
    routes = findings_routes()
    sources = [ROOT / "mac-workspace/research" / name for name in
               ("eclipse-ios-patcher-strings.txt", "sparking-ios-patcher-strings.txt",
                "eclipse-android-libbase-strings.txt", "sparking-android-libbase-strings.txt")]
    lines = {str(p.relative_to(ROOT)): p.read_text(errors="replace").splitlines() for p in sources}
    result = []
    for route in routes:
        observed = {}
        pattern = re.compile(re.escape(route) + (r"(?=$|[?\s\"'])" if not route.endswith("/") else ""))
        for source, rows in lines.items():
            matches = [n for n, s in enumerate(rows, 1) if pattern.search(s)]
            if matches:
                observed[source] = matches
        result.append({"reported_fragment": route, "static_string_lines": observed,
                       "method_verified_current": False, "request_verified_current": False,
                       "response_verified_current": False})
    return {"kind": "static-evidence-inventory", "routes": result,
            "warning": "A string fragment is not a full route, method or response contract"}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("mode", choices=("metadata", "schema", "inventory"))
    p.add_argument("input", type=pathlib.Path, nargs="?")
    p.add_argument("--out", type=pathlib.Path, required=True)
    args = p.parse_args()
    if args.mode != "inventory" and args.input is None:
        p.error("An input file is required")
    try:
        part = args.out.with_suffix(".part")
        if args.input is not None and args.input.resolve() in (args.out.resolve(), part.resolve()):
            raise ValueError("Output must not replace input")
        result = inventory() if args.mode == "inventory" else ipa_metadata(args.input) if args.mode == "metadata" else schema_fixture(args.input)
        args.out.parent.mkdir(parents=True, exist_ok=True)
        with part.open("x") as stream:
            stream.write(json.dumps(result, indent=2) + "\n")
        part.replace(args.out)
    except (ValueError, OSError, KeyError, zipfile.BadZipFile, json.JSONDecodeError, plistlib.InvalidFileException):
        # Exceptions can include a private path or arbitrary fixture value. Do not echo those values.
        raise SystemExit("Collection failed: input is missing, unsupported, invalid or exceeds a documented limit.")
    print("Evidence written. No application bytes, raw payloads or scalar payload values were emitted.")


if __name__ == "__main__":
    main()
