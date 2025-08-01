{
  lib,
  fetchFromGitHub,
  helix,
  installShellFiles,
  nix-update-script,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "evil-helix";
  version = "20250601";

  src = fetchFromGitHub {
    owner = "usagi-flow";
    repo = "evil-helix";
    rev = "release-${version}";
    hash = "sha256-bsl9ltPXEhkcnnHFAXQMyBCh1qd+UBV0XK2EcJOe+eg=";
  };

  cargoHash = "sha256-epI/Xvw0mgc1IoDXpACws7Lsbkj1Xdk7conzJlUqRxY=";

  nativeBuildInputs = [ installShellFiles ];

  env = {
    # disable fetching and building of tree-sitter grammars in the helix-term build.rs
    HELIX_DISABLE_AUTO_GRAMMAR_BUILD = "1";
    HELIX_DEFAULT_RUNTIME = "${placeholder "out"}/lib/runtime";
  };

  postInstall = ''
    mkdir -p $out/lib
    cp -r runtime $out/lib
    # copy tree-sitter grammars from helix package
    # TODO: build it from source instead
    cp -r ${helix}/lib/runtime/grammars/* $out/lib/runtime/grammars/
    installShellCompletion contrib/completion/hx.{bash,fish,zsh}
    mkdir -p $out/share/{applications,icons/hicolor/256x256/apps}
    cp contrib/Helix.desktop $out/share/applications
    cp contrib/helix.png $out/share/icons/hicolor/256x256/apps
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Post-modern modal text editor, with vim keybindings";
    homepage = "https://github.com/usagi-flow/evil-helix";
    license = lib.licenses.mpl20;
    mainProgram = "hx";
    maintainers = with lib.maintainers; [ thiagokokada ];
  };
}
