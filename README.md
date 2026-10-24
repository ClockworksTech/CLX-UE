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
| `clx-ue-<version>-UE5.x-<platform>.zip` (prebuilt) | A release has one for your engine version and platform. No C++ toolchain needed. |
| `clx-ue-<version>.zip` (source) | Any other engine version or platform. Unreal compiles it the first time, so you need a C++ toolchain. |

Each release lists the prebuilt zips it includes. A plugin binary only loads in
the engine version it was built for, so match the `UE5.x` in the file name to
your editor (**Help → About Unreal Editor**).

### Prebuilt

1. Close the Unreal Editor.
2. Unzip the prebuilt zip into your project's `Plugins` folder (create it next to
   the `.uproject` if it isn't there). You should end up with
   `<YourProject>/Plugins/CLX/CLX.uplugin`.
3. Open the project. If CLX isn't enabled yet, enable it in **Edit → Plugins**
   (search "CLX") and restart the editor.

If the editor says the CLX module is missing or was built with a different engine
version and asks to rebuild it, the zip doesn't match your engine. Rebuilding then
needs a C++ toolchain, so download the zip for your engine version instead.

Packaging a standalone game from a Blueprint-only project that uses any code
plugin, this one included, makes Unreal build a game executable. That step still
needs the C++ toolchain. The prebuilt zip covers the editor and Play In Editor.

On a Mac, run `xattr -dr com.apple.quarantine Plugins/CLX` after unzipping a
prebuilt build, so macOS will load its unsigned libraries.

### Source (any engine version or platform)

1. Install a C++ toolchain:
   - **Windows:** Visual Studio 2022 with the **Game development with C++**
     workload.
   - **Mac:** the Xcode version your engine's release notes list.
   - **Linux:** nothing extra, since the engine bundles its own clang.
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

If any build fails, nothing is published, so the `-latest` files never mix
versions. Use **Re-run failed jobs** once it's fixed. Running a manual **Run
workflow** with "publish" unticked builds everything without uploading anything;
the zips are then in the run's **Release** artifact.

### Where each platform builds

- **Linux** builds run on GitHub-hosted runners inside Epic's
  [Unreal Engine container images](https://dev.epicgames.com/documentation/unreal-engine/overview-of-containers-in-unreal-engine)
  (`ghcr.io/epicgames/unreal-engine:dev-slim-5.x`). They're on by default.
- **Win64** and **Mac** can't use the containers. Epic only publishes Linux
  images, and Unreal can't build Windows or Mac binaries from Linux. These builds
  run on a self-hosted runner with the stock Launcher engine installed. That's
  also what makes them load in a Blueprint-only project without compiling.
  - **Win64** is on by default (UE 5.6). It runs on `[self-hosted, Windows,
    X64]`, or on the labels in `UE_WIN64_RUNNER`.
  - **Mac** stays off until `UE_MAC_VERSIONS` is set. It runs on
    `[self-hosted, macOS]`.

### Container access (once)

Epic's images are private packages, visible only to GitHub accounts linked to an
Epic Games account.

1. Link a GitHub account in your Epic account's **Apps and Accounts**
   settings, then accept the invitation to the EpicGames GitHub org.
2. On that GitHub account, create a classic personal access token with only the
   `read:packages` scope.
3. Add two repo secrets: `GHCR_USER` (the GitHub username) and `GHCR_TOKEN` (the
   token).

### Self-hosted Windows and Mac runners (once)

1. **Allow this repo on the runner.** In the org's **Settings → Actions → Runner
   groups**, the group holding the runners must include CLX-UE. This repo is
   public, so the group also needs **Allow public repositories**. That's safe
   here because the workflow runs only on tags and manual runs, never on pull
   requests.
2. **Install the engines** with the Epic Games Launcher. In each engine's
   **Options**, you can untick the other target platforms and the Starter Content
   to save disk space. On Windows, the workflow finds engines through the
   Launcher's own install list, so any drive works.
3. **Install the toolchain.**
   - **Windows:** Visual Studio 2022 with the **Game development with C++**
     workload, plus the MSVC version each engine's release notes require.
   - **Mac:** the Xcode version each engine's release notes require.
4. **Pick the versions.** Set `UE_WIN64_VERSIONS` to the engines installed on the
   Windows runner (the default is `["5.6"]`), and set `UE_MAC_VERSIONS` to turn Mac
   on. If a listed engine isn't installed, the job fails and names it.

### Repo variables

Set these in **Settings → Secrets and variables → Actions → Variables**:

| Variable | Default | Meaning |
| --- | --- | --- |
| `UE_LINUX_VERSIONS` | `["5.6","5.7","5.8"]` | Container image versions to build for Linux (JSON array); `[]` turns Linux off. |
| `UE_WIN64_VERSIONS` | `["5.6"]` | Engine versions prebuilt on the Windows runner (JSON array); `[]` turns Win64 off. |
| `UE_WIN64_RUNNER` | `["self-hosted","Windows","X64"]` | Labels of the runner that has the engines installed (JSON array). |
| `UE_MAC_VERSIONS` | unset (Mac skipped) | Engine versions prebuilt on the Mac runner (JSON array). |
| `UE_INSTALL_DIR` | `C:\Program Files\Epic Games` | Windows fallback when the Launcher's list doesn't name an engine. |
| `UE_INSTALL_DIR_MAC` | `/Users/Shared/Epic Games` | Folder holding the Mac `UE_5.x` folders. |

The B2 upload uses the existing `B2_KEY_ID`, `B2_APPLICATION_KEY` and
`B2_BUCKET_NAME` secrets.
