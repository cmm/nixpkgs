{ pkgs, haskellLib }:

self: super:

with haskellLib;

let
  inherit (pkgs) lib;

  warnAfterVersion =
    ver: pkg:
    lib.warnIf (lib.versionOlder ver
      super.${pkg.pname}.version
    ) "override for haskell.packages.ghc96.${pkg.pname} may no longer be needed" pkg;

in

{
  llvmPackages = lib.dontRecurseIntoAttrs self.ghc.llvmPackages;

  # Disable GHC core libraries
  array = null;
  base = null;
  binary = null;
  bytestring = null;
  Cabal = null;
  Cabal-syntax = null;
  containers = null;
  deepseq = null;
  directory = null;
  exceptions = null;
  filepath = null;
  ghc-bignum = null;
  ghc-boot = null;
  ghc-boot-th = null;
  ghc-compact = null;
  ghc-heap = null;
  ghc-prim = null;
  ghci = null;
  haskeline = null;
  hpc = null;
  integer-gmp = null;
  libiserv = null;
  mtl = null;
  parsec = null;
  pretty = null;
  process = null;
  rts = null;
  stm = null;
  system-cxx-std-lib = null;
  template-haskell = null;
  # terminfo is not built if GHC is a cross compiler
  terminfo =
    if pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform then
      null
    else
      doDistribute self.terminfo_0_4_1_7;
  text = null;
  time = null;
  transformers = null;
  unix = null;
  xhtml = null;

  # Becomes a core package in GHC >= 9.8
  semaphore-compat = doDistribute self.semaphore-compat_1_0_0;

  # Needs base-orphans for GHC < 9.8 / base < 4.19
  some = addBuildDepend self.base-orphans super.some;

  #
  # Version deviations from Stackage LTS
  #

  # Too strict upper bound on template-haskell
  # https://github.com/mokus0/th-extras/pull/21
  th-extras = doJailbreak super.th-extras;

  # not in Stackage, needs to match ghc-lib
  # since expression is generated for 9.8, ghc-lib dep needs to be added manually
  ghc-tags = doDistribute (addBuildDepends [ self.ghc-lib ] self.ghc-tags_1_8);

  #
  # Too strict bounds without upstream fix
  #

  # Forbids transformers >= 0.6
  quickcheck-classes-base = doJailbreak super.quickcheck-classes-base;
  # https://github.com/Gabriella439/Haskell-Break-Library/pull/3
  break = doJailbreak super.break;
  # Forbids mtl >= 2.3
  ChasingBottoms = doJailbreak super.ChasingBottoms;
  # Forbids base >= 4.18
  cabal-install-solver = doJailbreak super.cabal-install-solver;
  cabal-install = doJailbreak super.cabal-install;

  # Forbids base >= 4.18, fix proposed: https://github.com/sjakobi/newtype-generics/pull/25
  newtype-generics = warnAfterVersion "0.6.2" (doJailbreak super.newtype-generics);

  # Jailbreaks for servant <0.20
  servant-lucid = doJailbreak super.servant-lucid;

  stm-containers = dontCheck super.stm-containers;
  regex-tdfa = dontCheck super.regex-tdfa;
  hiedb = dontCheck super.hiedb;
  retrie = dontCheck super.retrie;
  # https://github.com/kowainik/relude/issues/436
  relude = dontCheck (doJailbreak super.relude);

  inherit (pkgs.lib.mapAttrs (_: doJailbreak) super)
    ghc-trace-events
    gi-cairo-connector # mtl <2.3
    ghc-prof # base <4.18
    env-guard # doctest <0.21
    package-version # doctest <0.21, tasty-hedgehog <1.4
    ;

  # Pending text-2.0 support https://github.com/gtk2hs/gtk2hs/issues/327
  gtk = doJailbreak super.gtk;

  # 2023-12-23: It needs this to build under ghc-9.6.3.
  #   A factor of 100 is insufficient, 200 seems seems to work.
  hip = appendConfigureFlag "--ghc-options=-fsimpl-tick-factor=200" super.hip;

  # This can be removed once https://github.com/typeclasses/ascii-predicates/pull/1
  # is merged and in a release that's being tracked.
  ascii-predicates = appendPatch (pkgs.fetchpatch {
    url = "https://github.com/typeclasses/ascii-predicates/commit/2e6d9ed45987a8566f3a77eedf7836055c076d1a.patch";
    name = "ascii-predicates-pull-1.patch";
    relative = "ascii-predicates";
    sha256 = "sha256-4JguQFZNRQpjZThLrAo13jNeypvLfqFp6o7c1bnkmZo=";
  }) super.ascii-predicates;

  # This can be removed once https://github.com/typeclasses/ascii-numbers/pull/1
  # is merged and in a release that's being tracked.
  ascii-numbers = appendPatch (pkgs.fetchpatch {
    url = "https://github.com/typeclasses/ascii-numbers/commit/e9474ad91bc997891f1a46afd5d0bdf9b9f7d768.patch";
    name = "ascii-numbers-pull-1.patch";
    relative = "ascii-numbers";
    sha256 = "sha256-buw1UeW57CFefEfqdDUraSyQ+H/NvCZOv6WF2ORiYQg=";
  }) super.ascii-numbers;

  # Tests require nothunks < 0.3 (conflicting with Stackage) for GHC < 9.8
  aeson = dontCheck super.aeson;

  # Apply patch from PR with mtl-2.3 fix.
  ConfigFile = overrideCabal (drv: {
    editedCabalFile = null;
    buildDepends = drv.buildDepends or [ ] ++ [ self.HUnit ];
    patches = [
      (pkgs.fetchpatch {
        # https://github.com/jgoerzen/configfile/pull/12
        name = "ConfigFile-pr-12.patch";
        url = "https://github.com/jgoerzen/configfile/compare/d0a2e654be0b73eadbf2a50661d00574ad7b6f87...83ee30b43f74d2b6781269072cf5ed0f0e00012f.patch";
        sha256 = "sha256-b7u9GiIAd2xpOrM0MfILHNb6Nt7070lNRIadn2l3DfQ=";
      })
    ];
  }) super.ConfigFile;

  # https://github.com/NixOS/nixpkgs/pull/367998#issuecomment-2598941240
  libtorch-ffi-helper = unmarkBroken (doDistribute super.libtorch-ffi-helper);

  # Compatibility with core libs of GHC 9.6
  # Jailbreak to lift bound on time
  kqueue = doJailbreak (
    appendPatches [
      (pkgs.fetchpatch {
        name = "kqueue-ghc-9.6.patch";
        url = "https://github.com/hesselink/kqueue/pull/10/commits/a2735e807d761410e776482ec04515d9cf76a7f5.patch";
        sha256 = "18rilz4nrwcmlvll3acjx2lp7s129pviggb8fy3hdb0z34ls5j84";
        excludes = [ ".gitignore" ];
      })
    ] super.kqueue
  );

  # This runs into the following GHC bug currently affecting 9.6.* and 9.8.* as
  # well as 9.10.1: https://gitlab.haskell.org/ghc/ghc/-/issues/24432
  inherit
    (lib.mapAttrs (
      _:
      overrideCabal (drv: {
        badPlatforms = drv.badPlatforms or [ ] ++ [ "aarch64-linux" ];
      })
    ) super)
    mueval
    lambdabot
    lambdabot-haskell-plugins
    ;

  singletons-base = dontCheck super.singletons-base;

  # A given major version of ghc-exactprint only supports one version of GHC.
  ghc-exactprint = addBuildDepend self.extra super.ghc-exactprint_1_7_1_0;
}
# super.ghc is required to break infinite recursion as Nix is strict in the attrNames
//
  lib.optionalAttrs (pkgs.stdenv.hostPlatform.isAarch64 && lib.versionOlder super.ghc.version "9.6.4")
    {
      # The NCG backend for aarch64 generates invalid jumps in some situations,
      # the workaround on 9.6 is to revert to the LLVM backend (which is used
      # for these sorts of situations even on 9.2 and 9.4).
      # https://gitlab.haskell.org/ghc/ghc/-/issues/23746#note_525318
      inherit (lib.mapAttrs (_: self.forceLlvmCodegenBackend) super)
        tls
        mmark
        ;
    }
