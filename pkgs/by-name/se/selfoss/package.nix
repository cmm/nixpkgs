{
  lib,
  stdenvNoCC,
  fetchurl,
  fetchpatch,
  unzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "selfoss";
  version = "2.19";

  src = fetchurl {
    url = "https://github.com/SSilence/selfoss/releases/download/${version}/selfoss-${version}.zip";
    sha256 = "5JxHUOlyMneWPKaZtgLwn5FI4rnyWPzmsUQpSYrw5Pw=";
  };

  patches = fetchpatch {
    name = "any-auth";
    url = "https://github.com/cmm/selfoss/commit/28c5605e89182af6526a3ee53a7956502ddb865d.patch";
    hash = "sha256-Oh2jhIyCYecDdqcq/f0y5yG/UIJoj1olDJY/IiQ+Mu4=";
  };

  nativeBuildInputs = [
    unzip
  ];

  installPhase = ''
    runHook preInstall

    mkdir "$out"
    cp -ra \
      .htaccess \
      .nginx.conf \
      * \
      "$out/"

    runHook postInstall
  '';

  meta = {
    description = "Web-based news feed (RSS/Atom) aggregator";
    homepage = "https://selfoss.aditu.de";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      jtojnar
      regnat
    ];
    platforms = lib.platforms.all;
  };
}
