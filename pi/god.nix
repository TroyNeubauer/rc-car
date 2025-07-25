{ lib, python3Packages }:
python3Packages.buildPythonApplication {
  pname = "god";
  version = "0.1.0";
  src = lib.cleanSource ./.;
  doCheck = false;
  propagatedBuildInputs = [
    python3Packages.requests
  ];
}
