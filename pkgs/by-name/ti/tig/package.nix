{
  lib,
  stdenv,
  fetchFromGitHub,
  ncurses,
  asciidoc,
  xmlto,
  docbook_xsl,
  docbook_xml_dtd_45,
  readline,
  makeWrapper,
  git,
  libiconv,
  autoreconfHook,
  findXMLCatalogs,
  pkg-config,
}:

stdenv.mkDerivation rec {
  pname = "tig";
  version = "2.5.12";

  src = fetchFromGitHub {
    owner = "jonas";
    repo = "tig";
    rev = "tig-${version}";
    sha256 = "sha256-2kNogpzu8e/abjwo18s1G5ZcSZdG5c/Ydp6tfezumdk=";
  };

  nativeBuildInputs = [
    makeWrapper
    autoreconfHook
    asciidoc
    xmlto
    docbook_xsl
    docbook_xml_dtd_45
    findXMLCatalogs
    pkg-config
  ];

  autoreconfFlags = [
    "-I"
    "tools"
    "-v"
  ];

  buildInputs = [
    ncurses
    readline
    git
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ libiconv ];

  # those files are inherently impure, we'll handle the corresponding dependencies.
  postPatch = ''
    rm contrib/config.make-*
  '';

  enableParallelBuilding = true;

  installPhase = ''
    make install
    make install-doc

    # fixes tig-completion __git-complete dependency
    sed -i '1s;^;source ${git}/share/bash-completion/completions/git\n;' contrib/tig-completion.bash

    install -D contrib/tig-completion.bash $out/share/bash-completion/completions/tig
    cp contrib/vim.tigrc $out/etc/

    # Note: Until https://github.com/jonas/tig/issues/940 is resolved it is best
    # not to install the ZSH completion so that the fallback implementation from
    # ZSH can be used (Completion/Unix/Command/_git: "_tig () { _git-log }"):
    #install -D contrib/tig-completion.zsh $out/share/zsh/site-functions/_tig

    wrapProgram $out/bin/tig \
      --prefix PATH ':' "${git}/bin"
  '';

  meta = with lib; {
    homepage = "https://jonas.github.io/tig/";
    description = "Text-mode interface for git";
    maintainers = with maintainers; [
      bjornfor
      qknight
      globin
      ma27
    ];
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
    mainProgram = "tig";
  };
}
