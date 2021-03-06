{ stdenv, fetchurl, perl, systemd, openssl, pam, bzip2, zlib, openldap
, inotify-tools, clucene_core_2, sqlite }:

stdenv.mkDerivation rec {
  name = "dovecot-2.2.19";

  buildInputs = [ perl openssl bzip2 zlib openldap clucene_core_2 sqlite ]
    ++ stdenv.lib.optionals (stdenv.isLinux) [ systemd pam inotify-tools ];

  src = fetchurl {
    url = "http://dovecot.org/releases/2.2/${name}.tar.gz";
    sha256 = "17sf5aancad4pg1vx1606k99389wg76blpqzmnmxlz4hklzix7km";
  };

  preConfigure = ''
    substituteInPlace src/config/settings-get.pl --replace \
      "/usr/bin/env perl" "${perl}/bin/perl"
  '';

  postInstall = stdenv.lib.optionalString stdenv.isDarwin ''
    install_name_tool -change libclucene-shared.1.dylib \
        ${clucene_core_2}/lib/libclucene-shared.1.dylib \
        $out/lib/dovecot/lib21_fts_lucene_plugin.so
    install_name_tool -change libclucene-core.1.dylib \
        ${clucene_core_2}/lib/libclucene-core.1.dylib \
        $out/lib/dovecot/lib21_fts_lucene_plugin.so
  '';

  patches = [
    # Make dovecot look for plugins in /var/lib/dovecot/modules
    # so we can symlink plugins from several packages there
    # The symlinking needs to be done in NixOS, as part of the
    # dovecot service start-up
    ./2.2.x-module_dir.patch
  ];

  configureFlags = [
    # It will hardcode this for /var/lib/dovecot.
    # http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=626211
    "--localstatedir=/var"
    "--with-ldap"
    "--with-lucene"
    "--with-ssl=openssl"
    "--with-sqlite"
    "--with-zlib"
    "--with-bzlib"
  ] ++ stdenv.lib.optionals (stdenv.isLinux) [
    "--with-systemdsystemunitdir=$(out)/etc/systemd/system"
  ];

  meta = {
    homepage = "http://dovecot.org/";
    description = "Open source IMAP and POP3 email server written with security primarily in mind";
    maintainers = with stdenv.lib.maintainers; [viric simons rickynils];
    hydraPlatforms = stdenv.lib.platforms.linux;
  };
}
