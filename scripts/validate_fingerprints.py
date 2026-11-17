#!/usr/bin/env python3
"""Validate every driver's fingerprints.yml against its profiles/.

A profile's identity is the `name:` field INSIDE the profile YAML, not its
filename. multipurpose-switch-1.yml declares `name: multipurpse-switch-1`, and
window-treatment-profile.calib.yml declares `name: window-treatment-profile-calib`.
Resolve deviceProfileName by internal name, case-insensitively.

Python 3 stdlib only, so this runs on macOS and Windows with no install step.
That means a narrow hand parser rather than PyYAML. It reads exactly two shapes:

    profiles/*.yml     `name:` as a top-level key
    fingerprints.yml   list items introduced by `- id:`, with sibling keys

Anything it cannot confidently read is reported as a problem rather than skipped.

Usage: validate_fingerprints.py [driver-dir ...]   (default: the whole repo)
"""

import os
import re
import sys
from collections import defaultdict

NAME_RE = re.compile(r"^name\s*:\s*(.+?)\s*$")
ITEM_RE = re.compile(r"^(\s*)-\s+(\w+)\s*:\s*(.*?)\s*$")
KEY_RE = re.compile(r"^(\s*)(\w+)\s*:\s*(.*?)\s*$")
BARE_SEQ_RE = re.compile(r"^\s*-\s+(?!\w+\s*:).*$")


def scalar(v):
    """Strip surrounding quotes, or an unquoted trailing ` # comment`."""
    v = v.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        return v[1:-1]
    # YAML starts an inline comment at a `#` preceded by whitespace
    return re.split(r"\s#", v, maxsplit=1)[0].strip()


def profile_name(path):
    """Return the declared name, or None if the file has no top-level `name:`."""
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("#") or not line.strip():
                continue
            m = NAME_RE.match(line.rstrip("\n"))
            if m:
                return scalar(m.group(1))
            if line[0] not in " \t-":
                continue  # another top-level key; keep looking
    return None


def fingerprint_entries(path):
    """Yield dicts for each list item. Raises ValueError on an unreadable shape."""
    entries, cur, indent = [], None, None
    with open(path, encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            m = ITEM_RE.match(line)
            if m:
                if cur is not None:
                    entries.append(cur)
                indent = len(m.group(1)) + 2
                cur = {m.group(2): scalar(m.group(3)), "__line": lineno}
                continue
            if BARE_SEQ_RE.match(line):
                continue
            m = KEY_RE.match(line)
            if not m:
                raise ValueError(f"{path}:{lineno}: unrecognized line {line!r}")
            lead, key, val = len(m.group(1)), m.group(2), m.group(3)
            if cur is not None and indent is not None and lead == indent:
                cur[key] = scalar(val)
            elif lead == 0:
                if cur is not None:
                    entries.append(cur)
                cur, indent = None, None
    if cur is not None:
        entries.append(cur)
    return entries


def walk(tops):
    """os.walk each top. A missing directory is an error, so a typo cannot pass."""
    for top in tops:
        if not os.path.isdir(top):
            sys.exit(f"not a directory: {top}")
        yield from os.walk(top)


def main():
    problems = defaultdict(list)
    scanned = 0

    for root, _dirs, files in walk(sys.argv[1:] or ["."]):
        if ".git" in root.split(os.sep):
            continue
        if "fingerprints.yml" not in files:
            continue
        fp = os.path.join(root, "fingerprints.yml")
        pdir = os.path.join(root, "profiles")
        if not os.path.isdir(pdir):
            continue

        names = set()
        for pf in sorted(os.listdir(pdir)):
            if not pf.endswith(".yml"):
                continue
            full = os.path.join(pdir, pf)
            n = profile_name(full)
            if n is None:
                problems["profile missing name field"].append(full)
            else:
                names.add(n.lower())
        if not names:
            continue

        try:
            entries = fingerprint_entries(fp)
        except (ValueError, OSError) as e:
            problems["unreadable fingerprints"].append(str(e))
            continue

        if not entries:
            problems["fingerprints parsed to zero entries"].append(fp)
            continue

        ids = defaultdict(int)
        for e in entries:
            scanned += 1
            if "id" in e:
                ids[e["id"]] += 1
            pn = e.get("deviceProfileName")
            if pn is None:
                continue
            if pn.lower() not in names:
                problems["dangling profile reference"].append(
                    f"{fp}:{e['__line']}: id={e.get('id')!r} -> {pn!r}"
                )
        for i, c in sorted(ids.items()):
            if c > 1:
                problems["duplicate fingerprint id"].append(f"{fp}: {i!r} appears {c}x")

    print(f"fingerprint entries scanned: {scanned}")
    total = sum(len(v) for v in problems.values())
    if not total:
        print("OK: no problems")
        return 0
    for kind in sorted(problems):
        print(f"\n{kind} ({len(problems[kind])}):")
        for line in problems[kind]:
            print(f"  {line}")
    print(f"\n{total} problem(s)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
