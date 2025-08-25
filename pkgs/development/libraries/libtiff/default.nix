{
  lib,
  stdenv,
  fetchFromGitLab,
  fetchpatch,
  nix-update-script,

  autoreconfHook,
  pkg-config,
  sphinx,

  lerc,
  libdeflate,
  libjpeg,
  xz,
  zlib,

  # for passthru.tests
  libgeotiff,
  python3Packages,
  imagemagick,
  graphicsmagick,
  gdal,
  openimageio,
  freeimage,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libtiff";
  version = "4.7.0";

  src = fetchFromGitLab {
    owner = "libtiff";
    repo = "libtiff";
    rev = "v${finalAttrs.version}";
    hash = "sha256-SuK9/a6OUAumEe1kz1itFJGKxJzbmHkBVLMnyXhIwmQ=";
  };

  patches = [
    # FreeImage needs this patch
    ./headers.patch
    # libc++abi 11 has an `#include <version>`, this picks up files name
    # `version` in the project's include paths
    ./rename-version.patch
    (fetchpatch {
      name = "CVE-2024-13978_1.patch";
      url = "https://gitlab.com/libtiff/libtiff/-/commit/7be20ccaab97455f192de0ac561ceda7cd9e12d1.patch";
      hash = "sha256-cpsQyIvyP6LkGeQTlLX73iNd1AcPkvZ6Xqfns7G3JBc=";
    })
    (fetchpatch {
      name = "CVE-2024-13978_2.patch";
      url = "https://gitlab.com/libtiff/libtiff/-/commit/2ebfffb0e8836bfb1cd7d85c059cd285c59761a4.patch";
      hash = "sha256-cZlLTeB7/nvylf5SLzKF7g91aBERhZxpV5fmWEJVrX4=";
    })
    (fetchpatch {
      name = "CVE-2025-9165.patch";
      url = "https://gitlab.com/libtiff/libtiff/-/commit/ed141286a37f6e5ddafb5069347ff5d587e7a4e0.patch";
      hash = "sha256-DIsk8trbHMMTrj6jP5Ae8ciRjHV4CPHdWCN+VbeFnFo=";
    })
  ];

  postPatch = ''
    mv VERSION VERSION.txt
  '';

  outputs = [
    "bin"
    "dev"
    "dev_private"
    "out"
    "man"
    "doc"
  ];

  postFixup = ''
    moveToOutput include/tif_config.h $dev_private
    moveToOutput include/tif_dir.h $dev_private
    moveToOutput include/tif_hash_set.h $dev_private
    moveToOutput include/tiffiop.h $dev_private
  '';

  # If you want to change to a different build system, please make
  # sure cross-compilation works first!
  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    sphinx
  ];

  buildInputs = [
    lerc
  ];

  # TODO: opengl support (bogus configure detection)
  propagatedBuildInputs = [
    libdeflate
    libjpeg
    xz
    zlib
  ];

  enableParallelBuilding = true;

  doCheck = true;

  passthru = {
    tests = {
      inherit
        libgeotiff
        imagemagick
        graphicsmagick
        gdal
        openimageio
        freeimage
        ;
      inherit (python3Packages) pillow imread;
      pkg-config = testers.hasPkgConfigModules {
        package = finalAttrs.finalPackage;
      };
    };
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "Library and utilities for working with the TIFF image file format";
    homepage = "https://libtiff.gitlab.io/libtiff";
    changelog = "https://libtiff.gitlab.io/libtiff/releases/v${finalAttrs.version}.html";
    license = licenses.libtiff;
    platforms = platforms.unix ++ platforms.windows;
    pkgConfigModules = [ "libtiff-4" ];
    maintainers = teams.geospatial.members;
  };
})
