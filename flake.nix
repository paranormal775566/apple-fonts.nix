{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils/abfb11bd1aec8ced1c9bb9adfe68018230f4fb3c";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    sf-pro = {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
      flake = false;
    };

    sf-mono = {
      url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, sf-pro, sf-mono }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      unpackPhase = pkgName: ''
        undmg $src
        7z x '${pkgName}'
        7z x 'Payload~'
      '';
      commonInstall = ''
        mkdir -p $out/share/fonts
        mkdir -p $out/share/fonts/opentype
        mkdir -p $out/share/fonts/truetype
      '';
      commonBuildInputs = with pkgs; [ undmg p7zip ];
      makeAppleFont = (name: pkgName: src: pkgs.stdenv.mkDerivation {
        inherit name src;

        unpackPhase = unpackPhase pkgName;

        buildInputs = commonBuildInputs;
        setSourceRoot = "sourceRoot=`pwd`";

        installPhase = commonInstall + ''
          find -name \*.otf -exec mv {} $out/share/fonts/opentype/ \;
          find -name \*.ttf -exec mv {} $out/share/fonts/truetype/ \;
        '';
      });
      makeNerdAppleFont = (name: pkgName: src: pkgs.stdenv.mkDerivation {
        inherit name src;

        unpackPhase = unpackPhase pkgName;

        buildInputs = with pkgs; commonBuildInputs ++ [ parallel nerd-font-patcher ];
        setSourceRoot = "sourceRoot=`pwd`";

        buildPhase = ''
          find -name \*.ttf -o -name \*.otf -print0 | parallel -j $NIX_BUILD_CORES -0 nerd-font-patcher -c {}
        '';

        installPhase = commonInstall + ''
          find -name \*.otf -maxdepth 1 -exec mv {} $out/share/fonts/opentype/ \;
          find -name \*.ttf -maxdepth 1 -exec mv {} $out/share/fonts/truetype/ \;
        '';
      });
    in rec {
      packages = {
        sf-pro = makeAppleFont "sf-pro" "SF Pro Fonts.pkg" sf-pro;
        sf-pro-nerd = makeNerdAppleFont "sf-pro-nerd" "SF Pro Fonts.pkg" sf-pro;

        sf-mono = makeAppleFont "sf-mono" "SF Mono Fonts.pkg" sf-mono;
        sf-mono-nerd = makeNerdAppleFont "sf-mono-nerd" "SF Mono Fonts.pkg" sf-mono;
      };
    }
  );
}
