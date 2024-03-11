{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  runtimeShell,
  bashInteractive,
  glibcLocales,
  less,
  ps,
}:

stdenvNoCC.mkDerivation {
  pname = "blesh";
  version = "0.4.0-unstable-2026-08-12";

  src = fetchFromGitHub {
    owner = "akinomyoga";
    repo = "ble.sh";
    rev = "95ae551dd687a0c61227839dda43f52ac7ea6631";
    fetchSubmodules = true;
    hash = "sha256-8yNrsPKF2WB0zZ5B9lTRmYkA0cu8cfBncuLnfcYrmDk=";
    leaveDotGit = true;
    postFetch = ''
      cd $out
      git archive --format=tar HEAD make/.git-archive-export.mk | tar xf -
      find "$out" -name .git -type d -print0 | xargs -0 rm -r
    '';
  };

  patches = [ ./no-git-submodule-update.patch ];

  postPatch = ''
    patchShebangs ./make_command.sh
  '';

  doCheck = true;
  nativeCheckInputs = [
    bashInteractive
    glibcLocales
    less
    ps
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

  meta = {
    homepage = "https://github.com/akinomyoga/ble.sh";
    description = "Bash Line Editor -- a full-featured line editor written in pure Bash";
    mainProgram = "blesh-share";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [
      aiotter
      matthiasbeyer
    ];
    platforms = lib.platforms.unix;
  };
}
