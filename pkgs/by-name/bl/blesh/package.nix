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
  version = "unstable-2025-07-31";

  src = fetchFromGitHub {
    owner = "akinomyoga";
    repo = "ble.sh";
    rev = "52c38977d945b4fe4ba59f6ed0b14007ea395a26";
    fetchSubmodules = true;
    hash = "sha256-EyYLwW4kvJSGyWIMnW/wKVrJSRyrNT79zhbC2BK4DL4=";
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
