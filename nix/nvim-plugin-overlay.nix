{ self }: final: prev: let
  luaPackages-override = luaself: luaprev: {
    zeta-nvim = luaself.callPackage ({
      buildLuarocksPackage,
      fetchurl,
      fetchzip,
      luaOlder,
    }:
      buildLuarocksPackage {
        pname = "zeta.nvim";
        version = "scm-1";
        knownRockspec = "${self}/zeta.nvim-scm-1.rockspec";
        src = self;

        disabled = luaOlder "5.1";
        propagatedBuildInputs = with luaself; [
          plenary-nvim
        ];
      }) {};
  };
  lua5_1 = prev.lua5_1.override {
    packageOverrides = luaPackages-override;
  };
  lua51Packages = prev.lua51Packages // final.lua5_1.pkgs;

  zeta-nvim-dev = final.neovimUtils.buildNeovimPlugin {
    luaAttr = final.lua51Packages.zeta-nvim;
  };
in {
  inherit
    lua5_1
    lua51Packages
    zeta-nvim-dev
    ;
  vimPlugins = prev.vimPlugins // {
    zeta-nvim = zeta-nvim-dev;
  };
  neovim-test-drive = let
    neovimConfig = final.neovimUtils.makeNeovimConfig {
      viAlias = false;
      vimAlias = false;
      plugins = [
        final.vimPlugins.zeta-nvim
      ];
    };
  in (final.wrapNeovimUnstable final.neovim-nightly (neovimConfig // {
    luaRcContent = /* lua */ ''
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
        end,
      })
    '';
  }))
    .overrideAttrs (oa: {
      nativeBuildInputs = oa.nativeBuildInputs ++ [
        final.luajit.pkgs.wrapLua
      ];
    });
}
