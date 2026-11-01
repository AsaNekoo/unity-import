# unity-import

Double-click a `.unitypackage` on Linux to import it into the Unity editor you already have open.

Tested on Unity 2022.3.22f1.
Works by adding a script to a built-in package inside the editor install.

## Install

Close Unity, then run:

```sh
./install.sh
./refresh-projects.sh /path/to/project
```

`install.sh` patches every editor listed by Unity Hub, or only the editor folders you pass it.
Run `refresh-projects.sh` once for each existing project. A project may need to be opened twice before imports work.

## Uninstall

Close Unity, then run:

```sh
./install.sh --uninstall
./refresh-projects.sh /path/to/project
```
