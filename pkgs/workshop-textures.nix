# Workshop map textures
#
# The UDK editor packages custom maps are built against. Rocket League ships
# without them, so a workshop map referencing editor materials loads with its
# surfaces untextured. Flat drop-in for TAGame/CookedPCConsole.
{
  lib,
  fetchzip,
}:
# Mirrored on the rocketleaguemapmaking.com downloads page; RL-MapManager's
# original Dropbox link is dead. Unversioned upstream - the hash is the pin.
fetchzip {
  name = "rocketleague-workshop-textures";
  url = "https://drive.usercontent.google.com/download?id=1jklpjfEu4Yw97cjYaMDWRx8H2XFyji6U&export=download&confirm=t";
  hash = "sha256-tQFv+zXxGNf1f7Bsw9b33HZ0R1MVGOtZyQKeVw5jXa8=";
  extension = "zip";
  stripRoot = false;

  meta = {
    description = "UDK editor texture packages required by Rocket League workshop maps";
    homepage = "https://rocketleaguemapmaking.com/resources/downloads";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}
