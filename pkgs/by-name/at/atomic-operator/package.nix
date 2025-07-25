{
  lib,
  fetchFromGitHub,
  python3,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "atomic-operator";
  version = "0.8.5";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "swimlane";
    repo = "atomic-operator";
    rev = version;
    hash = "sha256-DyNqu3vndyLkmfybCfTbgxk3t/ALg7IAkAMg4kBkH7Q=";
  };

  build-system = with python3.pkgs; [
    setuptools
  ];

  pythonRelaxDeps = [
    "charset_normalizer"
    "urllib3"
  ];

  dependencies = with python3.pkgs; [
    attrs
    certifi
    chardet
    charset-normalizer
    fire
    idna
    paramiko
    pick
    pypsrp
    pyyaml
    requests
    urllib3
  ];

  nativeCheckInputs = with python3.pkgs; [
    pytestCheckHook
  ];

  pythonImportsCheck = [
    "atomic_operator"
  ];

  disabledTests = [
    # Tests require network access
    "test_download_of_atomic_red_team_repo"
    "test_setting_input_arguments"
    "test_config_parser"
  ];

  meta = with lib; {
    description = "Tool to execute Atomic Red Team tests (Atomics)";
    mainProgram = "atomic-operator";
    homepage = "https://www.atomic-operator.com/";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
