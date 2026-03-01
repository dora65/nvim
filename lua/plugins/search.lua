-- ── Búsqueda y Reemplazo ─────────────────────────────────────────────────────
--
-- SEARCH IN FILE (equivalente VSCode Ctrl+F):
--   <C-f>      → SearchBox flotante top-right, resalta TODOS los matches en tiempo real
--              → dentro del box: Tab/<S-Tab> o F3/<S-F3> para siguiente/anterior
--              → <C-f> o <Esc> cierra el box
--
-- REPLACE IN FILE (equivalente VSCode Ctrl+H):
--   <leader>sh → SearchBox replace simple (find → replace, aplica con Enter)
--   <leader>sH → SearchBox replace con confirmación por match (más seguro)
--   <leader>sR → Grug FAR en archivo actual (regex completo + preview visual)
--
-- REPLACE MULTI-FILE (equivalente VSCode Ctrl+Shift+H):
--   <leader>sr → Grug FAR en todo el proyecto (LazyVim default)
--
-- FLASH / JUMP (técnica nvim experta):
--   /texto  → flash labels (a,b,c…) sobre cada match → letra = salto directo
--   cgn     → cambiar primer match → . repite en siguiente (1 tecla por match)
--
-- SEARCH COUNTER:
--   n / N   → siguiente/anterior + contador [2/8] centrado (hlslens)
--   * / #   → buscar palabra bajo cursor
--   <leader>fs → rip-substitute: regex replace con preview en split

