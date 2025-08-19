{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = [
          "x86_64-linux"
        ];
        imports = [
          inputs.haskell-flake.flakeModule
        ];

        perSystem =
          {
            pkgs,
            lib,
            system,
            ...
          }:
          {
            formatter = pkgs.nixfmt-rfc-style;

            haskellProjects.default = {
              devShell = {
                tools = hpkgs: {
                  inherit (pkgs) nixfmt-rfc-style;
                };
                mkShellArgs = {
                  nativeBuildInputs = with pkgs.llvmPackages; [
                    libllvm
                    libclang
                  ];
                  BINDGEN_EXTRA_CLANG_ARGS =
                    lib.readFile "${pkgs.clang}/nix-support/libc-cflags"
                    + lib.readFile "${pkgs.clang}/nix-support/cc-cflags";
                };
              };
              settings = {
                skew-list = {
                  check = false;
                  broken = false;
                };
                debruijn =
                  { super, ... }:
                  {
                    custom =
                      _:
                      super.callHackageDirect {
                        pkg = "debruijn";
                        ver = "0.3.1";
                        sha256 = "sha256-eSfxwu3CqtamsAzHAKJfEVqUd5J9ydjSMxyQUpnq9C8=";
                      } { };
                    jailbreak = true;
                  };
                clang = {
                  extraBuildDepends = with pkgs.llvmPackages; [
                    libllvm
                    libclang
                  ];
                };
                c-expr.check = false;
                hs-bindgen = {
                  check = false;
                };
              };
            };
          };
      }
    );
}
