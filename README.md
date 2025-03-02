# nix-notes-shell-scripting

My Nix notes on writing shell scripts with built-in dependency management and
using neovim/tree-sitter.

## nix flake

### quick demo on how to get started

Create a nix flake from default template:

```text
$ nix flake init

$ git add flake.nix

$ nix flake lock

$ git add flake.lock

$ nix show flake
git+file:///home/vpayno/git_vpayno/nix-notes-shell-scripting
└───packages
    └───x86_64-linux
        ├───default: package 'hello-2.12.1'
        └───hello: package 'hello-2.12.1'

$ git commit -m 'nix: init flake'
```

Switch to multi-system flake:

```text
$ nvim flake.nix

$ git diff flake.nix
--- a/flake.nix
+++ b/flake.nix
@@ -1,16 +1,26 @@
 {
-  description = "A very basic flake";
+  description = "A multi-system flake";

   inputs = {
     nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
+
+    flake-utils. url = "github:numtide/flake-utils";
   };

   outputs = {
-    self,
     nixpkgs,
-  }: {
-    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
+    flake-utils,
+    ...
+  }:
+    flake-utils.lib.eachDefaultSystem (
+      system: let
+        pkgs = nixpkgs.legacyPackages.${system};
+      in {
+        packages = rec {
+          hello = pkgs.hello;

-    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;
-  };
+          default = hello;
+        };
+      }
+    );
 }

$ nix flake lock

$ nix flake show
git+file:///home/vpayno/git_vpayno/nix-notes-shell-scripting
└───packages
    ├───aarch64-darwin
    │   ├───default omitted (use '--all-systems' to show)
    │   └───hello omitted (use '--all-systems' to show)
    ├───aarch64-linux
    │   ├───default omitted (use '--all-systems' to show)
    │   └───hello omitted (use '--all-systems' to show)
    ├───x86_64-darwin
    │   ├───default omitted (use '--all-systems' to show)
    │   └───hello omitted (use '--all-systems' to show)
    └───x86_64-linux
        ├───default: package 'hello-2.12.1'
        └───hello: package 'hello-2.12.1'

$ git add ./flake.*

$ git commit -m 'nix: convert flake to multi-system'
```

Add a developer shell:

```text
$ nvim README.md

$ git diff
--- a/flake.nix
+++ b/flake.nix
@@ -15,12 +15,43 @@
     flake-utils.lib.eachDefaultSystem (
       system: let
         pkgs = nixpkgs.legacyPackages.${system};
-      in {
+
+        commonPkgs = with pkgs; [
+          bashInteractive
+          coreutils
+          moreutils
+          git
+          glow
+          runme
+        ];
+
+        darwinOnlyBuildInputs =
+          if pkgs.stdenv.isDarwin
+          then
+            with pkgs; [
+              darwin.apple_sdk.frameworks.Security
+            ]
+          else [];
+      in rec {
         packages = rec {
           hello = pkgs.hello;

           default = hello;
         };
+
+        devShells = {
+          default = pkgs.mkShell {
+            packages = commonPkgs ++ [packages.hello];
+
+            buildInputs = darwinOnlyBuildInputs;
+
+            GREETING = "Starting nix develop shell...";
+
+            shellHook = ''
+              ${pkgs.lib.getExe pkgs.cowsay} "$GREETING"
+            '';
+          };
+        };
       }
     );
 }

$ nix flake show
git+file:///home/vpayno/git_vpayno/nix-notes-shell-scripting
├───devShells
│   ├───aarch64-darwin
│   │   └───default omitted (use '--all-systems' to show)
│   ├───aarch64-linux
│   │   └───default omitted (use '--all-systems' to show)
│   ├───x86_64-darwin
│   │   └───default omitted (use '--all-systems' to show)
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
└───packages
    ├───aarch64-darwin
    │   ├───default omitted (use '--all-systems' to show)
    │   └───hello omitted (use '--all-systems' to show)
    ├───aarch64-linux
    │   ├───default omitted (use '--all-systems' to show)
    │   └───hello omitted (use '--all-systems' to show)
    ├───x86_64-darwin
    │   ├───default omitted (use '--all-systems' to show)
    │   └───hello omitted (use '--all-systems' to show)
    └───x86_64-linux
        ├───default: package 'hello-2.12.1'
        └───hello: package 'hello-2.12.1'

$ nix develop

$ which bash git glow runme hello
/nix/store/4k90qpzh1a4sldhnf7cxwkm9c0agq4fp-bash-interactive-5.2p37/bin/bash
/nix/store/nj1na0qwqhpd128vr71p70hz9jyhnz5x-git-2.48.1/bin/git
/nix/store/93d5xc37cmxkdlf6sb7kgrlv0wjhp5rq-glow-2.1.0/bin/glow
/nix/store/2kgwfvz90l5csn6gqkix3xinqvmgfmar-runme-3.8.3/bin/runme
/nix/store/3l4vg72nydxvif4l149z415l188xp2v2-hello-2.12.1/bin/hello

$ git add flake.nix

$ git commit -m 'nix: add developer shell'
```
