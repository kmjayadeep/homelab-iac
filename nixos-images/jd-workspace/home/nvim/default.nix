{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # TODO: Move to https://github.com/nix-community/nixvim

  programs.neovim = let
    toLua = str: "lua << EOF\n${str}\nEOF\n";
    toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
  in {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraPackages = with pkgs; [
      gopls
      wl-clipboard
      beancount-language-server
    ];

    plugins = with pkgs.vimPlugins; [
      # File manager on the left
      {
        plugin = neo-tree-nvim;
        config = toLuaFile ./plugin/neotree.lua;
      }
      nvim-web-devicons # Icons for file manager

      # LSP
      {
        plugin = nvim-lspconfig;
        config = toLuaFile ./plugin/lsp.lua;
      }

      # Autocomplete
      {
        plugin = nvim-cmp;
        config = toLuaFile ./plugin/cmp.lua;
      }
      cmp-nvim-lsp # LSP integration for cmp
      cmp_luasnip # luasnip integration for cmp
      luasnip # Snippet engine for nvim
      friendly-snippets # Snippets for a lot of languages

      # Theme
      # More catppuccin flavors in https://github.com/catppuccin/nvim/
      {
        plugin = catppuccin-nvim;
        # config = "colorscheme catppuccin";
      }
      {
        plugin = gruvbox-nvim;
        config = "colorscheme gruvbox";
      }

      # File opener, git files, fuzzy search etc
      {
        plugin = telescope-nvim;
        config = toLuaFile ./plugin/telescope.lua;
      }
      telescope-fzf-native-nvim # Required for telescope to search files

      # Status line
      {
        plugin = lualine-nvim;
        config = toLua "require(\"lualine\").setup()";
      }

      nerdcommenter
      vim-gitgutter # Show git diff +- on the left

      # For auto closing ( { etc
      {
        plugin = autoclose-nvim;
        config = toLua "require(\"autoclose\").setup()";
      }

      # For select/delete/change around { ( tags etc
      {
        plugin = nvim-surround;
        config = toLua "require(\"nvim-surround\").setup()";
      }

      # Better syntax highlighting
      {
        plugin = nvim-treesitter.withPlugins (p: [
          p.tree-sitter-nix
          p.tree-sitter-vim
          p.tree-sitter-bash
          p.tree-sitter-lua
          p.tree-sitter-json
          p.tree-sitter-go
          p.tree-sitter-beancount
          p.tree-sitter-terraform
        ]);
        config = toLuaFile ./plugin/treesitter.lua;
      }

      # Make indentation more visible
      {
        plugin = indent-blankline-nvim;
        config = toLuaFile ./plugin/ibl.lua;
      }

      # Nix language support in nvim
      vim-nix
    ];

    extraLuaConfig = ''
      ${builtins.readFile ./options.lua}
      ${builtins.readFile ./binds.lua}
    '';
  };
}
