{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  alsa-lib,
  fftw,
  gsl,
  motif,
  xorg,
}:

stdenv.mkDerivation rec {
  pname = "snd";
  version = "25.4";

  src = fetchurl {
    url = "mirror://sourceforge/snd/snd-${version}.tar.gz";
    hash = "sha256-lXcyeqLzd4a5HLm12Y6QMIzaFF3penyZri+yC2Iej4I=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    fftw
    gsl
    motif
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
  ]
  ++ (with xorg; [
    libXext
    libXft
    libXpm
    libXt
  ]);

  configureFlags = [
    "--with-motif"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Sound editor";
    homepage = "https://ccrma.stanford.edu/software/snd/";
    platforms = platforms.unix;
    license = licenses.free;
    maintainers = [ ];
    mainProgram = "snd";
  };
}
