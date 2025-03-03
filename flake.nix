# flake.nix
{
  description = "Flake with greetings scripts";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

        commonPkgs = with pkgs; [
          bashInteractive
          coreutils
          moreutils
          git
          glow
          runme
        ];

        darwinOnlyBuildInputs =
          if pkgs.stdenv.isDarwin then
            with pkgs;
            [
              darwin.apple_sdk.frameworks.Security
            ]
          else
            [ ];

        scriptSayHello = pkgs.writeShellScriptBin "sayhello" ''
          ${pkgs.lib.getExe pkgs.cowsay} "saying hello..."
        '';

        scriptSayGoodbye = pkgs.writeShellScriptBin "saygoodbye" ''
          ${pkgs.lib.getExe pkgs.cowsay} "saying goodbye..."
        '';

        metadata = {
          meta = {
            homepage = "https://github.com/vpayno/nix-notes-shell-scripting";
            description = "Bash script that says a greeting";
            platforms = pkgs.lib.platforms.linux;
            license = with pkgs.lib.licenses; [ mit ];
            # maintainers = with pkgs.lib.maintainers; [vpayno];
            maintainers = [
              {
                email = "vpayno@users.noreply.github.com";
                github = "vpayno";
                githubId = 3181575;
                name = "Victor Payno";
              }
            ];
            mainProgram = "sayhello";
            available = true;
            broken = false;
            insecure = false;
            outputsToInstall = [ "out" ];
            unfree = false;
            unsupported = false;
          };
        };
      in
      rec {
        formatter = treefmtEval.config.build.wrapper;

        checks = {
          formatting = treefmtEval.config.build.check self;
        };

        packages = rec {
          sayhello = scriptSayHello // metadata;
          saygoodbye =
            scriptSayGoodbye
            // metadata
            // {
              meta = {
                mainProgram = "saygoodbye";
              };
            };

          default = sayhello;
        };

        apps = rec {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe packages.default}";
            meta = metadata.meta;
          };
          hello = default;

          goodbye = {
            type = "app";
            program = "${pkgs.lib.getExe packages.saygoodbye}";
            meta = metadata.meta;
          };
        };

        devShells = {
          default = pkgs.mkShell {
            packages =
              commonPkgs
              ++ (with packages; [
                sayhello
                saygoodbye
              ]);

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
