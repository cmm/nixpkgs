{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  wrapGAppsHook3,
  libX11,
  libzip,
  glfw,
  libpng,
  xorg,
  zenity,
}:

stdenv.mkDerivation rec {
  pname = "tev";
  version = "1.29";

  src = fetchFromGitHub {
    owner = "Tom94";
    repo = "tev";
    rev = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-ke1T5nOrDoJilpfshAIAFWw/640Gm5OaxZ+ZakCevTs=";
  };

  nativeBuildInputs = [
    cmake
    wrapGAppsHook3
  ];
  buildInputs = [
    libX11
    libzip
    glfw
    libpng
  ]
  ++ (with xorg; [
    libXrandr
    libXinerama
    libXcursor
    libXi
    libXxf86vm
    libXext
  ]);

  dontWrapGApps = true; # We also need zenity (see below)

  cmakeFlags = [
    "-DTEV_DEPLOY=1" # Only relevant not to append "dev" to the version
  ];

  postInstall = ''
    wrapProgram $out/bin/tev \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH ":" "${zenity}/bin"
  '';

  env.CXXFLAGS = "-include cstdint";

  meta = {
    description = "High dynamic range (HDR) image comparison tool";
    mainProgram = "tev";
    longDescription = ''
      A high dynamic range (HDR) image comparison tool for graphics people. tev
      allows viewing images through various tonemapping operators and inspecting
      the values of individual pixels. Often, it is important to find exact
      differences between pairs of images. For this purpose, tev allows rapidly
      switching between opened images and visualizing various error metrics (L1,
      L2, and relative versions thereof). To avoid clutter, opened images and
      their layers can be filtered by keywords.
      While the predominantly supported file format is OpenEXR certain other
      types of images can also be loaded.
    '';
    inherit (src.meta) homepage;
    changelog = "https://github.com/Tom94/tev/releases/tag/v${version}";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
    broken = stdenv.hostPlatform.isDarwin; # needs apple frameworks + SDK fix? see #205247
    maintainers = with lib.maintainers; [ ];
  };
}
