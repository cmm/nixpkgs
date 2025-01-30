{
  lib,
  buildGoModule,
  fetchFromGitHub,
  buildEnv,
  linkFarm,
  makeWrapper,
  stdenv,
  addDriverRunpath,
  nix-update-script,

  cmake,
  gitMinimal,
  rsync,
  clblast,
  libdrm,
  rocmPackages,
  cudaPackages,
  shaderc,
  vulkan-headers,
  vulkan-loader,
  libcap,
  darwin,
  autoAddDriverRunpath,
  versionCheckHook,

  # passthru
  nixosTests,
  testers,
  ollama,
  ollama-rocm,
  ollama-cuda,

  config,
  # one of `[ null false "rocm" "cuda" "vulkan" ]`
  acceleration ? null,
}:

assert builtins.elem acceleration [
  null
  false
  "rocm"
  "cuda"
  "vulkan"
];

let
  pname = "ollama";
  # don't forget to invalidate all hashes each update
  version = "unstable-2025-01-31";

  llama-cpp-rev = "46e3556e01b824e52395fb050b29804b6cff2a7c";

  src = fetchFromGitHub {
    owner = "ollama";
    repo = "ollama";
    rev = "39fd89308c0bbe26311db583cf9729f81ffa9a94";
    hash = "sha256-1t3uDX+FWFpJKmjODiM8rnLsLyTkqa/O9XCyLfsTddY=";
  };

  llama-cpp-src = fetchFromGitHub {
    owner = "ggerganov";
    repo = "llama.cpp";
    rev = llama-cpp-rev;
    hash = "sha256-OJM3Qjpp6qpq/6tXGh2TGKaFcO/NwwrHP1ngRy6rBFg=";
    leaveDotGit = true;
    postFetch = ''
      actual_requested_llama_rev=$(cat ${src}/llama/vendoring)
      actual_requested_llama_rev=''${actual_requested_llama_rev#LLAMACPP_BASE_COMMIT=}
      [[ $actual_requested_llama_rev == ${llama-cpp-rev} ]] || {
        echo 1>&2 "Please fix llama-cpp-rev: expected ${llama-cpp-rev}, got $$actual_requested_llama_rev"
        exit 1
      }

      git clean -fdx
      # apply Ollama patches like Makefile.sync wants
      for p in ${src}/llama/patches/*.patch; do
        git -c user.name=nobody -c user.email='<>' am -3 $p
      done
      # remove .git for reproducibility
      rm -r .git
    '';
  };

  vendorHash = "sha256-wtmtuwuu+rcfXsyte1C4YLQA4pnjqqxFmH1H18Fw75g=";

  validateFallback = lib.warnIf (config.rocmSupport && config.cudaSupport) (lib.concatStrings [
    "both `nixpkgs.config.rocmSupport` and `nixpkgs.config.cudaSupport` are enabled, "
    "but they are mutually exclusive; falling back to cpu"
  ]) (!(config.rocmSupport && config.cudaSupport));
  shouldEnable =
    mode: fallback: (acceleration == mode) || (fallback && acceleration == null && validateFallback);

  rocmRequested = shouldEnable "rocm" config.rocmSupport;
  cudaRequested = shouldEnable "cuda" config.cudaSupport;
  vulkanRequested = shouldEnable "vulkan" true;

  enableRocm = rocmRequested && stdenv.hostPlatform.isLinux;
  enableCuda = cudaRequested && stdenv.hostPlatform.isLinux;
  enableVulkan = vulkanRequested && stdenv.hostPlatform.isLinux;

  rocmLibs = [
    rocmPackages.clr
    rocmPackages.hipblas
    rocmPackages.rocblas
    rocmPackages.rocsolver
    rocmPackages.rocsparse
    rocmPackages.rocm-device-libs
    rocmPackages.rocm-smi
  ];
  rocmClang = linkFarm "rocm-clang" { llvm = rocmPackages.llvm.clang; };
  rocmPath = buildEnv {
    name = "rocm-path";
    paths = rocmLibs ++ [ rocmClang ];
  };

  cudaLibs = [
    cudaPackages.cuda_cudart
    cudaPackages.libcublas
    cudaPackages.cuda_cccl
  ];

  vulkanLibs = [
    libcap
    vulkan-headers
    vulkan-loader
  ];

  # Extract the major version of CUDA. e.g. 11 12
  cudaMajorVersion = lib.versions.major cudaPackages.cuda_cudart.version;

  cudaToolkit = buildEnv {
    # ollama hardcodes the major version in the Makefile to support different variants.
    # - https://github.com/ollama/ollama/blob/v0.4.4/llama/Makefile#L17-L18
    name = "cuda-merged-${cudaMajorVersion}";
    paths = map lib.getLib cudaLibs ++ [
      (lib.getOutput "static" cudaPackages.cuda_cudart)
      (lib.getBin (cudaPackages.cuda_nvcc.__spliced.buildHost or cudaPackages.cuda_nvcc))
    ];
  };

  cudaPath = lib.removeSuffix "-${cudaMajorVersion}" cudaToolkit;

  metalFrameworks = with darwin.apple_sdk_11_0.frameworks; [
    Accelerate
    Metal
    MetalKit
    MetalPerformanceShaders
  ];

  wrapperOptions =
    [
      # ollama embeds llama-cpp binaries which actually run the ai models
      # these llama-cpp binaries are unaffected by the ollama binary's DT_RUNPATH
      # LD_LIBRARY_PATH is temporarily required to use the gpu
      # until these llama-cpp binaries can have their runpath patched
      "--suffix LD_LIBRARY_PATH : '${addDriverRunpath.driverLink}/lib'"
    ]
    ++ lib.optionals enableRocm [
      "--suffix LD_LIBRARY_PATH : '${rocmPath}/lib'"
      "--set-default HIP_PATH '${rocmPath}'"
    ]
    ++ lib.optionals enableCuda [
      "--suffix LD_LIBRARY_PATH : '${lib.makeLibraryPath (map lib.getLib cudaLibs)}'"
    ]
    ++ lib.optionals enableVulkan [
      "--suffix LD_LIBRARY_PATH : '${lib.makeLibraryPath (map lib.getLib vulkanLibs)}'"
    ];
  wrapperArgs = builtins.concatStringsSep " " wrapperOptions;

  preset =
    if cudaRequested then
      "CUDA"
    else if rocmRequested then
      "ROCm"
    else if vulkanRequested then
      "Vulkan"
    else
      "CPU";

  goBuild =
    if enableCuda then
      buildGoModule.override { stdenv = cudaPackages.backendStdenv; }
    else
      buildGoModule;
  inherit (lib) licenses platforms maintainers;
in
goBuild {
  inherit
    pname
    version
    src
    vendorHash
    ;

  patches = [
    ./vulkan-discovery.patch
    ./vulkan-preset.patch
    ./vulkan-build.patch
  ];

  env =
    lib.optionalAttrs enableRocm {
      ROCM_PATH = rocmPath;
      CLBlast_DIR = "${clblast}/lib/cmake/CLBlast";
      HIP_PATH = rocmPath;
    }
    // lib.optionalAttrs enableCuda { CUDA_PATH = cudaPath; };

  nativeBuildInputs =
    [
      cmake
      gitMinimal
      rsync
    ]
    ++ lib.optionals enableRocm [
      rocmPackages.llvm.bintools
      rocmLibs
    ]
    ++ lib.optionals enableCuda [ cudaPackages.cuda_nvcc ]
    ++ lib.optionals enableVulkan [ shaderc ]
    ++ lib.optionals (enableRocm || enableCuda || enableVulkan) [
      makeWrapper
      autoAddDriverRunpath
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin metalFrameworks;

  buildInputs =
    lib.optionals enableRocm (rocmLibs ++ [ libdrm ])
    ++ lib.optionals enableCuda cudaLibs
    ++ lib.optionals enableVulkan vulkanLibs
    ++ lib.optionals stdenv.hostPlatform.isDarwin metalFrameworks;

  # replace inaccurate version number with actual release version
  postPatch = ''
    substituteInPlace version/version.go \
      --replace-fail 0.0.0 '${version}'

    # put the patched llama.cpp in the expected place
    cp -r ${llama-cpp-src} llama/vendor
    chmod -R +w llama/vendor

    # do other things "make -f Makefile.sync sync" would do
    rsync -arvzc -f "merge llama/llama.cpp/.rsync-filter" llama/vendor/ llama/llama.cpp
    rsync -arvzc -f "merge ml/backend/ggml/ggml/.rsync-filter" llama/vendor/ggml/ ml/backend/ggml/ggml
  '';

  overrideModAttrs = (
    finalAttrs: prevAttrs: {
      # don't run llama.cpp build in the module fetch phase
      preBuild = "";
    }
  );

  preBuild = ''
    echo '*** preset: ${preset}'
    cmake --preset ${preset}
  '';

  cmakeFlags = [
    "--preset"
    "${preset}"
  ];

  postInstall =
    lib.optionalString (stdenv.hostPlatform.isx86 || enableRocm || enableCuda || enableVulkan)
      ''
        # copy libggml_*.so and runners into lib
        # https://github.com/ollama/ollama/blob/v0.4.4/llama/make/gpu.make#L90
        mkdir -p $out/lib
        cp -r dist/*/lib/* $out/lib/
      '';

  postFixup =
    # the app doesn't appear functional at the moment, so hide it
    ''
      mv "$out/bin/app" "$out/bin/.ollama-app"
    ''
    # expose runtime libraries necessary to use the gpu
    + lib.optionalString (enableRocm || enableCuda || enableVulkan) ''
      wrapProgram "$out/bin/ollama" ${wrapperArgs}
    '';

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/ollama/ollama/version.Version=${version}"
    "-X=github.com/ollama/ollama/server.mode=release"
  ];

  __darwinAllowLocalNetworking = true;

  nativeInstallCheck = [ versionCheckHook ];
  versionCheckProgramArg = [ "--version" ];
  doInstallCheck = true;

  passthru = {
    tests =
      {
        inherit ollama;
        version = testers.testVersion {
          inherit version;
          package = ollama;
        };
      }
      // lib.optionalAttrs stdenv.hostPlatform.isLinux {
        inherit ollama-rocm ollama-cuda;
        service = nixosTests.ollama;
        service-cuda = nixosTests.ollama-cuda;
        service-rocm = nixosTests.ollama-rocm;
      };
  } // lib.optionalAttrs (!enableRocm && !enableCuda) { updateScript = nix-update-script { }; };

  meta = {
    description =
      "Get up and running with large language models locally"
      + lib.optionalString rocmRequested ", using ROCm for AMD GPU acceleration"
      + lib.optionalString cudaRequested ", using CUDA for NVIDIA GPU acceleration"
      + lib.optionalString vulkanRequested ", using Vulkan acceleration";
    homepage = "https://github.com/ollama/ollama";
    changelog = "https://github.com/ollama/ollama/releases/tag/v${version}";
    license = licenses.mit;
    platforms =
      if (rocmRequested || cudaRequested || vulkanRequested) then platforms.linux else platforms.unix;
    mainProgram = "ollama";
    maintainers = with maintainers; [
      abysssol
      dit7ya
      elohmeier
      roydubnium
    ];
  };
}
