"""Check the Markdown files tracked by git.

Fails when a file contains an em dash, or when a relative link points to a
file or directory that does not exist. Web links and #anchors are not checked.
Run from the repository root: python3 .github/scripts/check_docs.py
"""

import re
import subprocess
import sys
from pathlib import Path

LINK = re.compile(r"!?\[[^\]]*\]\(\s*<?([^)\s>]+)>?(?:\s+\"[^\"]*\")?\s*\)")
SKIP = ("http://", "https://", "mailto:", "#")


def main() -> int:
    files = subprocess.run(
        ["git", "ls-files", "*.md"], check=True, capture_output=True, text=True
    ).stdout.split()
    errors = []
    for name in files:
        path = Path(name)
        in_code = False
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if "—" in line:
                errors.append(f"{name}:{number}: em dash, use a comma, colon or new sentence")
            if line.lstrip().startswith(("```", "~~~")):
                in_code = not in_code
            if in_code:
                continue
            for target in LINK.findall(line):
                if target.startswith(SKIP):
                    continue
                target = target.split("#", 1)[0]
                if not (path.parent / target).exists():
                    errors.append(f"{name}:{number}: broken link to {target}")
    for error in errors:
        print(error)
    print(f"Checked {len(files)} Markdown files, {len(errors)} problem(s).")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
