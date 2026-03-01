-- LSP: solo overrides sobre la config de LazyVim (no duplicar mason/lspconfig)
return {
  -- Mason: solo opciones de UI (LazyVim ya gestiona instalacion y servidores)
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        border = "single",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },

  -- LSP: overrides específicos
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = true },
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
