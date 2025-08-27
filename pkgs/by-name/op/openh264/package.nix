{
  lib,
  fetchFromGitHub,
  fetchpatch,
  gtest,
  meson,
  nasm,
  ninja,
  pkg-config,
  stdenv,
  windows,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "openh264";
  version = "2.4.1";

  src = fetchFromGitHub {
    owner = "cisco";
    repo = "openh264";
    rev = "v${finalAttrs.version}";
    hash = "sha256-ai7lcGcQQqpsLGSwHkSs7YAoEfGCIbxdClO6JpGA+MI=";
  };

  patches = [
    # https://github.com/cisco/openh264/security/advisories/GHSA-m99q-5j7x-7m9x
    (fetchpatch {
      name = "CVE-2025-27091";
      url = "https://github.com/cisco/openh264/commit/63db555e30986e3a5f07871368dc90ae78c27449.patch";
      hash = "sha256-rLoJO7QufE7LKykUfoWo/dKzqlu9cqLYM+hUhwtjEUY=";
    })
  ];

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    meson
    nasm
    ninja
    pkg-config
  ];

  buildInputs =
    [
      gtest
    ]
    ++ lib.optionals stdenv.hostPlatform.isWindows [
      windows.pthreads
    ];

  strictDeps = true;

  meta = {
    homepage = "https://www.openh264.org";
    description = "A codec library which supports H.264 encoding and decoding";
    changelog = "https://github.com/cisco/openh264/releases/tag/${finalAttrs.src.rev}";
    license = with lib.licenses; [ bsd2 ];
    maintainers = with lib.maintainers; [ AndersonTorres ];
    platforms = lib.platforms.unix ++ lib.platforms.windows;
  };
})
