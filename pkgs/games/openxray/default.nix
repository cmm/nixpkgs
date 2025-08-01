{
  lib,
  stdenv,
  fetchFromGitHub,
  gitUpdater,
  cmake,
  glew,
  liblockfile,
  openal,
  libtheora,
  SDL2,
  lzo,
  libjpeg,
  libogg,
  pcre,
  makeWrapper,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "openxray";
  version = "2921-january-2025-rc1";

  src = fetchFromGitHub {
    owner = "OpenXRay";
    repo = "xray-16";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-PYRC1t4gjT2d41ZZOZJF4u3vc0Pq7DpivEnnfbcSQYk=";
  };

  # Don't force-override these please
  postPatch = ''
    substituteInPlace Externals/LuaJIT-proj/CMakeLists.txt \
      --replace-fail 'set(CMAKE_OSX_SYSROOT' '#set(CMAKE_OSX_SYSROOT' \
      --replace-fail 'set(ENV{SDKROOT}' '#set(ENV{SDKROOT}'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    makeWrapper
  ];

  buildInputs = [
    glew
    liblockfile
    openal
    libtheora
    SDL2
    lzo
    libjpeg
    libogg
    pcre
  ];

  cmakeFlags = [
    # Breaks on Darwin
    (lib.cmakeBool "USE_LTO" (!stdenv.hostPlatform.isDarwin))
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    # This seemingly only gets set properly by CMake when using the XCode generator
    (lib.cmakeFeature "CMAKE_OSX_DEPLOYMENT_TARGET" "${stdenv.hostPlatform.darwinMinVersion}")
  ];

  # Crashes can happen, we'd like them to be reasonably debuggable
  cmakeBuildType = "RelWithDebInfo";
  dontStrip = true;

  # Because we work around https://github.com/OpenXRay/xray-16/issues/1224 by using GCC,
  # we need a followup workaround for Darwin locale stuff when using GCC:
  # runtime error: locale::facet::_S_create_c_locale name not valid
  postInstall = lib.optionalString stdenv.hostPlatform.isDarwin ''
    wrapProgram $out/bin/xr_3da \
      --run 'export LC_ALL=C'
  '';

  # dlopens its own libraries, relies on rpath not having its prefix stripped
  dontPatchELF = true;

  passthru.updateScript = gitUpdater { };

  meta = with lib; {
    mainProgram = "xr_3da";
    description = "Improved version of the X-Ray Engine, the game engine used in the world-famous S.T.A.L.K.E.R. game series by GSC Game World";
    homepage = "https://github.com/OpenXRay/xray-16/";
    license = licenses.unfree // {
      url = "https://github.com/OpenXRay/xray-16/blob/${finalAttrs.version}/License.txt";
    };
    maintainers = with maintainers; [ OPNA2608 ];
    platforms = [
      "x86_64-linux"
      "i686-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
})
