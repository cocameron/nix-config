{ pkgs, ... }:
{
  programs.nixvim = {
    enable = true;

    # Colorscheme
    colorschemes.everforest = {
      enable = true;
      settings = {
        background = "hard";
        disable_italic_comment = true;
      };
    };

    # Global options
    globals = {
      mapleader = " ";
      maplocalleader = " ";
      have_nerd_font = false;
    };

    opts = {
      # Line numbers
      number = true;

      # Mouse mode
      mouse = "a";

      # Don't show mode
      showmode = false;

      # Sync clipboard
      clipboard = "unnamedplus";

      # Break indent
      breakindent = true;

      # Save undo history
      undofile = true;

      # Case-insensitive searching
      ignorecase = true;
      smartcase = true;

      # Keep signcolumn on
      signcolumn = "yes";

      # Decrease update time
      updatetime = 250;

      # Decrease mapped sequence wait time
      timeoutlen = 300;

      # Configure splits
      splitright = true;
      splitbelow = true;

      # Whitespace characters
      list = true;
      listchars = "tab:» ,trail:·,nbsp:␣";

      # Preview substitutions
      inccommand = "split";

      # Show cursor line
      cursorline = true;

      # Scroll offset
      scrolloff = 10;

      # Confirm before closing unsaved
      confirm = true;
    };

    # Keymaps
    keymaps = [
      # Clear search highlights
      {
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR>";
        mode = "n";
      }

      # Diagnostic quickfix list
      {
        key = "<leader>q";
        action.__raw = "vim.diagnostic.setloclist";
        options.desc = "Open diagnostic [Q]uickfix list";
        mode = "n";
      }

      # Exit terminal mode
      {
        key = "<Esc><Esc>";
        action = "<C-\\><C-n>";
        options.desc = "Exit terminal mode";
        mode = "t";
      }

      # Window navigation
      {
        key = "<C-h>";
        action = "<C-w><C-h>";
        options.desc = "Move focus to the left window";
        mode = "n";
      }
      {
        key = "<C-l>";
        action = "<C-w><C-l>";
        options.desc = "Move focus to the right window";
        mode = "n";
      }
      {
        key = "<C-j>";
        action = "<C-w><C-j>";
        options.desc = "Move focus to the lower window";
        mode = "n";
      }
      {
        key = "<C-k>";
        action = "<C-w><C-k>";
        options.desc = "Move focus to the upper window";
        mode = "n";
      }
    ];

    # Autocommands
    autoCmd = [
      # Highlight on yank
      {
        event = [ "TextYankPost" ];
        desc = "Highlight when yanking (copying) text";
        callback.__raw = ''
          function()
            vim.hl.on_yank()
          end
        '';
      }
    ];

    # Plugins
    plugins = {
      # Detect tabstop and shiftwidth automatically
      guess-indent.enable = true;

      # Git signs
      gitsigns = {
        enable = true;
        settings = {
          signs = {
            add.text = "+";
            change.text = "~";
            delete.text = "_";
            topdelete.text = "‾";
            changedelete.text = "~";
          };
        };
      };

      # Which-key
      which-key = {
        enable = true;
        settings = {
          delay = 0;
          spec = [
            { __unkeyed-1 = "<leader>s"; group = "[S]earch"; }
            { __unkeyed-1 = "<leader>t"; group = "[T]oggle"; }
            { __unkeyed-1 = "<leader>h"; group = "Git [H]unk"; mode = [ "n" "v" ]; }
          ];
        };
      };

      # Telescope
      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
          ui-select.enable = true;
        };
        keymaps = {
          "<leader>sh" = {
            action = "help_tags";
            options.desc = "[S]earch [H]elp";
          };
          "<leader>sk" = {
            action = "keymaps";
            options.desc = "[S]earch [K]eymaps";
          };
          "<leader>sf" = {
            action = "find_files";
            options.desc = "[S]earch [F]iles";
          };
          "<leader>ss" = {
            action = "builtin";
            options.desc = "[S]earch [S]elect Telescope";
          };
          "<leader>sw" = {
            action = "grep_string";
            options.desc = "[S]earch current [W]ord";
          };
          "<leader>sg" = {
            action = "live_grep";
            options.desc = "[S]earch by [G]rep";
          };
          "<leader>sd" = {
            action = "diagnostics";
            options.desc = "[S]earch [D]iagnostics";
          };
          "<leader>sr" = {
            action = "resume";
            options.desc = "[S]earch [R]esume";
          };
          "<leader>s." = {
            action = "oldfiles";
            options.desc = "[S]earch Recent Files";
          };
          "<leader><leader>" = {
            action = "buffers";
            options.desc = "[ ] Find existing buffers";
          };
        };
      };

      # LSP
      lsp = {
        enable = true;
        servers = {
          lua-ls = {
            enable = true;
            settings.Lua = {
              completion.callSnippet = "Replace";
            };
          };
          gopls = {
            enable = true;
          };
        };
        keymaps = {
          diagnostic = {
            "<leader>q" = {
              action = "setloclist";
              desc = "Open diagnostic [Q]uickfix list";
            };
          };
          lspBuf = {
            "grn" = {
              action = "rename";
              desc = "LSP: [R]e[n]ame";
            };
            "gra" = {
              action = "code_action";
              desc = "LSP: [G]oto Code [A]ction";
            };
            "grD" = {
              action = "declaration";
              desc = "LSP: [G]oto [D]eclaration";
            };
          };
          extra = [
            {
              key = "grd";
              action.__raw = "require('telescope.builtin').lsp_definitions";
              options.desc = "LSP: [G]oto [D]efinition";
            }
            {
              key = "grr";
              action.__raw = "require('telescope.builtin').lsp_references";
              options.desc = "LSP: [G]oto [R]eferences";
            }
            {
              key = "gri";
              action.__raw = "require('telescope.builtin').lsp_implementations";
              options.desc = "LSP: [G]oto [I]mplementation";
            }
            {
              key = "grt";
              action.__raw = "require('telescope.builtin').lsp_type_definitions";
              options.desc = "LSP: [G]oto [T]ype Definition";
            }
            {
              key = "gO";
              action.__raw = "require('telescope.builtin').lsp_document_symbols";
              options.desc = "LSP: Open Document Symbols";
            }
            {
              key = "gW";
              action.__raw = "require('telescope.builtin').lsp_dynamic_workspace_symbols";
              options.desc = "LSP: Open Workspace Symbols";
            }
          ];
        };
      };

      # Fidget for LSP progress
      fidget.enable = true;

      # Lazydev for Lua development
      lsp-lines.enable = false;

      # Autoformat
      conform-nvim = {
        enable = true;
        settings = {
          notify_on_error = false;
          format_on_save = {
            timeout_ms = 500;
            lsp_format = "fallback";
          };
          formatters_by_ft = {
            lua = [ "stylua" ];
            go = [ "goimports" "gofmt" ];
          };
        };
      };

      # Autocompletion
      blink-cmp = {
        enable = true;
        settings = {
          keymap = {
            preset = "default";
          };
          appearance = {
            nerd_font_variant = "mono";
          };
          completion = {
            documentation = {
              auto_show = false;
              auto_show_delay_ms = 500;
            };
          };
          sources = {
            default = [ "lsp" "path" "snippets" ];
          };
          signature = {
            enabled = true;
          };
        };
      };

      # Snippets
      luasnip.enable = true;

      # Todo comments
      todo-comments = {
        enable = true;
        settings = {
          signs = false;
        };
      };

      # Mini.nvim modules
      mini = {
        enable = true;
        modules = {
          ai = {
            n_lines = 500;
          };
          surround = { };
          statusline = {
            use_icons = false;
          };
        };
      };

      # Treesitter
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          indent.disable = [ "ruby" ];
          highlight.additional_vim_regex_highlighting = [ "ruby" ];
        };
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          c
          diff
          html
          lua
          luadoc
          markdown
          markdown_inline
          query
          vim
          vimdoc
        ];
      };
    };

    # Extra packages needed for plugins
    extraPackages = with pkgs; [
      # Formatters
      stylua
      gotools # includes goimports

      # LSP servers
      lua-language-server
      gopls

      # Telescope dependencies
      ripgrep
      fd
    ];
  };
}
