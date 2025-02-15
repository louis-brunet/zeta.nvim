{
  description = "zeta.nvim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    neorocks.url = "github:nvim-neorocks/neorocks";
    flake-parts.url = "github:hercules-ci/flake-parts";
    vimcats.url = "github:mrcjkb/vimcats";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    neorocks,
    flake-parts,
    ...
  }: let
    plugin-overlay = import ./nix/nvim-plugin-overlay.nix {
      inherit self;
    };
    test-overlay = import ./nix/test-overlay.nix {
      inherit self inputs;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem = {
        config,
        self',
        inputs',
        system,
        ...
      }: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            neorocks.overlays.default
            plugin-overlay
            test-overlay
          ];
        };
      in {
        packages = rec {
          default = nvim-plugin;
          nvim-plugin = pkgs.zeta-nvim-dev;
          inherit
            (pkgs)
            docgen
            neovim-test-drive
            ;
        };

        devShells.default = pkgs.mkShell {
          name = "zeta.nvim devShell";
          shellHook = ''
            export LUA_PATH="$(luarocks path --lr-path --lua-version 5.1 --local)"
            export LUA_CPATH="$(luarocks path --lr-cpath --lua-version 5.1 --local)"
          '';
          buildInputs = with pkgs; [
            sumneko-lua-language-server
            stylua
            docgen
            (pkgs.lua5_1.withPackages (ps: with ps; [luarocks luacheck]))
          ];
        };

        # TODO: use nix for testing when I choose my mind with test framework
        # zeta.nvim is UI-centric plugin, so using nlua might not enough
        #
        # checks = {
        #   inherit
        #     (pkgs)
        #     neovim-stable-test
        #     neovim-nightly-test
        #     ;
        # };
      };
    };
}
