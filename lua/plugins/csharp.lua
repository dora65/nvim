-- ─── C# / .NET — LSP + Syntax ────────────────────────────────────────────────
-- csharp_ls: LSP ligero basado en Roslyn (alternativa moderna a OmniSharp)
-- Treesitter c_sharp: syntax highlighting, folds, text objects
--
-- Navegacion LSP (ya provista por LazyVim + goto-preview):
--   gd   → Go to Definition (salta a la clase, metodo, interface)
--   gi   → Go to Implementation (interface → clase que la implementa)
--   gr   → Go to References (todos los usos de un simbolo)
--   K    → Hover (documentacion, signature)
--   gpd  → Preview Definition (float window)
--   gpi  → Preview Implementation
--   gpr  → Preview References
--   <C-LeftMouse> → Ctrl+Click: Go to Definition (ver keymaps.lua)
-- ──────────────────────────────────────────────────────────────────────────────

return {
  -- 1. Treesitter: parser para syntax highlighting (merge automático de LazyVim)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "c_sharp" },
    },
  },

  -- 2. Mason: instalar automáticamente el servidor de Roslyn (csharp_ls)
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "csharp-language-server" },
    },
  },

  -- 3. LSP: csharp_ls (soporta SDK-style .csproj por defecto y es muy rápido)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        csharp_ls = {},
      },
    },
  },
}
