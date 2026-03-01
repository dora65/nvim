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
        winblend = 0,
        highlights = {
          border = "FloatBorder",
          background = "NormalFloat",
        },
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)
      -- Auto-ocultar terminal flotante al entrar a CUALQUIER otra ventana
      -- WinEnter es más fiable que WinLeave: el nuevo contexto ya está estabilizado
      vim.api.nvim_create_autocmd("WinEnter", {
        group = vim.api.nvim_create_augroup("toggleterm_autohide", { clear = true }),
        callback = function()
          if vim.bo.filetype == "toggleterm" then return end  -- entramos al propio float, no hacer nada
          local ok, tt = pcall(require, "toggleterm.terminal")
          if not ok then return end
          for _, term in pairs(tt.get_all()) do
            if term.direction == "float" then
              term:close()
            end
          end
        end,
      })
    end
  }
}