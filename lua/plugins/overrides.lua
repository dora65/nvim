return {
  -- ─── mini.files: explorador flotante premium ─────────────────────────────
  -- Reemplaza oil.nvim: misma filosofía (editar filesystem como buffer) pero
  -- con multi-columna estilo ranger y preview de archivos en tiempo real.
  -- Keymaps internos por defecto (dentro del panel):
  --   l / <CR> → abrir   h / - → subir directorio   g? → ayuda
  --   R         → sync    d → crear directorio  % → crear archivo
  {
    "nvim-mini/mini.files", -- LazyVim renombró el repo: usar nvim-mini/
    opts = {
      windows = {
        preview = true,      -- Vista previa del archivo al hacer hover (killer feature)
        width_focus = 30,    -- Columna activa
        width_nofocus = 15,  -- Columnas inactivas (breadcrumb)
        width_preview = 60,  -- Panel de preview
      },
      options = {
        use_as_default_explorer = false, -- neo-tree sigue manejando el sidebar
        permanent_delete = false,        -- Archivos eliminados van a papelera del OS
      },
    },
  },

  {
    "folke/trouble.nvim",
    opts = { use_diagnostic_signs = true },
  },
  {
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline",
    keys = { { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" } },
    config = true,
  },
}
