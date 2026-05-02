{
  lib,
  buildPythonPackage,
}:

buildPythonPackage {

  pname = "typeddep";
  version = "1.3.3.7";
  pyproject = true;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./setup.py
      ./typeddep
    ];
  };

}
