{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  scdoc,
}:

buildGoModule rec {
  pname = "shfmt";
  version = "3.12.0";

  src = fetchFromGitHub {
    owner = "mvdan";
    repo = "sh";
    rev = "v${version}";
    hash = "sha256-3a0N5GsqZvJVx1qhsTzwtC2SBtexdXJMalerM+joNIc=";
  };

  vendorHash = "sha256-jvsX0nn9cHq2cZUrD9E1eMtOiy5I4wfpngAc+6qUbEE=";

  subPackages = [ "cmd/shfmt" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  nativeBuildInputs = [
    installShellFiles
    scdoc
  ];

  postBuild = ''
    scdoc < cmd/shfmt/shfmt.1.scd > shfmt.1
    installManPage shfmt.1
  '';

  meta = with lib; {
    homepage = "https://github.com/mvdan/sh";
    description = "Shell parser and formatter";
    longDescription = ''
      shfmt formats shell programs. It can use tabs or any number of spaces to indent.
      You can feed it standard input, any number of files or any number of directories to recurse into.
    '';
    license = licenses.bsd3;
    maintainers = with maintainers; [
      zowoq
      SuperSandro2000
    ];
    mainProgram = "shfmt";
  };
}
