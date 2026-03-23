-- LSP: solo overrides sobre la config de LazyVim (no duplicar mason/lspconfig)
return {
  -- Mason: solo opciones de UI (LazyVim ya gestiona instalacion y servidores)
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "󰄜",
          package_pending = "󰑓",
          package_uninstalled = "󰅚",
        },
      },
    },
  },

  -- LSP: overrides específicos
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = true },

      -- ─── Diagnósticos: override quirúrgico sobre LazyVim defaults ─────────
      -- LazyVim ya configura: update_in_insert=false, severity_sort, signs con icons, prefix="●"
      -- Aquí extendemos SOLO lo que LazyVim no tiene:
      diagnostics = {
        virtual_text = {
          -- nvim 0.11+: alinea diagnósticos al margen derecho del buffer (VS Code / JetBrains style)
          -- Elimina colisión visual con código corto y mejora legibilidad en líneas largas
          virt_text_pos = "right_align",
          spacing       = 4,
          source        = "if_many",   -- muestra qué LSP reporta cuando hay varios
          prefix        = "●",
        },
        -- Float para <leader>cd / vim.diagnostic.open_float()
        -- winborder="rounded" (options.lua) ya cubre el border nativo; esto lo fuerza explícitamente
        float = {
          border = "rounded",
          source = "if_many",          -- fuente del LSP visible en el float
          max_width = 80,              -- no más de 80 cols (mensajes largos quedan legibles)
        },
      },

      servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
              completion = { callSnippet = "Replace" },
            },
          },
        },
      },
    },
  },
}
