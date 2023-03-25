{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        blink = with pkgs;
          # Taken with thanks from https://github.com/nix-community/nur-combined/blob/784d7cedd877d57cb06a3250f976dad733477f09/repos/sikmir/pkgs/misc/blink/default.nix
          stdenv.mkDerivation (finalAttrs: {
            pname = "blink";
            version = "2023-01-06";

            src = fetchFromGitHub {
              owner = "jart";
              repo = "blink";
              rev = "312fbb3a1bd868de5763a2ebe6a6a199ad7c164a";
              hash = "sha256-Yjpd8+R8QlH3L8IoVOX7xbANvc8vUwVhDmC7Vzyh+oM=";
            };

            postPatch = ''
              substituteInPlace third_party/cosmo/cosmo.mk --replace "curl" "#curl"
            '';

            postInstall = ''
              mkdir -p $out/bin
              install -Dm755 o//blink/{blink,blinkenlights} $out/bin
            '';

            meta = with lib; {
              description = "tiniest x86-64-linux emulator";
              inherit (finalAttrs.src.meta) homepage;
              license = licenses.isc;
              maintainers = [maintainers.sikmir];
              platforms = platforms.linux;
              skip.ci = true;
            };
          });
      asm = pkgs.writeScriptBin "asm" (builtins.readFile ./compile_asm.sh);
      in {
        devShell = pkgs.mkShell {
          packages = with pkgs; [nasm gdb blink asm];
        };
      }
    );
}
