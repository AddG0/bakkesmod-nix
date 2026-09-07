# BakkesMod Nix development tasks

default:
    @just --list

# Rocket League Wine prefix
rl_prefix := env("HOME") / ".steam/steam/steamapps/compatdata/252950"
bakkes_data := rl_prefix / "pfx/drive_c/users/steamuser/AppData/Roaming/bakkesmod"

[group('dev')]
[doc('Update plugin metadata from bakkesplugins.com')]
update *ARGS:
    nix run .#update -- {{ ARGS }}

[group('dev')]
[doc('Build a flake output')]
build TARGET="bakkesmod":
    nix build .#{{ TARGET }}

[group('dev')]
[doc('Format every Nix file')]
fmt:
    nix fmt

[group('testing')]
[doc('Run the behavior tests (seconds; skips building every plugin)')]
test:
    nix build --no-link .#bakkes-sync .#checks.x86_64-linux.workshop-textures-test .#checks.x86_64-linux.config-generation-test
    nix run .#check-no-ifd

[group('testing')]
[doc('Build every package and run the flake checks')]
check:
    nix flake check

[group('testing')]
[doc('Check that the module evaluates without import-from-derivation')]
check-ifd:
    nix run .#check-no-ifd

[group('testing')]
[doc('Show BakkesMod launcher logs')]
logs:
    @cat "${XDG_STATE_HOME:-$HOME/.local/state}/bakkesmod/launcher.log"

[group('testing')]
[doc('Remove BakkesMod entirely for fresh install testing')]
clean-bakkes:
    @echo "Removing BakkesMod data directory..."
    rm -rf "{{ bakkes_data }}"
    @echo "Done. BakkesMod will be reinstalled on next launch."
