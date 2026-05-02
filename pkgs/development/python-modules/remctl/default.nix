{
  buildPythonPackage,
  remctl-c, # remctl from pkgs, not from pythonPackages
}:

buildPythonPackage {
  pyproject = true;
  inherit (remctl-c)
    meta
    pname
    src
    version
    ;
  setSourceRoot = "sourceRoot=$(echo */python)";

  buildInputs = [ remctl-c ];
}
