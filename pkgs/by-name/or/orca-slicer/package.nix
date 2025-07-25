{
  stdenv,
  lib,
  binutils,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  pkg-config,
  wrapGAppsHook3,
  boost186,
  cereal,
  cgal,
  curl,
  dbus,
  eigen,
  expat,
  ffmpeg,
  gcc-unwrapped,
  glew,
  glfw,
  glib,
  glib-networking,
  gmp,
  gst_all_1,
  gtest,
  gtk3,
  hicolor-icon-theme,
  ilmbase,
  libpng,
  mpfr,
  nlopt,
  opencascade-occt_7_6,
  openvdb,
  opencv,
  pcre,
  systemd,
  tbb_2021,
  webkitgtk_4_0,
  wxGTK31,
  xorg,
  libnoise,
  withSystemd ? stdenv.hostPlatform.isLinux,
}:
let
  wxGTK' =
    (wxGTK31.override {
      withCurl = true;
      withPrivateFonts = true;
      withWebKit = true;
    }).overrideAttrs
      (old: {
        configureFlags = old.configureFlags ++ [
          # Disable noisy debug dialogs
          "--enable-debug=no"
        ];
      });
in
stdenv.mkDerivation (finalAttrs: {
  pname = "orca-slicer";
  version = "v2.3.0";

  src = fetchFromGitHub {
    owner = "SoftFever";
    repo = "OrcaSlicer";
    tag = finalAttrs.version;
    hash = "sha256-MEa57jFBJkqwoAkqI7wXOn1X1zxgLQt3SNeanfD88kU=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapGAppsHook3
    wxGTK'
  ];

  buildInputs = [
    binutils
    (boost186.override {
      enableShared = true;
      enableStatic = false;
      extraFeatures = [
        "log"
        "thread"
        "filesystem"
      ];
    })
    boost186.dev
    cereal
    cgal
    curl
    dbus
    eigen
    expat
    ffmpeg
    gcc-unwrapped
    glew
    glfw
    glib
    glib-networking
    gmp
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-good
    gtk3
    hicolor-icon-theme
    ilmbase
    libpng
    mpfr
    nlopt
    opencascade-occt_7_6
    openvdb
    pcre
    tbb_2021
    webkitgtk_4_0
    wxGTK'
    xorg.libX11
    opencv.cxxdev
    libnoise
  ]
  ++ lib.optionals withSystemd [ systemd ]
  ++ finalAttrs.checkInputs;

  patches = [
    # Fix for webkitgtk linking
    ./patches/0001-not-for-upstream-CMakeLists-Link-against-webkit2gtk-.patch
    # Link opencv_core and opencv_imgproc instead of opencv_world
    ./patches/dont-link-opencv-world-orca.patch
    # Don't link osmesa
    ./patches/no-osmesa.patch
    # The changeset from https://github.com/SoftFever/OrcaSlicer/pull/7650, can be removed when that PR gets merged
    # Allows disabling the update nag screen
    (fetchpatch {
      name = "pr-7650-configurable-update-check.patch";
      url = "https://github.com/SoftFever/OrcaSlicer/commit/d10a06ae11089cd1f63705e87f558e9392f7a167.patch";
      hash = "sha256-t4own5AwPsLYBsGA15id5IH1ngM0NSuWdFsrxMRXmTk=";
    })
  ];

  doCheck = true;
  checkInputs = [ gtest ];

  separateDebugInfo = true;

  NLOPT = nlopt;

  NIX_CFLAGS_COMPILE = toString (
    [
      "-Wno-ignored-attributes"
      "-I${opencv.out}/include/opencv4"
      "-Wno-error=incompatible-pointer-types"
      "-Wno-template-id-cdtor"
      "-Wno-uninitialized"
      "-Wno-unused-result"
      "-Wno-deprecated-declarations"
      "-Wno-use-after-free"
      "-Wno-format-overflow"
      "-Wno-stringop-overflow"
      "-DBOOST_ALLOW_DEPRECATED_HEADERS"
      "-DBOOST_MATH_DISABLE_STD_FPCLASSIFY"
      "-DBOOST_MATH_NO_LONG_DOUBLE_MATH_FUNCTIONS"
      "-DBOOST_MATH_DISABLE_FLOAT128"
      "-DBOOST_MATH_NO_QUAD_SUPPORT"
      "-DBOOST_MATH_MAX_FLOAT128_DIGITS=0"
      "-DBOOST_CSTDFLOAT_NO_LIBQUADMATH_SUPPORT"
      "-DBOOST_MATH_DISABLE_FLOAT128_BUILTIN_FPCLASSIFY"
    ]
    # Making it compatible with GCC 14+, see https://github.com/SoftFever/OrcaSlicer/pull/7710
    ++ lib.optionals (stdenv.cc.isGNU && lib.versionAtLeast stdenv.cc.version "14") [
      "-Wno-error=template-id-cdtor"
    ]
  );

  NIX_LDFLAGS = toString [
    (lib.optionalString withSystemd "-ludev")
    "-L${boost186}/lib"
    "-lboost_log"
    "-lboost_log_setup"
  ];

  prePatch = ''
    sed -i 's|nlopt_cxx|nlopt|g' cmake/modules/FindNLopt.cmake
    sed -i 's|"libnoise/noise.h"|"noise/noise.h"|' src/libslic3r/PerimeterGenerator.cpp
  '';

  cmakeFlags = [
    (lib.cmakeBool "SLIC3R_STATIC" false)
    (lib.cmakeBool "SLIC3R_FHS" true)
    (lib.cmakeFeature "SLIC3R_GTK" "3")
    (lib.cmakeBool "BBL_RELEASE_TO_PUBLIC" true)
    (lib.cmakeBool "BBL_INTERNAL_TESTING" false)
    (lib.cmakeBool "SLIC3R_BUILD_TESTS" false)
    (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-DGL_SILENCE_DEPRECATION")
    (lib.cmakeFeature "CMAKE_EXE_LINKER_FLAGS" "-Wl,--no-as-needed")
    (lib.cmakeBool "ORCA_VERSION_CHECK_DEFAULT" false)
    (lib.cmakeFeature "LIBNOISE_INCLUDE_DIR" "${libnoise}/include/noise")
    (lib.cmakeFeature "LIBNOISE_LIBRARY" "${libnoise}/lib/libnoise-static.a")
    "-Wno-dev"
  ];

  # Generate translation files
  postBuild = "( cd .. && ./run_gettext.sh )";

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "$out/lib:${
        lib.makeLibraryPath [
          glew
        ]
      }"
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1
    )
  '';

  meta = {
    description = "G-code generator for 3D printers (Bambu, Prusa, Voron, VzBot, RatRig, Creality, etc.)";
    homepage = "https://github.com/SoftFever/OrcaSlicer";
    changelog = "https://github.com/SoftFever/OrcaSlicer/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [
      zhaofengli
      ovlach
      pinpox
      liberodark
    ];
    mainProgram = "orca-slicer";
    platforms = lib.platforms.linux;
  };
})
