#!/usr/bin/env python3
"""
Converts screenplay-style dialogue text into a JSON dialogue sequence.

Usage:
    python tools/dialogue_converter.py input.txt
    python tools/dialogue_converter.py input.txt --base project/assets/dialogue/walsh_test.json --event-key intro

Input format:
    Abel: "Hello?"
    ???: "Ahoy!"
    Narrator (hidden): An elderly man appeared from the shadows.
    Narrator: The man bellowed heartily.
    Walsh: "Call me Captain Walsh."

Rules:
    - Lines matching  Speaker: text  start a new entry.
    - (hidden) modifier suppresses the speaker name in output.
    - Outer double quotes are stripped from dialogue text.
    - Blank lines are ignored (use them for readability).
    - Non-speaker lines following a speaker line are appended as
      additional text lines for that entry.

Output:
    Without --base: prints the sequence JSON array to stdout.
    With --base:    patches the sequence into the given JSON file's
                    event (specified by --event-key, default "intro")
                    and prints the full amended JSON to stdout.
"""

import sys
import re
import json

SPEAKER_RE = re.compile(r"^([^:]+?)(?:\s*\(([^)]+)\))?\s*:\s*(.+)$")


def strip_outer_quotes(text: str) -> str:
    text = text.strip()
    if len(text) >= 2 and text[0] == '"' and text[-1] == '"':
        return text[1:-1]
    return text


def parse_dialogue(lines: list[str]) -> list[dict]:
    sequence: list[dict] = []
    current: dict | None = None

    for raw in lines:
        line = raw.rstrip()
        if not line:
            continue

        m = SPEAKER_RE.match(line)
        if m:
            speaker = m.group(1).strip()
            modifier = (m.group(2) or "").strip().lower()
            text = strip_outer_quotes(m.group(3).strip())

            current = {}
            if modifier != "hidden":
                current["speaker"] = speaker
            current["text"] = [text]
            sequence.append(current)
        elif current is not None:
            current["text"].append(strip_outer_quotes(line.strip()))

    return sequence


def main() -> None:
    if len(sys.argv) < 2:
        print(
            "Usage: dialogue_converter.py <input.txt> [--base <file.json>] [--event-key <key>]",
            file=sys.stderr,
        )
        sys.exit(1)

    input_file = sys.argv[1]
    base_file: str | None = None
    event_key = "intro"

    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--event-key" and i + 1 < len(sys.argv):
            event_key = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--base" and i + 1 < len(sys.argv):
            base_file = sys.argv[i + 1]
            i += 2
        else:
            print(f"Unknown argument: {sys.argv[i]}", file=sys.stderr)
            sys.exit(1)

    with open(input_file, "r", encoding="utf-8") as f:
        sequence = parse_dialogue(f.readlines())

    if base_file:
        with open(base_file, "r", encoding="utf-8") as f:
            data = json.load(f)

        event = data.get("events", {}).get(event_key)
        if event is not None:
            event.pop("text", None)
            event.pop("speaker", None)
            event["sequence"] = sequence
        else:
            data.setdefault("events", {})[event_key] = {"sequence": sequence}

        print(json.dumps(data, indent="\t", ensure_ascii=False))
    else:
        print(json.dumps(sequence, indent="\t", ensure_ascii=False))


if __name__ == "__main__":
    main()
