{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:

rustPlatform.buildRustPackage rec {
  pname = "gen-license";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "nexxeln";
    repo = "license-generator";
    rev = "${version}";
    hash = "sha256-VOmt8JXd2+ykhkhupv/I4RfXz9P0eEesW3JGAoXStUI=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-xXzUobB8RMyJOC4lKayE+6SKC7NW1dNWGUUH3i1TaW0=";

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  meta = with lib; {
    description = "Create licenses for your projects right from your terminal";
    mainProgram = "gen-license";
    homepage = "https://github.com/nexxeln/license-generator";
    license = licenses.mit;
    maintainers = [ maintainers.ryanccn ];
  };
}
