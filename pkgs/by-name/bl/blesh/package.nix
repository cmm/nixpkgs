{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  runtimeShell,
  bashInteractive,
  glibcLocales,
  gitMinimal,
}:

stdenvNoCC.mkDerivation {
  pname = "blesh";
  version = "unstable-2025-01-16";

  src = fetchFromGitHub {
    owner = "akinomyoga";
    repo = "ble.sh";
    rev = "36ab934f5120998c7de94fba27b9b77b54e602e9";
    fetchSubmodules = true;
    leaveDotGit = true;
    hash = "sha256-9OntLsbOjOyJySXlCQMtTNsq/dp+eqbR7BGsrfTuNB8=";
  };

  patches = [ ./no-git-submodule-update.patch ];

  dontBuild = true;
  nativeBuildInputs = [ gitMinimal ];

  doCheck = true;
  nativeCheckInputs = [
    bashInteractive
    glibcLocales
  ];
  preCheck = "export LC_ALL=en_US.UTF-8";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/blesh/lib"

    cat <<EOF >"$out/share/blesh/lib/_package.sh"
    _ble_base_package_type=nix

    function ble/base/package:nix/update {
      echo "Ble.sh is installed by Nix. You can update it there." >&2
      return 1
    }
    EOF

    make install PREFIX=$out
    #cp -rv $src/* $out/share/blesh

    runHook postInstall
  '';

  postInstall = ''
    mkdir -p "$out/bin"
    cat <<EOF >"$out/bin/blesh-share"
    #!${runtimeShell}
    # Run this script to find the ble.sh shared folder
    # where all the shell scripts are living.
    echo "$out/share/blesh"
    EOF
    chmod +x "$out/bin/blesh-share"
  '';

  meta = with lib; {
    homepage = "https://github.com/akinomyoga/ble.sh";
    description = "Bash Line Editor -- a full-featured line editor written in pure Bash";
    mainProgram = "blesh-share";
    license = licenses.bsd3;
    maintainers = with maintainers; [
      aiotter
      matthiasbeyer
    ];
    platforms = platforms.unix;
  };
}
