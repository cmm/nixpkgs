{
  lib,
  stdenv,
  fetchPypi,
  buildPythonPackage,
  libmediainfo,
  setuptools-scm,
  pytest,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "pymediainfo";
  version = "7.0.1";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-DV31nsxhXiTFbzA7j2UVecasyrcmVxXl1CkYbXuiFRQ=";
  };

  postPatch = ''
    substituteInPlace pymediainfo/__init__.py \
      --replace "libmediainfo.0.dylib" \
                "${libmediainfo}/lib/libmediainfo.0${stdenv.hostPlatform.extensions.sharedLibrary}" \
      --replace "libmediainfo.dylib" \
                "${libmediainfo}/lib/libmediainfo${stdenv.hostPlatform.extensions.sharedLibrary}" \
      --replace "libmediainfo.so.0" \
                "${libmediainfo}/lib/libmediainfo${stdenv.hostPlatform.extensions.sharedLibrary}.0"
  '';

  nativeBuildInputs = [ setuptools-scm ];

  nativeCheckInputs = [
    pytest
  ];

  checkPhase = ''
    py.test -k 'not test_parse_url' tests
  '';

  pythonImportsCheck = [ "pymediainfo" ];

  meta = with lib; {
    description = "Python wrapper for the mediainfo library";
    homepage = "https://github.com/sbraz/pymediainfo";
    changelog = "https://github.com/sbraz/pymediainfo/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = [ ];
  };
}
