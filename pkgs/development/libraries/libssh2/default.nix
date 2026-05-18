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

  patches = [
    # fetchpatch cannot be used due to infinite recursion
    # https://github.com/libssh2/libssh2/pull/1858/changes/7f521e5fd96860a3f869e9f9c4bc8d149118f5b0
    ./CVE-2026-7598.patch
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
