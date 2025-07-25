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
  opendbcPkg = pythonPackages.buildPythonPackage rec {
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
      inputsPkg
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
  };

  pandaSrc = fetchgit {
    url = "https://github.com/commaai/panda.git";
    rev = "ee32eb524085f4bf8fbcc6abc123f45a0f13fd42";
    sha256 = "sha256-ftDmfEKaQLovkG7hkv51FEmWycrWiizklk80yTf5YAY=";
    leaveDotGit = true;
  };
  pandaPkg = pythonPackages.buildPythonPackage rec {
    pname = "panda";
    version = "2025-07-20";
    src = pandaSrc;
    format = "other";
    nativeBuildInputs = [];
    doCheck = false;


    propagatedBuildInputs = with pythonPackages; [
      libusb1
    ];

    # Skip building firmware, we only care about the python userspace libray
    buildPhase = "";

    installPhase = ''
      install -d $out/${python.sitePackages}/panda
      cp -r python/* $out/${python.sitePackages}/panda/
    '';
  };
in pythonPackages.buildPythonApplication {
  pname = "god";
  version = "0.1.0";
  src = lib.cleanSource ./.;

  doCheck = false;
  propagatedBuildInputs = [
    opendbcPkg
    pandaPkg
  ];
}
