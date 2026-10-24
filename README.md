# CLX Unreal Engine
## Implements the CLX protocol in Unreal Engine.

Blueprint included with examples. Supports all platforms Unreal Engine supports.

The plugin adds a Game Instance subsystem: call **Get CLXSubsystem** in any
Blueprint and bind its Deck, Meta, Control, Event and WaveformComplete events.

## Install

Downloads are on the Clockworks Hub (Plugins) and on each
[GitHub release](https://github.com/medcelerate/CLX-UE/releases). There are two
kinds:

| Download | Use it when |
| --- | --- |
| `clx-ue-<version>-UE5.x-Win64.zip` | Your engine version has a prebuilt zip. No Visual Studio needed. |
| `clx-ue-<version>.zip` (source) | Any other engine version or platform. Unreal compiles it the first time, so you need a C++ toolchain. |

Prebuilt zips are made for Unreal Engine 5.6, 5.7 and 5.8 on Windows. A plugin
binary only loads in the engine version it was built for, so match the `UE5.x` in
the file name to your editor (**Help → About Unreal Editor**).

### Prebuilt (Windows)

1. Close the Unreal Editor.
2. Unzip `clx-ue-<version>-UE5.x-Win64.zip` into your project's `Plugins` folder
   (create it next to the `.uproject` if it isn't there). You should end up with
   `<YourProject>/Plugins/CLX/CLX.uplugin`.
3. Open the project. If CLX isn't enabled yet, enable it in **Edit → Plugins**
   (search "CLX") and restart the editor.

If the editor says the CLX module is missing or was built with a different engine
version and asks to rebuild it, the zip doesn't match your engine. Rebuilding then
needs Visual Studio, so download the zip for your engine version instead.

Packaging a standalone game from a Blueprint-only project that uses any code
plugin, this one included, makes Unreal build a game executable. That step still
needs Visual Studio. The prebuilt zip covers the editor and Play In Editor.

### Source (any engine version or platform)

1. Install a C++ toolchain:
   - **Windows:** Visual Studio 2022 with the **Game development with C++**
     workload.
   - **Mac:** the Xcode version your engine's release notes list.
2. Close the Unreal Editor, then unzip `clx-ue-<version>.zip` (or clone this repo)
   into `<YourProject>/Plugins/CLX`.
3. Open the project. When the editor says the CLX module is missing and asks to
   rebuild it, click **Yes**.

## Releasing

Pushing a `v*` tag runs [`release.yml`](.github/workflows/release.yml). It
uploads these files to the `clockworks-downloads` bucket under `plugins/`, and
attaches them to the GitHub release:

- `clx-ue-<tag>.zip`, the source.
- `clx-ue-<tag>-UE<engine>-<platform>.zip`, one prebuilt zip per engine version and
  platform.
- `clx-ue-<tag>.json`, an index of the above for the Hub.
- A `clx-ue-latest…` copy of each file.

The prebuilt jobs need Unreal Engine, which GitHub-hosted runners don't have, so
they run on the org's self-hosted runners:

- **Windows:** the `[self-hosted, Windows, X64]` runner that builds Clockworks
  Viewer and Bridge.
- **Mac (optional):** the `[self-hosted, macOS]` runner.

Running a manual **Run workflow** with "publish" unticked builds everything
without uploading anything. Use it to check a runner, then download the zips
from the run's **Release** artifact.

### Runner setup (once)

1. **Allow this repo on the runner.** In the org's **Settings → Actions → Runner
   groups**, the group holding the runners must include CLX-UE. This repo is
   public, so the group also needs **Allow public repositories**. That's safe
   here because the workflow runs only on tags and manual runs, never on pull
   requests.
2. **Install the engines.** On the Windows runner, use the Epic Games Launcher to
   install each version listed in `UE_WIN64_VERSIONS` (default 5.6, 5.7 and
   5.8). In each engine's **Options**, you can untick the other target platforms
   and the Starter Content to save disk space. The workflow finds engines through
   the Launcher's own install list, so any drive works.
3. **Install the toolchain.** Visual Studio 2022 with the **Game development with
   C++** workload, plus the MSVC version each engine's release notes require. The
   Viewer build already uses this machine's VS 2022, so this is usually just a
   matter of adding components.
4. **Optional Mac builds.** Install the engines and the matching Xcode on the Mac
   mini, then set `UE_MAC_VERSIONS`. Mac users unzipping a prebuilt build may
   need to run `xattr -dr com.apple.quarantine Plugins/CLX` so macOS will load the
   unsigned libraries.

### Repo variables

Set these in **Settings → Secrets and variables → Actions → Variables**:

| Variable | Default | Meaning |
| --- | --- | --- |
| `UE_WIN64_VERSIONS` | `["5.6","5.7","5.8"]` | Engine versions prebuilt for Windows (JSON array). |
| `UE_MAC_VERSIONS` | unset (Mac skipped) | Engine versions prebuilt for Mac (JSON array). |
| `UE_INSTALL_DIR` | `C:\Program Files\Epic Games` | Windows fallback when the Launcher's list doesn't name an engine. |
| `UE_INSTALL_DIR_MAC` | `/Users/Shared/Epic Games` | Folder holding the Mac `UE_5.x` folders. |

The B2 upload uses the existing `B2_KEY_ID`, `B2_APPLICATION_KEY` and
`B2_BUCKET_NAME` secrets. If any build fails, nothing is published, so the
`-latest` files never mix versions. Use **Re-run failed jobs** once it's fixed.
