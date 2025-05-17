{
  stdenv,
  fetchFromGitHub,
  pkg-config,
  libpng,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libflif";
  version = "0.4";
  src = fetchFromGitHub {
    owner = "FLIF-hub";
    repo = "FLIF";
    rev = "v${finalAttrs.version}";
    hash = "sha256-S2RYno5u50jCgu412yMeXxUoyQzeaCqr8U13XC43y8o=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libpng
  ];

  installPhase = ''
    runHook preInstall

    cd src
    make install-libflif.so PREFIX=$out
    make install-dev PREFIX=$out

    runHook postInstall
  '';

  outputs = [
    "out"
    "dev"
  ];
})