{
  lib,
  stdenvNoCC,
  commandLineArgs ? "",

  addDriverRunpath,
  adwaita-icon-theme,
  alsa-lib,
  asar,
  atk,
  at-spi2-atk,
  at-spi2-core,
  bintools,
  bubblewrap,
  cairo,
  cups,
  dbus,
  expat,
  fetchurl,
  fontconfig,
  freetype,
  gcc-unwrapped,
  gdk-pixbuf,
  glib,
  gsettings-desktop-schemas,
  gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libpulseaudio,
  libusb1,
  libva,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  makeWrapper,
  nspr,
  nss,
  openssl,
  pango,
  patchelf,
  pipewire,
  systemdLibs,
  testers,
  tpm2-tss,
  unzip,
  vulkan-loader,
  wayland,
  wrapGAppsHook3,
  xdg-utils,
  xz,
}:

let
  pname = "chatgpt";
  source = import ./source.nix;

  deps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gcc-unwrapped.lib
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libglvnd
    libnotify
    libpulseaudio
    libusb1
    libva
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    openssl
    pango
    pipewire
    systemdLibs
    tpm2-tss
    vulkan-loader
    wayland
  ];

  linux = stdenvNoCC.mkDerivation (finalAttrs: {
    inherit pname meta;
    inherit (source.linux) version;

    src = fetchurl source.linux.src.${stdenvNoCC.hostPlatform.system};

    strictDeps = true;
    __structuredAttrs = true;

    nativeBuildInputs = [
      asar
      makeWrapper
      patchelf
      wrapGAppsHook3
    ];

    buildInputs = [
      adwaita-icon-theme
      glib
      gsettings-desktop-schemas
      gtk3
    ];

    unpackPhase = ''
      runHook preUnpack

      ${lib.getExe' bintools "ar"} x "$src"
      tar xf data.tar.xz

      runHook postUnpack
    '';

    postPatch = ''
      # patchelf relocates PT_INTERP beyond familySync's 2 KiB read limit.
      # Its fallback to process.report.getReport() crashes this Electron build.
      asar extract usr/lib/chatgpt/resources/app.asar app
      substituteInPlace app/node_modules/@parcel/watcher/index.js \
        --replace-fail 'const family = familySync();' "const family = '${stdenvNoCC.hostPlatform.libc}';"
      # Don't pack packages that were originally unpacked
      unpackedDirs="$(
        find usr/lib/chatgpt/resources/app.asar.unpacked/node_modules \
          -mindepth 1 -maxdepth 2 \
          # Only descend into @scope directories
          ! -name '@*' -printf '%P\n' -prune |
          paste -sd,
      )"
      asar pack app usr/lib/chatgpt/resources/app.asar \
        --unpack-dir "node_modules/{$unpackedDirs}"
    '';

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    dontPatchELF = true;
    dontWrapGApps = true;

    rpath = lib.makeLibraryPath deps;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib" "$out/share" "$out/bin"
      cp -a usr/lib/chatgpt "$out/lib/"
      cp -a usr/share/{applications,doc,metainfo,pixmaps,swcatalog} "$out/share/"

      # Use the system Vulkan loader so it can find the installed drivers.
      rm "$out/lib/chatgpt/libvulkan.so.1"
      ln -s "${lib.getLib vulkan-loader}/lib/libvulkan.so.1" "$out/lib/chatgpt/libvulkan.so.1"

      # The bundle includes native modules and helper executables as well as the app.
      # Preserve relative RPATHs used to find bundled libraries, and skip static ELFs.
      find "$out/lib/chatgpt" -type f -print0 | while IFS= read -r -d $'\0' file; do
        if isELF "$file" && needed=$(patchelf --print-needed "$file" 2>/dev/null) && [ -n "$needed" ]; then
          oldRpath=$(patchelf --print-rpath "$file")
          patchelf --set-rpath "$rpath:$out/lib/chatgpt''${oldRpath:+:$oldRpath}" "$file"
          if patchelf --print-interpreter "$file" >/dev/null 2>&1; then
            patchelf --set-interpreter "${bintools.dynamicLinker}" "$file"
          fi
        fi
      done

      substituteInPlace "$out/share/applications/chatgpt.desktop" \
        --replace-fail 'Exec=chatgpt' "Exec=$out/bin/chatgpt"

      runHook postInstall
    '';

    postFixup = ''
      makeShellWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
        "''${gappsWrapperArgs[@]}" \
        --prefix LD_LIBRARY_PATH : "$rpath" \
        --suffix PATH : "${
          lib.makeBinPath [
            bubblewrap
            glib
            xdg-utils
            xz
          ]
        }" \
        --prefix XDG_DATA_DIRS : "${addDriverRunpath.driverLink}/share" \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
        --add-flags ${lib.escapeShellArg commandLineArgs}
    '';

    passthru = {
      updateScript = ./update.sh;
      tests.version = testers.testVersion { package = finalAttrs.finalPackage; };
    };
  });

  darwin = stdenvNoCC.mkDerivation (finalAttrs: {
    inherit pname;
    inherit (source.darwin) version;

    src = fetchurl source.darwin.src;

    strictDeps = true;
    __structuredAttrs = true;

    nativeBuildInputs = [
      makeWrapper
      unzip
    ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications"
      mkdir -p "$out/bin"
      cp -a ChatGPT.app "$out/Applications"
      makeWrapper "$out/Applications/ChatGPT.app/Contents/MacOS/ChatGPT" "$out/bin/ChatGPT" \
        --add-flags ${lib.escapeShellArg commandLineArgs}

      runHook postInstall
    '';

    passthru = {
      updateScript = ./update.sh;
      tests.version = testers.testVersion { package = finalAttrs.finalPackage; };
    };
  });

  meta = {
    description = "Desktop application for ChatGPT";
    changelog = "https://learn.chatgpt.com/docs/changelog?type=codex-app";
    homepage = "https://openai.com/chatgpt/desktop/";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [
      mdaniels5757
      wattmto
    ];
    platforms = lib.platforms.darwin ++ [
      "aarch64-linux"
      "x86_64-linux"
    ];
    broken =
      stdenvNoCC.hostPlatform.isLinux
      # Uses @parcel-bundler/watcher, which only supports glibc and musl on Linux
      && !(stdenvNoCC.hostPlatform.libc == "glibc" || stdenvNoCC.hostPlatform.libc == "musl");
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = if stdenvNoCC.hostPlatform.isDarwin then "ChatGPT" else "chatgpt";
  };
in
if stdenvNoCC.hostPlatform.isDarwin then
  darwin
else if stdenvNoCC.hostPlatform.isLinux then
  linux
else
  throw "Unsupported platform ${stdenvNoCC.hostPlatform.system}"
