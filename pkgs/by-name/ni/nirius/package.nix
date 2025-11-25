{
  lib,
  fetchFromSourcehut,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "nirius";
  version = "unstable-20251125";

  src = fetchFromSourcehut {
    owner = "~tsdh";
    repo = "nirius";
    rev = "165e3d8b12660d5d8aac8a2b37e034fa1c403d83";
    hash = "sha256-Nz+7wVTt6i2owtQ1vWRtU5FtfZMMsn4l98zOrKkk8eM=";
  };

  cargoHash = "sha256-p123QvlB/j0b5kFjICcTI/5ZKL8pzGfIvH80doAhqFA=";

  meta = {
    description = "Utility commands for the niri wayland compositor";
    mainProgram = "nirius";
    homepage = "https://git.sr.ht/~tsdh/nirius";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ tylerjl ];
    platforms = lib.platforms.linux;
  };
}
