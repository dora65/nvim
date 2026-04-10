return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = {"ToggleTerm", "TermExec"},  -- Agrega esto para cargar el plugin cuando se usen estos comandos
    keys = {
      { "<leader>tf", "<cmd>lua require('toggleterm').toggle(1, nil, nil, 'float')<CR>", desc = "Terminal flotante" },
      { "<leader>th", "<cmd>lua require('toggleterm').toggle(2, 10, nil, 'horizontal')<CR>", desc = "Terminal horizontal" },
      { "<leader>tv", "<cmd>lua require('toggleterm').toggle(3, nil, 80, 'vertical')<CR>", desc = "Terminal vertical" },
    },
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
      end,
      -- <C-\> reservado para Claude Code, toggleterm usa <leader>t*
      open_mapping = false,
      hide_numbers = true,
      shade_terminals = false,  -- false: deja que winblend+NormalFloat controlen el bg
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "rounded",
        width = function()
          return math.floor(vim.o.columns * 0.88)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.85)
        end,
        winblend = 12,  -- glassmorphism unificado: sync con noice/snacks/ufo (12)
        highlights = {
          border = "FloatBorder",      -- Coordina con colorscheme.lua: surface2 sobre mantle
          background = "NormalFloat",  -- Coordina con colorscheme.lua: mantle #1a1a1c
        },
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)
      -- Auto-close eliminado: el WinEnter era demasiado agresivo y cerraba el float
      -- al abrir cualquier picker/mini.files/Claude, creando cascadas inesperadas.
      -- El toggle manual con <leader>tf/th/tv es suficiente. Esc en modo normal cierra.
    end
  }
}