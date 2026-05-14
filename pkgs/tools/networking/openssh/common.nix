{ pname
, version
, extraDesc ? ""
, src
, extraPatches ? []
, extraNativeBuildInputs ? []
, extraConfigureFlags ? []
, extraMeta ? {}
}:

{ lib, stdenv
# This *is* correct, though unusual. as a way of getting krb5-config from the
# package without splicing See: https://github.com/NixOS/nixpkgs/pull/107606
, pkgs
, fetchurl
, fetchpatch
, autoreconfHook
, zlib
, openssl
, libedit
, ldns
, pkg-config
, pam
, libredirect
, etcDir ? null
, withKerberos ? true
, withLdns ? true
, krb5
, libfido2
, libxcrypt
, hostname
, nixosTests
, withSecurityKey ? !stdenv.hostPlatform.isStatic
, withFIDO ? stdenv.hostPlatform.isUnix && !stdenv.hostPlatform.isMusl && withSecurityKey
, withPAM ? stdenv.hostPlatform.isLinux
  # Attempts to mlock the entire sshd process on startup to prevent swapping.
  # Currently disabled when PAM support is enabled due to crashes
  # See https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1103418
, withLinuxMemlock ? (stdenv.hostPlatform.isLinux && !withPAM)
, dsaKeysSupport ? false
, linkOpenssl ? true
, isNixos ? stdenv.hostPlatform.isLinux
}:

# FIDO support requires SK support
assert withFIDO -> withSecurityKey;

