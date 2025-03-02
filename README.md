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