return {
  -- ── 0. Searchbox.nvim: panel flotante Ctrl+F (tipo VS Code) ─────────────
  -- <C-f>     → MatchAll: resalta todos los matches mientras escribís
  -- <leader>sh → Replace simple | <leader>sH → Replace con confirmación
  {
    "VonHeikemen/searchbox.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    keys = {
      -- Búsqueda: resalta todos los matches mientras escribís
      { "<C-f>", "<cmd>SearchBoxMatchAll clear_matches=true<cr>", mode = { "n", "v" }, desc = "Search in file" },
      -- Replace simple: find → replace todo de una vez
      { "<leader>sh", "<cmd>SearchBoxReplace<cr>", mode = { "n" }, desc = "Search & Replace" },
      -- Replace con confirmación: pregunta match por match (más seguro)
      { "<leader>sH", "<cmd>SearchBoxReplace confirm=menu<cr>", mode = { "n" }, desc = "Search & Replace (confirm each)" },
    },
    opts = {
      default_value = "",
      enable_cmdline_keymaps = false,
      hooks = {
        before_mount = function(_)
          local ok, colors = pcall(require, "catppuccin.palettes")
          if not ok then return end
          local C = colors.get_palette("mocha")
          vim.api.nvim_set_hl(0, "SearchBoxNormal",   { bg = C.mantle,   fg = C.text })
          vim.api.nvim_set_hl(0, "SearchBoxBorder",   { fg = C.mauve,    bg = C.mantle })
          vim.api.nvim_set_hl(0, "SearchBoxTitle",    { fg = C.mauve,    bg = C.mantle, bold = true })
          vim.api.nvim_set_hl(0, "SearchBoxShadow",   { fg = C.crust })
          vim.api.nvim_set_hl(0, "SearchBoxPrompt",   { fg = C.mauve,    bg = C.mantle, bold = true })
          vim.api.nvim_set_hl(0, "SearchBoxMatchAll", { bg = C.surface1, fg = C.text })
        end,
        after_mount = function(input)
          local close = function() input.input_props.on_close() end
          -- Cerrar el panel
          input:map("n", "<Esc>", close, { noremap = true })
          input:map("i", "<C-f>", close, { noremap = true })
          input:map("n", "<C-f>", close, { noremap = true })
          -- Tab / Shift+Tab → siguiente / anterior match (estilo VSCode)
          input:map("i", "<Tab>",   "<C-n>", { noremap = true })
          input:map("i", "<S-Tab>", "<C-p>", { noremap = true })
          -- F3 / Shift+F3 → siguiente / anterior match (estilo estándar de editores)
          input:map("i", "<F3>",   "<C-n>", { noremap = true })
          input:map("i", "<S-F3>", "<C-p>", { noremap = true })
        end,
      },
    },
  },

  -- ── 0b. Grug FAR: replace avanzado ───────────────────────────────────────
  -- <leader>sr  → reemplazar en TODO el proyecto (LazyVim default)
  -- <leader>sR  → reemplazar SOLO en el archivo actual (modo enfocado)
  -- Soporta regex, flags ripgrep, preview visual con diff, undo seguro
  {
    "MagicDuck/grug-far.nvim",
    opts = {
      headerMaxWidth = 80,
      -- Abrir en vsplit (como VSCode): no ocupa toda la pantalla
      windowCreationCommand = "vsplit",
    },
    keys = {
      -- <leader>sR: grug-far restringido al archivo actual
      {
        "<leader>sR",
        function()
          local grug = require("grug-far")
          grug.open({ prefills = { paths = vim.fn.expand("%") } })
        end,
        desc = "Replace in current file (Grug Far)",
      },
    },
  },

  -- ── 1. Flash.nvim: labels sobre matches durante / ────────────────────────
  {
    "folke/flash.nvim",
    opts = {
      search = { enabled = true },
      label = {
        uppercase = false,
        rainbow = { enabled = false }, -- colores manuales catppuccin abajo
        after = true,
        before = false,
        style = "overlay",
        min_length = 1,
        reuse = "lowercase",
      },
      highlight = {
        backdrop = true,   -- backdrop en modo s/S jump
        matches = true,
        priority = 5000,
      },
      modes = {
        search = {
          enabled = true,
          -- SIN backdrop en search: el cursor de la cmdline queda visible
          highlight = { backdrop = false },
          jump = { history = true, register = true, nohlsearch = true },
        },
        char = {
          enabled = true,
          jump_labels = true,
          label = { exclude = "hjkliardc" },
          keys = { "f", "F", "t", "T", ";", "," },
        },
      },
    },
    -- Colores catppuccin mocha: consistentes con el tema
    config = function(_, opts)
      require("flash").setup(opts)
      local function set_hl()
        -- Backdrop: oscurece sin matar el contexto
        vim.api.nvim_set_hl(0, "FlashBackdrop", { fg = "#585b70" })
        -- Label: mauve brillante sobre fondo oscuro → muy legible
        vim.api.nvim_set_hl(0, "FlashLabel",    { bg = "#cba6f7", fg = "#1e1e2e", bold = true })
        -- Match: todos los resultados en superficie resaltada
        vim.api.nvim_set_hl(0, "FlashMatch",    { bg = "#313244", fg = "#cdd6f4" })
        -- Current: verde para el match activo/seleccionado
        vim.api.nvim_set_hl(0, "FlashCurrent",  { bg = "#a6e3a1", fg = "#1e1e2e", bold = true })
      end
      set_hl()
      -- Reaplicar tras cambio de colorscheme
      vim.api.nvim_create_autocmd("ColorScheme", { pattern = "*", callback = set_hl })
    end,
  },

  -- ── 2. nvim-hlslens: contador [actual/total] al navegar con n/N ──────────
  {
    "kevinhwang91/nvim-hlslens",
    event = "BufReadPost",
    config = function()
      require("hlslens").setup({
        calm_down = true,
        nearest_only = true,
        nearest_float_when = "always",
      })

      local o = { noremap = true, silent = true }
      -- n/N + centra cursor automáticamente (zz)
      vim.keymap.set("n", "n", [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>zz]], o)
      vim.keymap.set("n", "N", [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>zz]], o)
      vim.keymap.set("n", "*",  [[*<Cmd>lua require('hlslens').start()<CR>]],  o)
      vim.keymap.set("n", "#",  [[#<Cmd>lua require('hlslens').start()<CR>]],  o)
      vim.keymap.set("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], o)
      vim.keymap.set("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], o)
      vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR><Esc>", o)
    end,
  },
}