stdenv.mkDerivation (finalAttrs: {
  inherit pname version src;

  patches = [
    ./locale_archive.patch

    # See discussion in https://github.com/NixOS/nixpkgs/pull/16966
    ./dont_create_privsep_path.patch
  ]
  ++ lib.optionals (lib.versionOlder finalAttrs.version "10.3") [
    # See discussion in https://github.com/NixOS/nixpkgs/issues/466049 and
    # https://gitlab.archlinux.org/archlinux/packaging/packages/openssh/-/issues/23
    (fetchpatch {
      name = "pkcs11-fetchkey-error-to-debug.patch";
      url = "https://github.com/openssh/openssh-portable/commit/607f337637f2077b34a9f6f96fc24237255fe175.patch";
      hunks = [ "2-" ];
      hash = "sha256-rdvKL6/rwrdhGKlcmdy6fxVgJgaaRsmngX0KkShXAhQ=";
    })
    (fetchpatch {
      name = "pkcs11-fix-pinentry.patch";
      url = "https://github.com/openssh/openssh-portable/commit/434ba7684054c0637ce8f2486aaacafe65d9b8aa.patch";
      # only applies to Makefile.in (which doesn't have a date header) so no hunks= needed
      hash = "sha256-3JQ3IJurngXclORrfC2Bx7xvmGA6w2nIh+eZ0zd0bLY=";
    })

    # See discussion in https://github.com/NixOS/nixpkgs/issues/453782 and
    # https://github.com/openssh/openssh-portable/pull/602
    (fetchpatch {
      name = "pkcs11-tests-allow-module-path.patch";
      url = "https://github.com/openssh/openssh-portable/commit/5e7c3f33b2693b668ecfbac84b85f2c0c84410c2.patch";
      hunks = [ "2-" ];
      hash = "sha256-mGpRGXurg8K9Wp8qoojG5MQ+3sZW2XKy2z0RDXLHaEc=";
    })
    (fetchpatch {
      name = "ssh-agent-tests-increase-timeout.patch";
      url = "https://github.com/openssh/openssh-portable/commit/1fdc3c61194819c16063dc430eeb84b81bf42dcf.patch";
      hunks = [ "2-" ];
      hash = "sha256-b9YCOav32kY5VEvIG3W1fyD87HaQxof6Zwq9Oo+/Lac=";
    })
  ]
  ++ extraPatches;

  postPatch =
    # On Hydra this makes installation fail (sometimes?),
    # and nix store doesn't allow such fancy permission bits anyway.
    ''
      substituteInPlace Makefile.in --replace '$(INSTALL) -m 4711' '$(INSTALL) -m 0711'
    '';

  strictDeps = true;
  nativeBuildInputs = [ autoreconfHook pkg-config ]
    # This is not the same as the krb5 from the inputs! pkgs.krb5 is
    # needed here to access krb5-config in order to cross compile. See:
    # https://github.com/NixOS/nixpkgs/pull/107606
    ++ lib.optional withKerberos pkgs.krb5
    ++ extraNativeBuildInputs;
  buildInputs = [ zlib libedit ]
    ++ [ (if linkOpenssl then openssl else libxcrypt) ]
    ++ lib.optional withFIDO libfido2
    ++ lib.optional withKerberos krb5
    ++ lib.optional withLdns ldns
    ++ lib.optional withPAM pam;

  preConfigure = ''
    # Setting LD causes `configure' and `make' to disagree about which linker
    # to use: `configure' wants `gcc', but `make' wants `ld'.
    unset LD
  '';

  env = lib.optionalAttrs isNixos {
    # openssh calls passwd to allow the user to reset an expired password, but nixos
    # doesn't ship it at /usr/bin/passwd.
    PATH_PASSWD_PROG = "/run/wrappers/bin/passwd";
  };

  # I set --disable-strip because later we strip anyway. And it fails to strip
  # properly when cross building.
  configureFlags = [
    "--sbindir=\${out}/bin"
    "--localstatedir=/var"
    "--with-pid-dir=/run"
    "--with-mantype=doc"
    "--with-libedit=yes"
    "--disable-strip"
    (lib.withFeature withPAM "pam")
    (lib.enableFeature dsaKeysSupport "dsa-keys")
  ] ++ lib.optional (etcDir != null) "--sysconfdir=${etcDir}"
    ++ lib.optional (!withSecurityKey) "--disable-security-key"
    ++ lib.optional withFIDO "--with-security-key-builtin=yes"
    ++ lib.optional withKerberos (assert krb5 != null; "--with-kerberos5=${lib.getDev krb5}")
    ++ lib.optional stdenv.isDarwin "--disable-libutil"
    ++ lib.optional (!linkOpenssl) "--without-openssl"
    ++ lib.optional withLdns "--with-ldns"
    ++ lib.optional withLinuxMemlock "--with-linux-memlock-onfault"
    ++ extraConfigureFlags;

  ${if stdenv.hostPlatform.isStatic then "NIX_LDFLAGS" else null} = [ "-laudit" ]
    ++ lib.optional withKerberos "-lkeyutils"
    ++ lib.optional withLdns "-lcrypto";

  buildFlags = [ "SSH_KEYSIGN=ssh-keysign" ];

  enableParallelBuilding = true;

  hardeningEnable = [ "pie" ];

  doCheck = true;
  enableParallelChecking = false;
  nativeCheckInputs = [ openssl ] ++ lib.optional (!stdenv.isDarwin) hostname;
  preCheck = lib.optionalString (stdenv.hostPlatform == stdenv.buildPlatform) ''
    # construct a dummy HOME
    export HOME=$(realpath ../dummy-home)
    mkdir -p ~/.ssh

    # construct a dummy /etc/passwd file for the sshd under test
    # to use to look up the connecting user
    DUMMY_PASSWD=$(realpath ../dummy-passwd)
    cat > $DUMMY_PASSWD <<EOF
    $(whoami)::$(id -u):$(id -g)::$HOME:$SHELL
    EOF

    # we need to NIX_REDIRECTS /etc/passwd both for processes
    # invoked directly and those invoked by the "remote" session
    cat > ~/.ssh/environment.base <<EOF
    NIX_REDIRECTS=/etc/passwd=$DUMMY_PASSWD
    LD_PRELOAD=${libredirect}/lib/libredirect.so
    EOF

    # use an ssh environment file to ensure environment is set
    # up appropriately for build environment even when no shell
    # is invoked by the ssh session. otherwise the PATH will
    # only contain default unix paths like /bin which we don't
    # have in our build environment
    cat - regress/test-exec.sh > regress/test-exec.sh.new <<EOF
    cp $HOME/.ssh/environment.base $HOME/.ssh/environment
    echo "PATH=\$PATH" >> $HOME/.ssh/environment
    EOF
    mv regress/test-exec.sh.new regress/test-exec.sh

    # explicitly enable the PermitUserEnvironment feature
    substituteInPlace regress/test-exec.sh \
      --replace \
        'cat << EOF > $OBJ/sshd_config' \
        $'cat << EOF > $OBJ/sshd_config\n\tPermitUserEnvironment yes'

    # some tests want to use files under /bin as example files
    for f in regress/sftp-cmds.sh regress/forwarding.sh; do
      substituteInPlace $f --replace '/bin' "$(dirname $(type -p ls))"
    done

    # set up NIX_REDIRECTS for direct invocations
    set -a; source ~/.ssh/environment.base; set +a
  '';
  # integration tests hard to get working on darwin with its shaky
  # sandbox
  # t-exec tests fail on musl
  checkTarget = lib.optional (!stdenv.isDarwin && !stdenv.hostPlatform.isMusl) "t-exec"
    # other tests are less demanding of the environment
    ++ [ "unit" "file-tests" "interop-tests" ];

  postInstall = ''
    # Install ssh-copy-id, it's very useful.
    cp contrib/ssh-copy-id $out/bin/
    chmod +x $out/bin/ssh-copy-id
    cp contrib/ssh-copy-id.1 $out/share/man/man1/
  '';

  installTargets = [ "install-nokeys" ];
  installFlags = [
    "sysconfdir=\${out}/etc/ssh"
  ];

  doInstallCheck = true;
  installCheckPhase = ''
    for binary in ssh sshd; do
      $out/bin/$binary -V 2>&1 | grep -P "$(printf '^OpenSSH_\\Q%s\\E,' "$version")"
    done
  '';

  passthru.tests = {
    borgbackup-integration = nixosTests.borgbackup;
    openssh = nixosTests.openssh;
  };

  meta = with lib; {
    description = "An implementation of the SSH protocol${extraDesc}";
    homepage = "https://www.openssh.com/";
    changelog = "https://www.openssh.com/releasenotes.html";
    license = licenses.bsd2;
    platforms = platforms.unix ++ platforms.windows;
    maintainers = (extraMeta.maintainers or []) ++ (with maintainers; [ eelco aneeshusa ]);
    mainProgram = "ssh";
  } // extraMeta;
})
