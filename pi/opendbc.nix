{ pythonPackages, patchelf, fetchFromGitHub, python3 }:
let
  python = python3;
  sconsPkg = pythonPackages.buildPythonPackage rec {
    pname = "scons";
    version = "4.9.1";
    src = fetchFromGitHub {
      owner = "SCons";
      repo = "scons";
      rev = version;
      hash = "sha256-nVjUJQ6AuGvq9mmVVWy35kJbNY16PbLURw6vYtIoJsE=";
    };
    pyproject = true;
    nativeBuildInputs = [ pythonPackages.setuptools pythonPackages.wheel ];
    doCheck = false;
  };

  opendbcSrc = fetchFromGitHub {
    owner = "commaai";
    repo  = "opendbc";
    rev = "08469e941683fdb685d0c20eeee5c92cc9d31710";
    sha256 = "sha256-7Ex8OvwnNAOvZAQyh9NErIC4lGaZ2GKMQ4az9L1RgPg=";
  };
in pythonPackages.buildPythonPackage rec {
  pname = "opendbc";
  version = "0.2.1";
  src = opendbcSrc;
  format = "other";

  nativeBuildInputs = [
    sconsPkg
    patchelf
    pythonPackages.cython
    pythonPackages.setuptools
    pythonPackages.distutils
  ];

  propagatedBuildInputs = with pythonPackages; [
    numpy
    cantools
    # "python-can"
    crcmod
    tqdm
    pycapnp
    pycryptodome
  ];

  doCheck = false;

  patchPhase = ''
    # Patch SConstruct so that it uses numpy from nix nistead of dynamic path hack
    sed -i 's/^import numpy as np/# &/' SConstruct
    sed -i 's/np.get_include()/python_path/' SConstruct

    # Patch schebangs into generator files so that they run properly
    sed -i "1s|.*|#!${python.interpreter}|" opendbc/dbc/generator/*/*.py

    # Export repo root so sub-scripts can use import opendbc.*
    export PYTHONPATH="$PWD:$PYTHONPATH"
    ${python.interpreter} opendbc/dbc/generator/generator.py .
  '';

  buildPhase = ''
    ${python.interpreter} -m SCons -Q -f SConstruct --minimal
  '';

  installPhase = ''
    dest=$out/${python.sitePackages}/opendbc
    mkdir -p "$dest"
    cp -r opendbc/* "$dest"/
    # prune intermediates (.os .o, .h, etc.):
    find "$dest/can" -type f \
      ! -name '*.py' \
      ! -name '*.dbc' \
      ! -name '*.so' \
      -delete
  '';

  preFixup = ''
    # Fix relative dependencies
    for lib in libdbc.so packer_pyx.so parser_pyx.so; do
      patchelf --set-rpath '$ORIGIN' "$out/${python.sitePackages}/opendbc/can/$lib"
    done
  '';
}
