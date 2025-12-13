{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
}:

let
  pname = "niri-scratchpad";
  version = "unstable-20251213";
in
rustPlatform.buildRustPackage {
  inherit pname version;
  src = fetchFromGitHub {
    owner = "argosnothing";
    repo = "niri-scratchpad-rs";
    rev = "908e6d6fa3d6784bb16a5d9ad2ef269d8d975ce4";
    hash = "sha256-7KCQ63x61Wq2MtqIsXSGd2li4cW/iX4IY98paAr1XU4=";
  };

  cargoHash = "sha256-XeXNJOsc/5oeS91NOxM1eFn5cfUOFdTjeDmB5+4VIiQ=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = {
    description = "Dynamically assign windows as scratchpads against a numerical register";
    homepage = "https://github.com/argosnothing/niri-scratchpad-rs";
    license = lib.licenses.gpl3;
    maintainers = [ lib.maintainers.cmm ];
  };
}
