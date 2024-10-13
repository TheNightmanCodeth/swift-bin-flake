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
      nmc = import thenightmancodeth { system = "aarch64-linux"; };
      filename = "swift-6.0.1-RELEASE-debian12-aarch64.tar.gz";
      swift-derivation = { swift-src, system }: 
        with import nixpkgs { inherit system; };  
        stdenv.mkDerivation {
          name = "swift";
          version = "6.0.1";
          src = swift-src;

          #autoPatchelfIgnoreMissingDeps = [];
          #dontAutoPatchelf = true;
          runtimeDependencies = [
            nmc.ncurses
          ];

          nativeBuildInputs = [
            autoPatchelfHook
            python311
            libedit
            nmc.ncurses
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
            nmc.ncurses
            pkg-config
          ];

          postFixup = ''
            patchelf --replace-needed libedit.so.2 libedit.so.0.0.74 $out/usr/lib/liblldb.so.17.0.0
            patchelf --replace-needed libedit.so.2 libedit.so.0.0.74 $out/usr/bin/lldb-server
          '';

          unpackPhase = ''
            cp -r ${swift-src}/usr usr
          '';

          #patchPhase = ''
          #  autoPatchelf usr/bin/swift-driver
          #'';

          installPhase = ''
            echo "THE GAME: `ls ${swift-src}`"
            mkdir -p $out
            cp -r usr $out
          '';
        };
    in
    {
      defaultPackage.aarch64-linux = swift-derivation {
        swift-src = swift-bin-aarch64;
        system = "aarch64-linux";
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
