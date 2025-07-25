{ fetchFromGitHub, pythonPackages, python3 }:
let 
  pandaSrc = fetchFromGitHub {
    owner = "commaai";
    repo  = "panda";
    rev = "ee32eb524085f4bf8fbcc6abc123f45a0f13fd42";
    sha256 = "sha256-ftDmfEKaQLovkG7hkv51FEmWycrWiizklk80yTf5YAY=";
    leaveDotGit = true;
  };
in pythonPackages.buildPythonPackage rec {
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
    install -d $out/${python3.sitePackages}/panda
    cp -r python/* $out/${python3.sitePackages}/panda/
  '';
}
