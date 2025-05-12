{
  lib,
  stdenv,
  fetchgit,

  meson,
  ninja,
  pkg-config,
  python3,

  charls,
  exiv2,
  giflib,
  icu,
  jbig2dec,
  jbigkit,
  lcms2,
  lerc,
  libarchive,
  libavif,
  libepoxy,
  libheif,
  libjpeg,
  libjxl,
  libpng,
  libraw,
  librsvg,
  libtiff,
  libuchardet,
  libwebp,
  libxkbcommon,
  openjpeg,
  
  libdrm,
  libgbm,
  glfw,
  wayland,
  wayland-protocols,
  wayland-scanner,
  
  drmSupport ? (lib.meta.availableOn stdenv.hostPlatform libdrm),
  glfwSupport ? (lib.meta.availableOn stdenv.hostPlatform glfw),
  waylandSupport ? (lib.meta.availableOn stdenv.hostPlatform wayland)
}:
let
  rev = "ccfb85ded2b9f375b3a97f289239a10a06082719";
in
stdenv.mkDerivation {
  pname = "wuimg";

  version = rev;

  src = fetchgit {
    url = "https://codeberg.org/kaleido/wuimg.git";
    rev = rev;
    hash = "sha256-3pWKqQGFwAuQNGACrsgoa8CB4f2X/lukfq5NYNVPEf4=";
  };

  enableParallelBuilding = true;
  enableDebugInfo = true;
  dontStrip = true;
  strictDeps = true;

  mesonFlags = [
    "-Dflif=disabled"
    (lib.mesonEnable "window_wayland" waylandSupport)
    (lib.mesonEnable "window_glfw" glfwSupport)
    (lib.mesonEnable "window_drm" drmSupport)
  ];

  nativeBuildInputs = [
    meson
    python3
    pkg-config
    ninja
  ] ++ lib.optionals (waylandSupport) [
    wayland-scanner
  ];

  buildInputs = [
    # libflif # Not availible

    # Required
    charls
    exiv2
    giflib
    icu
    jbigkit
    lcms2
    lerc
    libarchive
    libavif
    libepoxy
    libheif
    libjpeg
    libjxl
    libpng
    libraw
    librsvg
    libtiff
    libuchardet
    libwebp
    openjpeg

    # Undocumented
    jbig2dec
    # Window backends:
  ] ++ lib.optionals (drmSupport) [
    libdrm
    libgbm
  ] ++ lib.optionals (glfwSupport) [
    glfw
  ] ++ lib.optionals (waylandSupport) [
    libxkbcommon
    wayland
    wayland-protocols
  ];

  patches = [
    ./src_meson.build.patch
    # ./window.patch
    # ./wayland.patch
  ];

  postPatch = ''
    substituteInPlace src/meson.build --replace-fail \
      "/usr/share/wayland-protocols/stable" \
      "${wayland-protocols.outPath}/share/wayland-protocols/stable"
  '';
}