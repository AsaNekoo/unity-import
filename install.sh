#!/bin/sh
set -eu
src=$(dirname "$(realpath "$0")")
data="${XDG_DATA_HOME:-$HOME/.local/share}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
uninstall=
[ "${1:-}" = "--uninstall" ] && { uninstall=1; shift; }

pgrep -x Unity >/dev/null && { echo "Close Unity first." >&2; exit 1; }

imgui_package() { echo "$1/Editor/Data/Resources/PackageManager/BuiltInPackages/com.unity.modules.imgui"; }

if [ $# -eq 0 ]; then
    IFS='
'
    # Hub prints lines like: 2022.3.22f1 installed at <editor-dir>/Editor/Unity
    for exe in $(unityhub --headless editors -i 2>/dev/null | sed -n 's/.* installed at //p'); do
        editor=$(dirname "$(dirname "$exe")")
        if [ -f "$(imgui_package "$editor")/package.json" ]; then
            set -- "$@" "$editor"
        else
            echo "skipped, not found: $editor" >&2
        fi
    done
    unset IFS
    [ $# -gt 0 ] || echo "No Unity editors found."
fi

for editor in "$@"; do
    [ -f "$(imgui_package "$editor")/package.json" ] || { echo "not a Unity editor: $editor" >&2; exit 1; }
done

if [ -n "$uninstall" ]; then
    for editor in "$@"; do
        pkg=$(imgui_package "$editor")
        rm -rf "$pkg/Editor" "$pkg/Editor.meta"
        echo "unpatched: $editor"
    done

    rm -f "$HOME/.local/bin/unity-import" \
        "$data/mime/packages/unitypackage.xml" \
        "$data/applications/unity-import.desktop"
    rm -rf "$data/unity-import" "$HOME/.cache/unity-import"
    [ ! -f "$config/mimeapps.list" ] || sed -i '/^application\/x-unitypackage=/d' "$config/mimeapps.list"

    update-mime-database "$data/mime"
    update-desktop-database "$data/applications"
    echo "Uninstalled. Delete Assets/Editor/PackageImportQueue.cs from any projects that have it."
    exit 0
fi

mkdir -p "$HOME/.local/bin" "$data/mime/packages" "$data/applications" "$data/unity-import" "$config"
install -m 755 "$src/bin/unity-import" "$HOME/.local/bin/unity-import"
install -m 644 "$src/share/unitypackage.xml" "$data/mime/packages/unitypackage.xml"
install -m 644 "$src/editor/PackageImportQueue.cs" "$data/unity-import/PackageImportQueue.cs"
cat > "$data/applications/unity-import.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Import to Unity
Exec=$HOME/.local/bin/unity-import %f
MimeType=application/x-unitypackage;
NoDisplay=true
EOF

update-mime-database "$data/mime"
update-desktop-database "$data/applications"
xdg-mime default unity-import.desktop application/x-unitypackage

for editor in "$@"; do
    pkg=$(imgui_package "$editor")
    mkdir -p "$pkg/Editor"
    cp "$src/editor/Editor.meta" "$pkg/"
    cp "$src/editor/PackageImportQueue.cs" "$src/editor/PackageImportQueue.cs.meta" \
        "$src/editor/UnityImport.Editor.asmdef" "$src/editor/UnityImport.Editor.asmdef.meta" "$pkg/Editor/"
    echo "patched: $editor"
done
echo "Installed."
