{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonAtLeast,

  # build-system
  setuptools,

  # dependencies
  build,
  check-manifest,
  docutils,
  flit-core,
  packaging,
  pygments,
  requests,
  trove-classifiers,

  # test
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "pyroma";
  version = "5.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "regebro";
    repo = "pyroma";
    tag = version;
    sha256 = "sha256-9yE6KEUgFSWnRQHpI5frq6SdnLwnVSdgBrhy09pLWm8=";
  };

  dependencies = [
    build
    docutils
    packaging
    pygments
    setuptools
    requests
    trove-classifiers
  ];

  nativeCheckInputs = [
    check-manifest
    flit-core
    pytestCheckHook
  ];

  disabledTests = [
    # tries to reach pypi
    "test_complete"
    "test_distribute"
  ];

  pythonImportsCheck = [ "pyroma" ];

  meta = with lib; {
    description = "Test your project's packaging friendliness";
    mainProgram = "pyroma";
    homepage = "https://github.com/regebro/pyroma";
    license = licenses.mit;
    maintainers = with maintainers; [ kamadorueda ];
  };
}
