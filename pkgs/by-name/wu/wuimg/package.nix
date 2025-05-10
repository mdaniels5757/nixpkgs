{
  lib,
  stdenv,
  fetchgit,
  meson,
  python3,
  pkg-config,
  libarchive,
  libepoxy,
  exiv2,
  icu,
  lcms2,
  libuchardet,
  libavif,
  # libflif,
  giflib,
  libheif,
  jbigkit,
  libjpeg,
  openjpeg,
  charls,
  libjxl,
  lerc,
  libpng,
  libraw,
  librsvg,
  libtiff,
  libwebp,
  # libwebpdemux,
}:
let
  version = "ccfb85ded2b9f375b3a97f289239a10a06082719";
in
stdenv.mkDerivation {
  pname = "wuimg";
  inherit version;

  src = fetchgit {
    url = "https://codeberg.org/kaleido/wuimg.git";
    rev = version;
    hash = "sha256-3pWKqQGFwAuQNGACrsgoa8CB4f2X/lukfq5NYNVPEf4=";
  };

  nativeBuildInputs = [
    meson
    python3
    pkg-config
  ];

  buildInputs = [
    # Required
    libarchive
    libepoxy
    exiv2
    icu
    lcms2
    libuchardet
    libavif
    # libflif
    giflib
    libheif
    jbigkit
    libjpeg
    openjpeg
    charls
    libjxl
    lerc
    libpng
    libraw
    librsvg
    libtiff
    libwebp
    # libwebpdemux

    # For window backends you need:
# * Wayland
#   * libwayland
#   * libxkbcommon
#   * wayland-protocols
# * DRM/KMS
#   * libdrm
#   * libgbm
# * X11
#   * libglfw3

  ];

  enableParallelBuilding = true;
}