{
  lib,
  stdenv,
  buildPackages,
}:
# A special kind of derivation that is only meant to be consumed by the
# nix-shell.
lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;

  excludeDrvArgNames = [
    "packages"
    "inputsFrom"
  ];

  extendDrvArgs =
    _finalAttrs:
    {
      name ? "nix-shell",
      # a list of packages to add to the shell environment
      packages ? [ ],
      # propagate all the inputs from the given derivations
      inputsFrom ? [ ],
      ...
    }@attrs:
    let
      mergeInputs =
        name:
        (attrs.${name} or [ ])
        ++
          # 1. get all `{build,nativeBuild,...}Inputs` from the elements of `inputsFrom`
          # 2. since that is a list of lists, `flatten` that into a regular list
          # 3. filter out of the result everything that's in `inputsFrom` itself
          # this leaves actual dependencies of the derivations in `inputsFrom`, but never the derivations themselves
          (lib.subtractLists inputsFrom (lib.flatten (lib.catAttrs name inputsFrom)));

      merged = {
        buildInputs = mergeInputs "buildInputs";
        nativeBuildInputs = packages ++ (mergeInputs "nativeBuildInputs");
        propagatedBuildInputs = mergeInputs "propagatedBuildInputs";
        propagatedNativeBuildInputs = mergeInputs "propagatedNativeBuildInputs";
      };

      docPathShellHook =
        let
          unwrapCC = pkg: if pkg ? cc then unwrapCC pkg.cc else pkg;
          docInputs =
            builtins.concatLists (builtins.attrValues merged)
            # grab the unwrapped cc, as wrappers may or may not
            # retain doc outputs
            ++ (lib.optional (stdenv ? cc) (unwrapCC stdenv.cc))
            ++ stdenv.defaultBuildInputs
            ++ stdenv.defaultNativeBuildInputs
            ++ stdenv.initialPath;
          docDrvs = lib.unique (builtins.filter lib.isDerivation docInputs);
          # Existence of these directories is tested when the hook runs:
          # testing it here with builtins.pathExists would build every input
          # during evaluation (import-from-derivation).
          docPaths = type: map (drv: "${lib.getOutput type drv}/share/${type}") docDrvs;
          # Shell command substitution printing the existing directories among
          # `paths`, joined with ':'.
          existingDirs =
            paths:
            "$(sep=; for d in ${lib.escapeShellArgs paths}; do [ -d \"$d\" ] && printf %s%s \"$sep\" \"$d\" && sep=:; done)";
          infoPaths = docPaths "info";
          manPaths = docPaths "man";

          # some packages neglect to build an info dir file
          infoDirAddenda = stdenv.mkDerivation {
            inherit (stdenv) system;
            name = "${name}-info-dir-addenda";
            passAsFile = [ "buildCommand" ];
            buildCommand = ''
              shopt -s nullglob
              mkdir -p $out/share/info
              for path in ${lib.escapeShellArgs infoPaths}; do
                [[ -d $path ]] || continue
                [[ -s $path/dir ]] && continue || :
                for file in $path/*.info{,.gz}; do
                  ${buildPackages.texinfo}/bin/install-info $file $out/share/info/dir
                done
              done
            '';
          };
        in
        ''
          __mkshell_info_dirs="${existingDirs infoPaths}"
          export INFOPATH="''${__mkshell_info_dirs:+$__mkshell_info_dirs:}${infoDirAddenda}/share/info:$INFOPATH"
          unset __mkshell_info_dirs
          export MANPATH="${existingDirs manPaths}:$MANPATH"
        '';
    in
    {
      inherit name;

      inherit (merged)
        buildInputs
        nativeBuildInputs
        propagatedBuildInputs
        propagatedNativeBuildInputs
        ;

      shellHook = lib.concatStringsSep "\n" (
        (lib.catAttrs "shellHook" (lib.reverseList inputsFrom ++ [ attrs ])) ++ [ docPathShellHook ]
      );

      phases = attrs.phases or [ "buildPhase" ];

      buildPhase =
        attrs.buildPhase or ''
          { echo "------------------------------------------------------------";
            echo " WARNING: the existence of this path is not guaranteed.";
            echo " It is an internal implementation detail for pkgs.mkShell.";
            echo "------------------------------------------------------------";
            echo;
            # Record all build inputs as runtime dependencies
            export;
          } >> "$out"
        '';

      preferLocalBuild = attrs.preferLocalBuild or true;
      allowSubstitutes = attrs.allowSubstitutes or false;
    };
}
