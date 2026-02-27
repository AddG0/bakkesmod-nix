{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "bakkes-sync";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Fast BakkesMod config and plugin sync";
    license = lib.licenses.mit;
    mainProgram = "bakkes-sync";
  };
}
