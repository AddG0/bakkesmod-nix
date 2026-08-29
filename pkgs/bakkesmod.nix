# BakkesMod - Rocket League mod injector
# Extracts BakkesMod.exe from the Windows installer for use with Wine/Proton
{
  lib,
  stdenv,
  fetchzip,
  innoextract,
}:
stdenv.mkDerivation rec {
  pname = "bakkesmod";
  version = "2.0.72";

  src = fetchzip {
    url = "https://github.com/bakkesmodorg/BakkesModInjectorCpp/releases/download/${version}/BakkesModSetup.zip";
    sha256 = "sha256-yHsrbKLZPauN49v8NHsN9MO+Htabc96M8G7zaS4Yjd8=";
    stripRoot = false;
  };

  nativeBuildInputs = [innoextract];

  unpackPhase = ''
    cp $src/BakkesModSetup.exe .
  '';

  buildPhase = ''
    innoextract BakkesModSetup.exe
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp app/BakkesMod.exe $out/bin/
  '';

  meta = with lib; {
    description = "BakkesMod - Rocket League mod framework";
    homepage = "https://bakkesmod.com/";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
