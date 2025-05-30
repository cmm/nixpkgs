{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  python3,
}:

let
  platform =
    {
      aarch64-linux = "armlinux64";
      x86_64-linux = "linux64";
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation rec {
  pname = "gurobi";
  version = "12.0.2";

  src = fetchurl {
    url = "https://packages.gurobi.com/${lib.versions.majorMinor version}/gurobi${version}_${platform}.tar.gz";
    hash =
      {
        aarch64-linux = "sha256-vlhF3OIMCVyS9Y31RS4eVhs4wQ4CUDGQZlNkf98Uji0=";
        x86_64-linux = "sha256-DMSmk41YzGoonHdX2xLsioU9RTBLn4kQy4v6HgVa08U=";
      }
      .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  };

  sourceRoot = "gurobi${builtins.replaceStrings [ "." ] [ "" ] version}/${platform}";

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    (python3.withPackages (ps: [
      ps.gurobipy
    ]))
  ];

  strictDeps = true;

  makeFlags = [ "--directory=src/build" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp bin/* $out/bin/
    rm $out/bin/gurobi.sh
    rm $out/bin/python*

    cp lib/gurobi.py $out/bin/gurobi.sh

    mkdir -p $out/include
    cp include/gurobi*.h $out/include/

    mkdir -p $out/lib
    cp lib/*.jar $out/lib/
    cp lib/libGurobiJni*.so $out/lib/
    cp lib/libgurobi*.so* $out/lib/
    cp lib/libgurobi*.a $out/lib/
    cp src/build/*.a $out/lib/

    mkdir -p $out/share/java
    ln -s $out/lib/gurobi.jar $out/share/java/
    ln -s $out/lib/gurobi-javadoc.jar $out/share/java/

    runHook postInstall
  '';

  passthru.libSuffix = lib.replaceStrings [ "." ] [ "" ] (lib.versions.majorMinor version);

  meta = {
    description = "Optimization solver for mathematical programming";
    homepage = "https://www.gurobi.com";
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
    license = lib.licenses.unfree;
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    maintainers = with lib.maintainers; [ wegank ];
  };
}
