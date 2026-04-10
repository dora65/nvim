return {
  -- ─── Noice: Consistency y Styling Total ──────────────────────────────────
  -- Noice ignora NormalFloat por defecto. Cada "view" tiene su propio bg/border.
  -- Hay que especificar los views EXPLICITAMENTE para someterlos al puente acromático.
  {
    "folke/noice.nvim",
    opts = {
      routes = {
        {
          filter = { event = "notify", find = "ECONNRESET" },
          opts   = { skip = true },
        },
        -- Silenciar deprecation harmless de dap.ext.vscode
        {
          filter = { event = "notify", find = "deprecated" },
          opts   = { skip = true },
        },
      },
      -- Views: Ajuste quirúrgico de cada tipo de flotante
      views = {
        cmdline_popup = {
          -- Posición: centrado alto (más ergonómico que bottom)
          position = { row = "30%", col = "50%" },
          size = { width = "auto", height = "auto" },
          border = {
            style = "rounded",
            padding = { 0, 0 },  -- densidad maxima: sin padding horizontal
          },
          -- Usar los highlights que inyectamos en colorscheme.lua
          win_options = {
            winhighlight = "Normal:NoiceCmdlinePopup,FloatBorder:NoiceCmdlinePopupBorder",
            winblend = 12,  -- glassmorphism unificado: 12 = 5% opaco sobre 95% acrylic (todos los floats)
          },
        },
        mini = {
          -- Notificaciones mini abajo a la derecha: sin borde, fondo mantle, fade temporal
          position = { row = -2, col = "100%" },
          size = { width = "auto", height = "auto" },
          border = { style = "none" },
          win_options = {
            winhighlight = "Normal:NoiceMini",
            winblend = 12,  -- sync: uniforme con resto de floats
          },
        },
      },
      -- Cmdline: Iconos visibles y elegantes (Sublime/Catppuccin style)
      cmdline = {
        format = {
          cmdline     = { icon = " " },   -- terminal icon
          search_down = { icon = " ⌄" },  -- search down
          search_up   = { icon = " ⌃" },  -- search up
          filter      = { icon = " " },   -- filter/bash
          lua         = { icon = "󰢱 " },   -- lua moon/logo
          help        = { icon = "󰋖 " },   -- help question
        },
      },
      -- CRITICO: Desactivar el popupmenu de Noice (nui backend).
      -- Si Noice mantiene control del popupmenu, blink.cmp no puede inyectar
      -- su propia UI ni sus keymaps — el usuario queda atrapado en el wildmenu.
      -- Con enabled=false: blink.cmp.cmdline source provee la lista con flechas.
      popupmenu = {
        enabled = false,   -- blink.cmp toma el control total del cmdline popup
      },
    },
  },


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
        width_focus = 28,    -- Columna activa: -2 chars sin perder rutas tipicas
        width_nofocus = 13,  -- Breadcrumb inactivo: -2 chars (solo icono+nombre corto)
        width_preview = 55,  -- Preview: -5 chars, aun amplio para visualizacion
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
