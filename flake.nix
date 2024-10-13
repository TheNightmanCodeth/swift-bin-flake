{
  description = "Latest swift binary distribution from swift.org";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    thenightmancodeth.url = "github:TheNightmanCodeth/nixpkgs?ref=swift-bin";
    swift-bin-aarch64 = {
      url = "https://download.swift.org/swift-6.0.1-release/debian12-aarch64/swift-6.0.1-RELEASE/swift-6.0.1-RELEASE-debian12-aarch64.tar.gz";
      flake = false;
    };
    swift-bin-x86_64 = {
      url = "https://download.swift.org/swift-6.0.1-release/debian12/swift-6.0.1-RELEASE/swift-6.0.1-RELEASE-debian12.tar.gz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, thenightmancodeth, swift-bin-aarch64, swift-bin-x86_64, ... }:
    let
      callPackage = nmc.newScope self;

      # And then there's also a separate subtree for statically linked  modules.
      toStaticSubdir = nmc.lib.replaceStrings [ "/swift/" ] [ "/swift_static/" ];
      swiftStaticLibSubdir = toStaticSubdir swiftLibSubdir;
      swiftStaticModuleSubdir = toStaticSubdir swiftModuleSubdir;
      swiftLibSubdir = "lib/swift/${swiftOs}";
      swiftModuleSubdir = "lib/swift/${swiftOs}/${swiftArch}";
      swiftOs = "unknown-linux-gnu";
      swiftArch = "aarch64";
      nmc = import thenightmancodeth { system = "aarch64-linux"; };
      pkgs = import nixpkgs { system = "aarch64-linux"; };
      filename = "swift-6.0.1-RELEASE-debian12-aarch64.tar.gz";
      swift-derivation = { swift-src, system }: 
        with import nixpkgs { inherit system; };  
        stdenv.mkDerivation {
          inherit swiftArch swiftOs swiftModuleSubdir swiftLibSubdir swiftStaticLibSubdir swiftStaticModuleSubdir;
          name = "swift";
          version = "6.0.1";
          src = swift-src;

          outputs = [ "out" "lib" ];

          passthru = {
          _wrapperParams = {
            inherit bintools;
            default_cc_wrapper = clang; # Instead of `@out@` in the original.
            coreutils_bin = lib.getBin coreutils;
            gnugrep_bin = gnugrep;
            suffixSalt = lib.replaceStrings ["-" "."] ["_" "_"] targetPlatform.config;
            use_response_file_by_default = 1;
            swiftDriver = "";
            #libdispatch = "${host_libdispatch}/lib";
            # NOTE: @prog@ needs to be filled elsewhere.
          };
          };

          #autoPatchelfIgnoreMissingDeps = [];
          #dontAutoPatchelf = true;
          runtimeDependencies = [
            nmc.ncurses
            binutils
          ];

          nativeBuildInputs = [
            autoPatchelfHook
            python311
            libedit
            nmc.ncurses
            binutils
          ];

          buildInputs = [
            sqlite
            curl
            python311
            swig
            libxml2
            libuuid
            binutils
            gcc
            git
            libedit
            icu
            lldb
            nmc.ncurses
            pkg-config
          ];

          postFixup = ''
            echo "LIBBBB `ls $lib`"
            echo "OUTTTT `ls $out`"
            patchelf --replace-needed libedit.so.2 libedit.so.0.0.74 $lib/lib/liblldb.so.17.0.0
            patchelf --replace-needed libedit.so.2 libedit.so.0.0.74 $out/bin/lldb-server
          '';

          unpackPhase = ''
            cp -r ${swift-src}/usr out
          '';

          #patchPhase = ''
          #  autoPatchelf usr/bin/swift-driver
          #'';

          installPhase = ''
            echo "THE GAME: `ls ${swift-src}`"
            mkdir -p $out
            mkdir -p $lib
            cp -r out/bin $out
            cp -r out/lib $lib
            #mkdir -p $lib/lib
            mkdir -p $out/lib

            #cp -r out/lib/swift $lib/lib/swift
            #cp -r out/lib/clang $lib/lib/clang
            #cp out/lib/libswiftDemangle.* $lib/lib/

            ln -s $lib/lib/swift $out/lib/swift
            ln -s $lib/lib/lib* $out/lib/
          '';
        };
    in
    {
      defaultPackage.aarch64-linux = swift-derivation {
        swift-src = swift-bin-aarch64;
        system = "aarch64-linux";
      };

      packages.aarch64-linux.swift-wrapped = callPackage ./wrapper {
        stdenv = pkgs.stdenv;
        lib = pkgs.lib;
        swift = self.defaultPackage.aarch64-linux;
        swift-driver = false;
      };

      defaultPackage.x86_64-linux = swift-derivation {
        swift-src = swift-bin-x86_64;
        system = "x86_64-linux";
      };

      meta = with nixpkgs.lib; {
        homepage = "https://swift.org";
        description = "Binary release of swiftlang";
        platforms = platforms.linux;
      };
    };
}
