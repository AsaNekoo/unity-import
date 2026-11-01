#!/bin/sh
set -eu
[ $# -gt 0 ] || { echo "usage: $0 <project>..." >&2; exit 2; }
pgrep -x Unity >/dev/null && { echo "Close Unity first." >&2; exit 1; }

status=0
for project in "$@"; do
    if [ ! -f "$project/ProjectSettings/ProjectVersion.txt" ]; then
        echo "skipped, not a Unity project: $project" >&2
        status=1
        continue
    fi
    rm -rf "$project/Library/PackageCache/com.unity.modules.imgui@1.0.0"
    echo "refreshed: $project"
done
exit $status
