{
  lib,
  stdenv,
  fetchzip,
  meson,
  ninja,
  pkg-config,
  python3,
  python3Packages,
  wayland-scanner,
  libxkbcommon,
  libgbm,
  pixman,
  xorg,
  wayland,
  gtest,
}:

stdenv.mkDerivation {
  pname = "sommelier";
  version = "142.0";

  separateDebugInfo = true;

  src = fetchzip rec {
    url = "https://chromium.googlesource.com/chromiumos/platform2/+archive/${passthru.rev}/vm_tools/sommelier.tar.gz";
    passthru.rev = "1a0ac747d984556d0d58ba38c30ba03c478c0697";
    stripRoot = false;
    sha256 = "4iE/EoAroS1wMO/QyIcy/pRfljUFU7skVBdtXJ/z/Jw=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
    python3Packages.jinja2
    wayland-scanner
  ];
  buildInputs = [
    libxkbcommon
    libgbm
    pixman
    wayland
    xorg.libxcb
  ];

  preConfigure = ''
    patchShebangs gen-shim.py
  '';

  doCheck = true;
  nativeCheckInputs = [ gtest ];

  postInstall = ''
    rm $out/bin/sommelier_test # why does it install the test binary? o_O
  '';

  passthru.updateScript = ./update.py;

  meta = with lib; {
    homepage = "https://chromium.googlesource.com/chromiumos/platform2/+/refs/heads/main/vm_tools/sommelier/";
    description = "Nested Wayland compositor with support for X11 forwarding";
    maintainers = with maintainers; [ qyliss ];
    license = licenses.bsd3;
    platforms = platforms.linux;
    mainProgram = "sommelier";
  };
}
