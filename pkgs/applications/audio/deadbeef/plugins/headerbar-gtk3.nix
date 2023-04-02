{ lib, stdenv, fetchFromGitHub, autoconf, automake, libtool, pkg-config, libxml2, deadbeef, glib, gtk3 }:

stdenv.mkDerivation rec {
  pname = "deadbeef-headerbar-gtk3-plugin";
  version = "unstable-2021-12-16";

  src = fetchFromGitHub {
    owner = "saivert";
    repo = "ddb_misc_headerbar_GTK3";
    rev = "a264cb4246c2958e6aadab06d9f7983ef56979ad";
    hash = "sha256-hCb7ktyhat5ge33wWrIgfdy2Jk+2+0S8R4Wu6x340fY=";
  };

  nativeBuildInputs = [ autoconf automake libtool pkg-config libxml2 ];
  buildInputs = [ deadbeef glib gtk3 ];

  # Choose correct installation path
  # https://github.com/saivert/ddb_misc_headerbar_GTK3/commit/50ff75f76aa9d40761e352311670a894bfcd5cf6#r30319680
  makeFlags = [ "pkglibdir=$(out)/lib/deadbeef" ];

  preConfigure = "./autogen.sh";

  meta = with lib; {
    description = "Plug-in that adds GTK 3 header bar to the DeaDBeeF music player";
    homepage = "https://github.com/saivert/ddb_misc_headerbar_GTK3";
    license = licenses.gpl2Plus;
    maintainers = [ maintainers.jtojnar ];
    platforms = platforms.linux;
  };
}
