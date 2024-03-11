{ lib
, stdenvNoCC
, fetchFromGitHub
, runtimeShell
, bashInteractive
, glibcLocales
, gitMinimal
}:

stdenvNoCC.mkDerivation rec {
  pname = "blesh";
  version = "unstable-2024-03-11";

  src = fetchFromGitHub {
    owner = "akinomyoga";
    repo = "ble.sh";
    rev = "b6344b3be1978695889371de83ac4d15352e4fee";
    fetchSubmodules = true;
    leaveDotGit = true;
    sha256 = "sha256-mKqvbwLW71NBeuP5Cqsp/dmrbodzAmFI3HYN5v07cNg=";
  };

  patches = [
    ./no-git-submodule-update.patch
  ];

  dontBuild = true;
  nativeBuildInputs = [ gitMinimal ];

  doCheck = true;
  nativeCheckInputs = [ bashInteractive glibcLocales ];
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
    maintainers = with maintainers; [ aiotter ];
    platforms = platforms.unix;
  };
}
