{
  mkDerivation,
  lib,
  extra-cmake-modules,
  kdoctools,
  shared-mime-info,
  exiv2,
  kactivities,
  kactivities-stats,
  karchive,
  kbookmarks,
  kconfig,
  kconfigwidgets,
  kcoreaddons,
  kdbusaddons,
  kdsoap,
  kguiaddons,
  kdnssd,
  kiconthemes,
  ki18n,
  kio,
  khtml,
  kpty,
  syntax-highlighting,
  libmtp,
  libssh,
  openexr,
  libtirpc,
  phonon,
  qtsvg,
  samba,
  solid,
  gperf,
  taglib,
  libX11,
  libXcursor,
}:

mkDerivation {
  pname = "kio-extras";
  meta = {
    license = with lib.licenses; [
      gpl2
      lgpl21
    ];
    maintainers = [ lib.maintainers.ttuegel ];
  };
  nativeBuildInputs = [
    extra-cmake-modules
    kdoctools
    shared-mime-info
  ];
  buildInputs = [
    exiv2
    kactivities
    kactivities-stats
    karchive
    kbookmarks
    kconfig
    kconfigwidgets
    kcoreaddons
    kdbusaddons
    kdsoap
    kguiaddons
    kdnssd
    kiconthemes
    ki18n
    kio
    khtml
    kpty
    syntax-highlighting
    libmtp
    libssh
    openexr
    libtirpc
    phonon
    qtsvg
    samba
    solid
    gperf
    taglib
    libX11
    libXcursor
  ];

  # org.kde.kmtpd5 DBUS service launches kiod5 binary from kio derivation, not from kio-extras
  postInstall = ''
    substituteInPlace $out/share/dbus-1/services/org.kde.kmtpd5.service \
      --replace Exec=$out Exec=${kio}
  '';

}
