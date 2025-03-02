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
