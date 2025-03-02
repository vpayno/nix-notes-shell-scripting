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

$ exit

$ git add flake.nix

$ git commit -m 'nix: add developer shell'
```

## sayhello script

Simple script that depends on `bash` and `cowsay`.

```text
$ nvim flake.nix

$ git diff
--- a/flake.nix
+++ b/flake.nix
@@ -32,16 +32,20 @@
               darwin.apple_sdk.frameworks.Security
             ]
           else [];
+
+        scriptSayhello = pkgs.writeShellScriptBin "sayhello" ''
+          ${pkgs.lib.getExe pkgs.cowsay} "saying hello..."
+        '';
       in rec {
         packages = rec {
-          hello = pkgs.hello;
+          sayhello = scriptSayhello;

-          default = hello;
+          default = sayhello;
         };

         devShells = {
           default = pkgs.mkShell {
-            packages = commonPkgs ++ [packages.hello];
+            packages = commonPkgs ++ [packages.sayhello];

             buildInputs = darwinOnlyBuildInputs;

$ git add flake.nix

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
    │   └───sayhello omitted (use '--all-systems' to show)
    ├───aarch64-linux
    │   ├───default omitted (use '--all-systems' to show)
    │   └───sayhello omitted (use '--all-systems' to show)
    ├───x86_64-darwin
    │   ├───default omitted (use '--all-systems' to show)
    │   └───sayhello omitted (use '--all-systems' to show)
    └───x86_64-linux
        ├───default: package 'sayhello'
        └───sayhello: package 'sayhello'

$ git commit -m 'nix: add sayhello script as a package output and a devShell dependency'

$ nix build .#sayhello

$ tree ./result
./result
└── bin
    └── sayhello

2 directories, 1 file

$ cat ./result/bin/sayhello
#!/nix/store/11ciq72n4fdv8rw6wgjgasfv4mjs1jrw-bash-5.2p37/bin/bash
/nix/store/whb3cxdphwxjlvh57c6rf8p3rjxjlsi8-cowsay-3.8.4/bin/cowsay "saying hello..."

$ nix develop

$ which bash git glow runme sayhello
/nix/store/4k90qpzh1a4sldhnf7cxwkm9c0agq4fp-bash-interactive-5.2p37/bin/bash
/nix/store/nj1na0qwqhpd128vr71p70hz9jyhnz5x-git-2.48.1/bin/git
/nix/store/93d5xc37cmxkdlf6sb7kgrlv0wjhp5rq-glow-2.1.0/bin/glow
/nix/store/2kgwfvz90l5csn6gqkix3xinqvmgfmar-runme-3.8.3/bin/runme
/nix/store/p30na4vk378hzv24xz225hh6vr3k6l3i-sayhello/bin/sayhello

$ cat /nix/store/p30na4vk378hzv24xz225hh6vr3k6l3i-sayhello/bin/sayhello
#!/nix/store/11ciq72n4fdv8rw6wgjgasfv4mjs1jrw-bash-5.2p37/bin/bash
/nix/store/whb3cxdphwxjlvh57c6rf8p3rjxjlsi8-cowsay-3.8.4/bin/cowsay "saying hello..."

$ sayhello
saying hello...

$ exit

$ nix run
 _________________
< saying hello... >
 -----------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||

$ nix run .#sayhello
 _________________
< saying hello... >
 -----------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

Adding package metadata:

```text
$ nvim flake.nix

$ git diff
--- a/flake.nix
+++ b/flake.nix
@@ -36,9 +36,34 @@
         scriptSayhello = pkgs.writeShellScriptBin "sayhello" ''
           ${pkgs.lib.getExe pkgs.cowsay} "saying hello..."
         '';
+
+        metadata = {
+          meta = {
+            homepage = "https://github.com/vpayno/nix-notes-shell-scripting";
+            description = "Bash script that says hello";
+            platforms = pkgs.lib.platforms.linux;
+            license = with pkgs.lib.licenses; [mit];
+            # maintainers = with pkgs.lib.maintainers; [vpayno];
+            maintainers = [
+              {
+                email = "vpayno@users.noreply.github.com";
+                github = "vpayno";
+                githubId = 3181575;
+                name = "Victor Payno";
+              }
+            ];
+            mainProgram = "sayhello";
+            available = true;
+            broken = false;
+            insecure = false;
+            outputsToInstall = ["out"];
+            unfree = false;
+            unsupported = false;
+          };
+        };
       in rec {
         packages = rec {
-          sayhello = scriptSayhello;
+          sayhello = scriptSayhello // metadata;

           default = sayhello;
         };

$ git add flake.nix

$ git commit -m 'nix: add package metadata'
```

Show metadata:

```text
$ nix repl . <<< ':p packages.x86_64-linux.default.meta'
Nix 2.25.3
Type :? for help.
Loading installable 'git+file:///home/vpayno/git_vpayno/nix-notes-shell-scripting#'...
Added 2 variables.
{
  available = true;
  broken = false;
  description = "Bash script that says hello";
  homepage = "https://github.com/vpayno/nix-notes-shell-scripting";
  insecure = false;
  license = [
    {
      deprecated = false;
      free = true;
      fullName = "MIT License";
      redistributable = true;
      shortName = "mit";
      spdxId = "MIT";
      url = "https://spdx.org/licenses/MIT.html";
    }
  ];
  mainProgram = "sayhello";
  maintainers = [
    {
      email = "vpayno@users.noreply.github.com";
      github = "vpayno";
      githubId = 3181575;
      name = "Victor Payno";
    }
  ];
  outputsToInstall = [ "out" ];
  platforms = [
    "aarch64-linux"
    "armv5tel-linux"
    "armv6l-linux"
    "armv7a-linux"
    "armv7l-linux"
    "i686-linux"
    "loongarch64-linux"
    "m68k-linux"
    "microblaze-linux"
    "microblazeel-linux"
    "mips-linux"
    "mips64-linux"
    "mips64el-linux"
    "mipsel-linux"
    "powerpc64-linux"
    "powerpc64le-linux"
    "riscv32-linux"
    "riscv64-linux"
    "s390-linux"
    "s390x-linux"
    "x86_64-linux"
  ];
  unfree = false;
  unsupported = false;
}
```

Make it an app (a `nix run` target). Adding a `default` and `hello` targets.

```text
$ vim flake.nix

$ git diff
--- a/flake.nix
+++ b/flake.nix
@@ -68,6 +68,15 @@
           default = sayhello;
         };

+        apps = rec {
+          default = {
+            type = "app";
+            program = "${pkgs.lib.getExe packages.default}";
+            meta = metadata.meta;
+          };
+          hello = default;
+        };
+
         devShells = {
           default = pkgs.mkShell {
             packages = commonPkgs ++ [packages.sayhello];

$ nix flake show
git+file:///home/vpayno/git_vpayno/nix-notes-shell-scripting
├───apps
│   ├───aarch64-darwin
│   │   ├───default: app: Bash script that says hello
│   │   └───hello: app: Bash script that says hello
│   ├───aarch64-linux
│   │   ├───default: app: Bash script that says hello
│   │   └───hello: app: Bash script that says hello
│   ├───x86_64-darwin
│   │   ├───default: app: Bash script that says hello
│   │   └───hello: app: Bash script that says hello
│   └───x86_64-linux
│       ├───default: app: Bash script that says hello
│       └───hello: app: Bash script that says hello
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
    │   └───sayhello omitted (use '--all-systems' to show)
    ├───aarch64-linux
    │   ├───default omitted (use '--all-systems' to show)
    │   └───sayhello omitted (use '--all-systems' to show)
    ├───x86_64-darwin
    │   ├───default omitted (use '--all-systems' to show)
    │   └───sayhello omitted (use '--all-systems' to show)
    └───x86_64-linux
        ├───default: package 'sayhello'
        └───sayhello: package 'sayhello'

$ git add flake.nix

$ git commit -m 'nix: add default and hello apps'

$ nix run
saying hello...

$ nix run .#hello
saying hello...
```
