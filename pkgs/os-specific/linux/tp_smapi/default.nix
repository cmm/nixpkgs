{
  stdenv,
  lib,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
}:

stdenv.mkDerivation (finalAttrs: {
  name = "${finalAttrs.pname}-${finalAttrs.version}-${kernel.version}";
  pname = "tp_smapi";
  version = "0.45";

  src = fetchFromGitHub {
    owner = "linux-thinkpad";
    repo = "tp_smapi";
    tag = "tp-smapi/${finalAttrs.version}";
    hash = "sha256-rB+DNgWUXd1oQBbDgVEAJVJ16nKCaKDtWGAmpcFsx+A=";
  };

  patches = [
    # Linux v7.2 removed function strncpy, have to use strscpy instead.
    # This is an open issue in upstream, patching with upstream PR's commit.
    # This patch should be removed once the PR is merged in upstream.
    #
    # Upstream issue: https://github.com/linux-thinkpad/tp_smapi/issues/82
    # Upstream pull request: https://github.com/linux-thinkpad/tp_smapi/pull/81
    # Upstream commit: https://github.com/linux-thinkpad/tp_smapi/commit/0483993a64f6d922d71dddd8f7f353d8bc22d1bf
    ./0001-use-strscpy-instead-of-strncpy.patch
  ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  hardeningDisable = [ "pic" ];

  makeFlags = kernelModuleMakeFlags ++ [
    "KBASE=${kernel.dev}/lib/modules/${kernel.modDirVersion}"
    "SHELL=${stdenv.shell}"
    "HDAPS=1"
    "INSTALL_MOD_PATH=${placeholder "out"}"
    "INSTALL_MOD_DIR=kernel/drivers/firmware"
    "DEPMOD=true"
  ];

  # The upstream install target requires root and removes existing modules.
  installTargets = [ "modules_install" ];

  installFlags = [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
  ];

  postInstall = ''
    # Keep the distinct hdapsd filename, including its compression suffix and certificate.
    for module in "$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/firmware/hdaps.ko"*; do
      mv "$module" "''${module/hdaps.ko/hdapsd.ko}"
    done
  '';

  dontStrip = true;

  enableParallelBuilding = true;

  meta = {
    description = "IBM ThinkPad hardware functions driver";
    homepage = "https://github.com/linux-thinkpad/tp_smapi";
    license = lib.licenses.gpl2Plus;
    maintainers = [ ];
    # driver is only meant for linux thinkpads, bellow platforms should cover it.
    platforms = [
      "x86_64-linux"
      "i686-linux"
    ];
  };
})
