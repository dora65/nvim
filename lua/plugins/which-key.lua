return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function(_, opts)
    local wk = require("which-key")

    -- ── Posición y dimensiones ────────────────────────────────────────────────
    -- row = math.huge  → centinela que ancla la ventana al FONDO del editor
    -- width = 0.99     → en which-key v3: valores < 1 son porcentajes
    --                    0.99 = 99% del ancho del terminal (layout horizontal completo)
    -- col = 0          → empieza desde la izquierda
    opts.win = vim.tbl_deep_extend("force", opts.win or {}, {
      row = math.huge,
      col = 0,
      width  = 0.99,   -- ← CLAVE: 99% de ancho = múltiples columnas horizontales
      border = "rounded",
      title  = true,
      title_pos = "center",
      no_overlap = false,
      padding = { 1, 2 },
    })

    -- ── Layout: columnas compactas para aprovechar el ancho ──────────────────
    -- width.min = 20: cada columna mínimo 20 chars
    -- spacing = 3: separación entre columnas
    -- Con 0.99 de ancho y columnas de 20+3, en una pantalla de 200 cols = ~7 columnas
    opts.layout = vim.tbl_deep_extend("force", opts.layout or {}, {
      width   = { min = 20 },
      spacing = 3,
    })

    opts.preset = "helix"
    opts.icons = vim.tbl_deep_extend("force", opts.icons or {}, {
      separator = "→",
      group = "+",
    })

    -- ── Grupos semánticos (etiquetas en el menú) ─────────────────────────────
    opts.spec = opts.spec or {}
    vim.list_extend(opts.spec, {
      { "<leader>N", group = "Obsidian Notes" },
      { "<leader>m", group = "Markdown" },
      { "<leader>g", group = "Git" },
      { "<leader>c", group = "Code/LSP" },
      { "<leader>b", group = "Buffers" },
      { "<leader>f", group = "Find" },
      { "<leader>s", group = "Search" },
      { "<leader>x", group = "Diagnostics" },
      { "<leader>u", group = "UI Toggle" },
      { "<leader>d", group = "Debug" },
      { "<leader>y", group = "Yank/Copy" },
      { "<leader>t", group = "Terminal" },
    })

    wk.setup(opts)
  end,
  keys = {
    {
      "<leader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "Buffer Keymaps",
    },
  },
}
