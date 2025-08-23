return {
  -- Add fzf-lua with optional dependencies
  {
    'ibhagwan/fzf-lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' }, -- Optional for icons
    keys = {
      -- Keybindings for fzf-lua
      { '<leader>ff', function() require('fzf-lua').files() end, desc = 'Find Files' },
      { '<leader>fg', function() require('fzf-lua').live_grep() end, desc = 'Live Grep' },
      { '<leader>fb', function() require('fzf-lua').buffers() end, desc = 'Buffers' },
      { '<leader>fh', function() require('fzf-lua').help_tags() end, desc = 'Help Tags' },
      { '<leader>fd', function() require('fzf-lua').diagnostics_workspace() end, desc = 'Workspace Diagnostics' },
      { 'gd', function() require('fzf-lua').lsp_definitions() end, desc = 'LSP Definitions' },
    },
    config = function()
      require('fzf-lua').setup({
        winopts = {
          height = 0.85,
          width = 0.80,
          preview = {
            layout = 'flex',
            horizontal = 'right:60%',
            vertical = 'down:45%',
            scroll = {
              up = '<C-o>',   -- Customize to scroll up
              down = '<C-d>', -- Customize to scroll down
            },
          },
        },
        lsp = {
          enable = true,
        },
        files = {
          prompt = 'Files❯ ',
          cmd = 'fd --type f --hidden --follow --exclude .git',
          git_icons = true,
          file_icons = true,
          color_icons = true,
        },
        grep = {
          prompt = 'Rg❯ ',
          input_prompt = 'Grep For❯ ',
          rg_opts = '--hidden --column --line-number --no-heading ' ..
                    '--color=always --smart-case -g "!{.git,node_modules}/*"',
        },
        keymap = {
          builtin = {
            ['<F1>'] = 'toggle-help',
            ['<F2>'] = 'toggle-fullscreen',
            ['<C-u>'] = 'preview-page-up',
            ['<C-d>'] = 'preview-page-down'
          },
          fzf = {
            ['ctrl-q'] = 'select-all+accept',
            ['ctrl-c'] = 'abort',
          },
        },
        fzf_opts = {
          ['--layout'] = 'default',
          ['--info'] = 'inline',
        },
      })
    end,
  },
}
