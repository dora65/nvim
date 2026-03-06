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
      shade_terminals = true,
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
        -- winblend omitido: mini.animate lo gestiona (open: 80→0, close: 0→80)
        -- Con winblend=0 explícito aquí se sobreescribe el estado inicial de la animación
        highlights = {
          border = "FloatBorder",
          background = "NormalFloat",
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