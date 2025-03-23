{
  lib,
  sqlite,
  fetchFromGitHub,
  perlPackages,
}:

let
  perlDeps =
    ps: with ps; [
      CGI
      Carp
      CompressZlib
      DBDSQLite
      DBI
      DataDump
      DateManip
      DateTime
      DateTimeFormatISO8601
      DateTimeFormatSQLite
      DateTimeTimeZone
      DigestSHA
      FileHomeDir
      FileSlurp
      FileWhich
      Filechdir
      HTMLParser
      HTMLTree
      HTTPCacheTransparent
      HTTPCookies
      HTTPMessage
      HTTPRequestAsCGI
      HTTPResponseEncoding
      IOStringy
      JSON
      JSONXS
      LWP
      LWPJSONTiny
      LWPProtocolhttps
      LWPUserAgent
      LWPUserAgentDetermined
      LinguaPreferred
      ListMoreUtils
      ListMoreUtils
      LogTraceMessages
      PerlIOgzip
      SOAPLite
      TermProgressBar
      TermReadKey
      TimeDate
      TimeDuration
      TimePiece
      URI
      URIEncode
      URIEscapeXS
      UnicodeString
      XMLDOM
      XMLLibXML
      XMLLibXSLT
      XMLParser
      XMLTreePP
      XMLTwig
      XMLWriter
    ];

  pkg = perlPackages.buildPerlPackage rec {
    pname = "xmltv";
    version = "1.3.0";

    src = fetchFromGitHub {
      owner = "XMLTV";
      repo = "xmltv";
      rev = "v${version}";
      sha256 = "sha256-FtLjIVK6VYi/qTepIjOO7cmi6Wfb5+n25zOHa//ZZGE=";
    };

    propagatedBuildInputs = [ sqlite ] ++ (perlDeps perlPackages);

    doCheck = false;

    makeMakerFlags = [
      "-default"
      "NO_PACKLIST=1"
      "NO_PERLLOCAL=1"
      "PREFIX=$$out/"
    ];

    meta = with lib; {
      changelog = "https://github.com/XMLTV/xmltv/blob/v${version}/Changes";
      description = "The XMLTV project provides a suite of software to gather television listings, process listings data, and help organize your TV viewing";
      homepage = "http://www.xmltv.org/";
      license = licenses.gpl2;
      platforms = platforms.unix;
    };
  };
in
pkg
