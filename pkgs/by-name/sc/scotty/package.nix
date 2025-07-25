{
  lib,
  stdenv,
  buildGoModule,
  fetchFromSourcehut,
  nix-update-script,
  testers,
}:

buildGoModule (finalAttrs: {
  pname = "scotty";
  version = "0.7.0";

  src = fetchFromSourcehut {
    owner = "~phw";
    repo = "scotty";
    rev = "v${finalAttrs.version}";
    hash = "sha256-NvFvayz8B69Vtl+Ghl9UBXqJqvka8p6hi2ClcQ7Xeys=";
  };

  # Otherwise checks fail with `panic: open /etc/protocols: operation not permitted` when sandboxing is enabled on Darwin
  # https://github.com/NixOS/nixpkgs/pull/381645#issuecomment-2656211797
  modPostBuild = ''
    substituteInPlace vendor/modernc.org/libc/honnef.co/go/netdb/netdb.go \
      --replace-fail '!os.IsNotExist(err)' '!os.IsNotExist(err) && !os.IsPermission(err)'
  '';

  vendorHash = "sha256-+Hypr514lp0MuZVH9R9LUP93TYq2VNGuZ+6OWytohc8=";

  env = {
    # *Some* locale is required to be set
    # https://git.sr.ht/~phw/scotty/tree/04eddfda33cc6f0b87dc0fcea43d5c4f50923ddc/item/internal/i18n/i18n.go#L30
    LC_ALL = "C.UTF-8";
  };

  passthru = {
    tests.version = testers.testVersion {
      # See above
      command = "LC_ALL='C.UTF-8' scotty --version";
      package = finalAttrs.finalPackage;
    };

    updateScript = nix-update-script { };
  };

  meta = {
    description = "Transfers your listens between various music listen tracking and streaming services";
    homepage = "https://git.sr.ht/~phw/scotty";
    changelog = "https://git.sr.ht/~phw/scotty/refs/v${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ getchoo ];
    mainProgram = "scotty";
  };
})
