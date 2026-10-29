#!/usr/bin/env python3
"""Author our settings-only tournament reward from a real, locally supplied source.

The trusted core still validates/registers the emitted document. Nothing is installed
or granted by this tool. Existing skill/art references stay on the supplied master.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import sys

PRIVATE = Path(__file__).resolve().parents[1] / "private"
IDENTIFIER = re.compile(r"[A-Za-z0-9_.:-]{1,127}\Z")
LIMIT = 2**31 - 1


def positive(value):
    number = int(value)
    if not 1 <= number <= LIMIT:
        raise argparse.ArgumentTypeError(f"must be between 1 and {LIMIT}")
    return number


def author(args):
    source = args.master.resolve(strict=True)
    destination = args.output.resolve()
    if not destination.is_relative_to(PRIVATE.resolve()) or destination == PRIVATE.resolve():
        raise ValueError("Output must be inside ignored offline-dokkan/private/.")
    if destination == source:
        raise ValueError("Output cannot overwrite the source master.")
    if not IDENTIFIER.fullmatch(args.definition_id) or not args.definition_id.startswith("tournament-exclusive:") or not args.definition_id[21:]:
        raise ValueError("Use a nonempty tournament-exclusive: identity (maximum 127 characters).")
    if not IDENTIFIER.fullmatch(args.creator_id):
        raise ValueError("Creator ID must be a bounded internal identifier.")
    if not args.name.strip() or "\0" in args.name or len(args.name.encode()) > 1024:
        raise ValueError("The authored name must be nonempty and at most 1,024 UTF-8 bytes.")
    if not args.creator_name.strip() or "\0" in args.creator_name or len(args.creator_name) > 80:
        raise ValueError("Creator name must contain 1–80 characters.")
    if args.content_id and not IDENTIFIER.fullmatch(args.content_id):
        raise ValueError("Content ID must match the trusted host's bounded content identifier.")
    with source.open("rb") as stream:
        content_id = args.content_id or hashlib.file_digest(stream, "sha256").hexdigest()
    with sqlite3.connect(source.as_uri() + "?mode=ro", uri=True) as master:
        master.row_factory = sqlite3.Row
        found = master.execute("SELECT * FROM cards WHERE id=?", (args.source_id,)).fetchone()
        if found is None:
            raise ValueError("Source card does not exist in the supplied master.")
        outgoing = master.execute("SELECT 1 FROM card_awakening_routes WHERE card_id=? AND awaked_card_id!=card_id AND type IN ('CardAwakeningRoute::Dokkan','CardAwakeningRoute::Zet') LIMIT 1", (args.source_id,)).fetchone()
        if outgoing:
            raise ValueError("Choose a fully awakened source with no further Z/Dokkan route.")
        card = dict(found)
    if card.get("rarity") != (4 if args.rarity == "UR" else 5):
        raise ValueError("UR needs a fully awakened UR source; LR/Super LR/Godly LR need an LR source.")
    if not card.get("leader_skill_set_id") or not card.get("passive_skill_set_id"):
        raise ValueError("Source must include actual Leader Skill and Passive Skill references.")
    card["name"] = args.name.strip()
    for stat in ("hp", "atk", "def"):
        maximum = getattr(args, stat + "_max")
        initial = card.get(stat + "_init")
        if not isinstance(initial, int) or not 0 <= initial <= maximum:
            raise ValueError(f"{stat.upper()} maximum must be at least the source initial value.")
        card[stat + "_max"] = maximum
    exclusive_cap = {"SLR": 180, "GR": 200}.get(args.rarity)
    if exclusive_cap and args.level_max not in (None, exclusive_cap):
        raise ValueError("Super LR requires level 180; Godly LR requires level 200.")
    card["lv_max"] = exclusive_cap or args.level_max or card["lv_max"]
    if args.sa_max is not None:
        card["skill_lv_max"] = args.sa_max
    document = {
        "format": "offline-dokkan-definition", "schema_version": 1,
        "definition_id": args.definition_id, "version": args.version,
        "source": {"content_id": content_id, "master_id": args.source_id},
        "rarity": args.rarity, "fully_awakened": True, "stat_policy": args.stat_policy,
        "card": card, "tables": {},
        "creator": {"id": args.creator_id, "name": args.creator_name.strip()},
    }
    if args.rarity in ("SLR", "GR"):
        document["progression_policy"] = "creator-lr-extended-v1"
    encoded = json.dumps(document, ensure_ascii=False, indent=2, allow_nan=False) + "\n"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(encoded, encoding="utf-8")
    print(f"Authored settings saved: {destination}")
    print("Register through the trusted host; no card has been granted.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--master", type=Path, required=True)
    parser.add_argument("--content-id", help="Exact host content ID; defaults to the master's SHA-256")
    parser.add_argument("--source-id", type=positive, required=True)
    parser.add_argument("--definition-id", required=True)
    parser.add_argument("--version", type=positive, default=1)
    parser.add_argument("--creator-id", required=True)
    parser.add_argument("--creator-name", required=True)
    parser.add_argument("--name", required=True, help="Our authored custom reward name")
    parser.add_argument("--rarity", choices=("UR", "LR", "SLR", "GR"), required=True)
    for stat in ("hp", "atk", "def"):
        parser.add_argument("--" + stat + "-max", type=positive, required=True)
    parser.add_argument("--stat-policy", choices=("master-coefficient-linear-floor-v1", "creator-cap-normalized-v1"), required=True, help="Explicit immutable internal base-stat policy")
    parser.add_argument("--level-max", type=positive)
    parser.add_argument("--sa-max", type=positive)
    parser.add_argument("--output", type=Path, required=True)
    try:
        author(parser.parse_args())
    except (ValueError, OSError, sqlite3.Error, TypeError) as error:
        print(f"Cannot author reward: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
