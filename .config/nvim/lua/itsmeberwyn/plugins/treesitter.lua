return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      "windwp/nvim-ts-autotag",
    },
    config = function()
      local treesitter = require("nvim-treesitter.configs")
      treesitter.setup({
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = { "markdown" },
        },

        indent = { enable = true },

        autotag = {
          enable = true,
        },

        ensure_installed = {
          "javascript", "typescript", "lua",
          "jsdoc", "bash", "go", "python", "php",
          "html", "tsx"
        },

        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },

      })
    end
  }
}
