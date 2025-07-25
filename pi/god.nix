{ lib, python312, python312Packages, fetchFromGitHub, fetchgit, fetchPypi, patchelf }:
let
  python = python312;
  pythonPackages = python312Packages;

  inputsSrc = fetchPypi {
    pname   = "inputs";
    version = "0.5";
    sha256  = "sha256-ox1blqNSXxIy8ya+nnzozK+HPGsfuE2fPJvD15sj6uQ=";
  };
  inputsPkg = pythonPackages.buildPythonPackage rec {
    pname   = "inputs";
    version = "0.5";
    src     = inputsSrc;
    format  = "setuptools";
    doCheck = false;
  };
in pythonPackages.buildPythonApplication {
  pname = "god";
  version = "0.1.0";
  src = lib.cleanSource ./.;

  doCheck = false;
  propagatedBuildInputs = [
    inputsPkg
    pythonPackages.opendbc
    pythonPackages.panda
  ];
}
