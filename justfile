# BakkesMod Nix development tasks

default:
    @just --list

# Rocket League Wine prefix
rl_prefix := env("HOME") / ".steam/steam/steamapps/compatdata/252950"
bakkes_data := rl_prefix / "pfx/drive_c/users/steamuser/AppData/Roaming/bakkesmod"

[group('dev')]
[doc('Update plugin metadata from bakkesplugins.com')]
update:
    nix run .#update

[group('testing')]
[doc('Remove BakkesMod entirely for fresh install testing')]
clean-bakkes:
    @echo "Removing BakkesMod data directory..."
    rm -rf "{{ bakkes_data }}"
    @echo "Done. BakkesMod will be reinstalled on next launch."
