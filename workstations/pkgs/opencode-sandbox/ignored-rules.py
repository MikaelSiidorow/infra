import json
import os
import subprocess
import sys

git, workspace = sys.argv[1:]
ignored = subprocess.run(
    [
        git,
        "-C",
        workspace,
        "ls-files",
        "-z",
        "--others",
        "--ignored",
        "--exclude-standard",
        "--directory",
    ],
    check=True,
    stdout=subprocess.PIPE,
).stdout.split(b"\0")

for entry in filter(None, ignored):
    relative = os.fsdecode(entry)
    path = os.path.realpath(os.path.join(workspace, relative.rstrip("/")))
    rule = "subpath" if relative.endswith("/") else "literal"
    print(f"(deny file-read* file-write* ({rule} {json.dumps(path)}))")
