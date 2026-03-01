-- ─── HTTP Client — kulala.nvim ────────────────────────────────────────────────
-- Formato .http 100% compatible con VSCode REST Client + IntelliJ
-- Soporta: HTTP/REST · gRPC · GraphQL · WebSocket · Streaming
-- Variables {{var}} y @var = val en el mismo .http (sin .env externo)
--
-- Atajos en archivos .http / .rest:
--   <CR>         → Enviar request bajo el cursor  (el más intuitivo)
--   <leader>Rs   → Ídem (kulala global_keymap)
--   <leader>Ra   → Enviar TODOS los requests del archivo
--   <leader>Ro   → Abrir/enfocar panel de respuesta
--   <leader>Rb   → Scratch .http temporal (desde cualquier buffer)
--   <leader>Re   → Cambiar entorno activo (.env / dev / prod / …)
--   <leader>Ru   → Gestión de autenticación (tokens, basic auth…)
--   <leader>Rf   → Buscar request en el archivo (picker)
--   <leader>Rp   → Copiar request actual como curl (portapapeles)
--   ]]  /  [[    → Saltar al siguiente / anterior bloque ###
--
-- En el panel de respuesta (buffer kulala):
--   B → Body · H → Headers · A → Todo · V → Verbose · S → Stats
--   [ / ] → Respuesta anterior / siguiente (historial)
--   <CR>  → Saltar al request de origen
--   ?     → Ayuda de atajos
-- ──────────────────────────────────────────────────────────────────────────────

return {
  -- Asegurar el parser treesitter HTTP (kulala lo registra en su setup,
  -- pero ensure_installed lo descarga en el primer arranque)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        table.insert(opts.ensure_installed, "http")
      end
    end,
  },

  {
    "mistweaverco/kulala.nvim",

    -- Carga lazy: solo al abrir un .http o .rest
    ft = { "http", "rest" },

    -- Keymaps globales declarados aquí para which-key / lazy hint
    keys = {
      { "<leader>Rb", function() require("kulala").scratchpad() end, desc = "HTTP Scratchpad" },
    },

    opts = {
      -- ── curl: viene integrado en Windows 10+ ──────────────────────────────
      curl_path = "curl",
      request_timeout = 30000, -- 30 s antes de timeout

      -- ── Variables: lee @var = val del propio .http (VSCode REST Client) ──
      default_env = "dev",
      vscode_rest_client_environmentvars = true,

      -- ── UI: split vertical (request izq · respuesta der) ─────────────────
      ui = {
        display_mode   = "split",
        split_direction = "vertical",
        default_view   = "body",       -- mostrar body al ejecutar
        winbar         = true,         -- tabs: Body / Headers / Stats…
        show_variable_info_text = "inline", -- muestra valor real de {{var}}
        show_icons     = "on_request", -- icono de estado junto al request
        disable_news_popup = true,     -- sin popups de noticias
      },

      -- ── LSP: completado + formato en .http files ──────────────────────────
      lsp = { enable = true },

      -- ── Keymaps: kulala gestiona buffer-local en .http automáticamente ────
      global_keymaps        = true,
      global_keymaps_prefix = "<leader>R",
    },

    config = function(_, opts)
      require("kulala").setup(opts)

      -- Atajos extra vim-nativos (complementan los <leader>R de kulala)
      local function setup_http_keys(buf)
        local K = require("kulala")
        local function map(key, fn, desc)
          vim.keymap.set("n", key, fn, { buffer = buf, desc = desc, silent = true })
        end

        -- <Enter>: el gesto más intuitivo — envía el request del cursor
        map("<CR>", function() K.run() end, "Send request")

        -- Navegación vim-nativa entre bloques ###
        map("]]", function() K.jump_next() end, "Next request block")
        map("[[", function() K.jump_prev() end, "Prev request block")
      end

      -- Keymaps + codelens refresh para todos los .http que se abran
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "http", "rest" },
        group   = vim.api.nvim_create_augroup("KulalaBufferKeys", { clear = true }),
        callback = function(ev)
          setup_http_keys(ev.buf)
          -- Forzar refresh de codelens al abrir: muestra "Send Request" encima de cada bloque
          vim.lsp.codelens.refresh()
        end,
      })

      -- Re-refrescar codelens al guardar y al volver de insert mode
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        pattern = { "*.http", "*.rest" },
        group   = vim.api.nvim_create_augroup("KulalaCodelens", { clear = true }),
        callback = function() vim.lsp.codelens.refresh() end,
      })

      -- Aplicar al buffer actual si ya es .http (apertura directa del plugin)
      local ft = vim.bo.filetype
      if ft == "http" or ft == "rest" then
        setup_http_keys(vim.api.nvim_get_current_buf())
      end
    end,
  },
}
