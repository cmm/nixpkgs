{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  orcania,
  systemd,
  check,
  subunit,
  withSystemd ? lib.meta.availableOn stdenv.hostPlatform systemd,
}:

stdenv.mkDerivation rec {
  pname = "yder";
  version = "1.4.20";

  src = fetchFromGitHub {
    owner = "babelouest";
    repo = "yder";
    rev = "v${version}";
    sha256 = "sha256-BaCF1r5mOYxj0zKc11uoKI9gVKuxWd8GaneGcV+qIFg=";
  };

  patches = [
    # We set CMAKE_INSTALL_LIBDIR to the absolute path in $out, so
    # prefix and exec_prefix cannot be $out, too
    ./fix-pkgconfig.patch
  ];

  nativeBuildInputs = [ cmake ];

  buildInputs = [ orcania ] ++ lib.optional withSystemd systemd;

  nativeCheckInputs = [
    check
    subunit
  ];

  cmakeFlags = [
    "-DBUILD_YDER_TESTING=on"
  ]
  ++ lib.optional (!withSystemd) "-DWITH_JOURNALD=off";

  doCheck = true;

  meta = with lib; {
    description = "Logging library for C applications";
    homepage = "https://github.com/babelouest/yder";
    license = licenses.lgpl21;
    maintainers = with maintainers; [ johnazoidberg ];
    platforms = platforms.all;
  };
}
