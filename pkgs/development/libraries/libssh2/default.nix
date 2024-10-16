{
  lib,
  stdenv,
  fetchurl,
  openssl,
  zlib,
  windows,
}:

stdenv.mkDerivation rec {
  pname = "libssh2";
  version = "1.11.1";

  src = fetchurl {
    url = "https://www.libssh2.org/download/libssh2-${version}.tar.gz";
    hash = "sha256-2ex2y+NNuY7sNTn+LImdJrDIN8s+tGalaw8QnKv2WPc=";
  };

  outputs = [
    "out"
    "dev"
    "devdoc"
  ];

  propagatedBuildInputs = [ openssl ]; # see Libs: in libssh2.pc
  buildInputs = [ zlib ] ++ lib.optional stdenv.hostPlatform.isMinGW windows.mingw_w64;

  meta = with lib; {
    description = "A client-side C library implementing the SSH2 protocol";
    homepage = "https://www.libssh2.org";
    platforms = platforms.all;
    license = with licenses; [
      bsd3
      libssh2
    ];
    maintainers = with maintainers; [ SuperSandro2000 ];
  };
}
