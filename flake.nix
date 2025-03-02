# flake.nix
{
  description = "Flake with scripts";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        commonPkgs = with pkgs; [
          bashInteractive
          coreutils
          moreutils
          git
          glow
          runme
        ];

        darwinOnlyBuildInputs =
          if pkgs.stdenv.isDarwin
          then
            with pkgs; [
              darwin.apple_sdk.frameworks.Security
            ]
          else [];

        scriptSayhello = pkgs.writeShellScriptBin "sayhello" ''
          echo "saying hello..."
        '';
      in rec {
        packages = rec {
          sayhello = scriptSayhello;

          default = sayhello;
        };

        devShells = {
          default = pkgs.mkShell {
            packages = commonPkgs ++ [packages.sayhello];

            buildInputs = darwinOnlyBuildInputs;

            GREETING = "Starting nix develop shell...";

            shellHook = ''
              ${pkgs.lib.getExe pkgs.cowsay} "$GREETING"
            '';
          };
        };
      }
    );
}
