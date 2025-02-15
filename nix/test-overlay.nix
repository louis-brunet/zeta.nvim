{
  self,
  inputs,
}: final: prev: let
  mkNeorocksTest = name: nvim:
    with final;
      neorocksTest {
        inherit name;
        pname = "zeta.nvim";
        src = self;
        neovim = nvim;
        luaPackages = ps:
          with ps; [
            nvim-nio
            plenary-nvim
            tree-sitter-lua
            tree-sitter-rust
          ];
        extraPackages = [];

        preCheck = ''
          # Neovim expects to be able to create log files, etc.
          export HOME=$(realpath .)
          export ZETA_NVIM_PLUGIN_DIR=${final.zeta-nvim-dev}
        '';
      };
  docgen = final.writeShellApplication {
    name = "docgen";
    runtimeInputs = [
      inputs.vimcats.packages.${final.system}.default
    ];
    text = ''
      mkdir -p doc
      echo "todo"
      # vimcats lua/zeta/init.lua > doc/zeta.txt
    '';
  };
in {
  neovim-stable-test = mkNeorocksTest "neovim-stable-test" final.neovim;
  neovim-nightly-test = mkNeorocksTest "neovim-nightly-test" final.neovim-nightly;
  inherit docgen;
}
