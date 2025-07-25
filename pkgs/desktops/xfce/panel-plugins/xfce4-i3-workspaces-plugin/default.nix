{
  lib,
  stdenv,
  fetchFromGitHub,
  gettext,
  pkg-config,
  intltool,
  gtk3,
  libxfce4ui,
  libxfce4util,
  xfce4-dev-tools,
  xfce4-panel,
  i3ipc-glib,
}:

stdenv.mkDerivation rec {
  pname = "xfce4-i3-workspaces-plugin";
  version = "1.4.2";

  src = fetchFromGitHub {
    owner = "denesb";
    repo = "xfce4-i3-workspaces-plugin";
    rev = version;
    sha256 = "sha256-CKpofupoJhe5IORJgij6gOGotB+dGkUDtTUdon8/JdE=";
  };

  nativeBuildInputs = [
    gettext
    pkg-config
    intltool
    xfce4-dev-tools
  ];

  buildInputs = [
    gtk3
    libxfce4ui
    libxfce4util
    xfce4-panel
    i3ipc-glib
  ];

  patches = [
    # Fix build with gettext 0.25
    # https://hydra.nixos.org/build/302762031/nixlog/2
    # FIXME: remove when gettext is fixed
    ./gettext-0.25.patch
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    homepage = "https://github.com/denesb/xfce4-i3-workspaces-plugin";
    description = "Workspace switcher plugin for xfce4-panel which can be used for the i3 window manager";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
    maintainers = with maintainers; [ berbiche ];
    teams = [ teams.xfce ];
  };
}
