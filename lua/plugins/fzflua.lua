return {
  -- ── fzf-lua: dotfiles + gitignored por defecto ────────────────────────────
  -- --no-ignore-vcs: ignora .gitignore pero respeta .ignore/.fdignore/.rgignore
  -- --exclude .git: nunca entra en la carpeta .git (metadata interna del repo)
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      files = {
        fd_opts = "--color=never --type f --hidden --follow --no-ignore-vcs --exclude .git",
      },
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --no-ignore-vcs --glob '!.git'",
      },
    },
  },
  -- ── Snacks picker ────────────────────────────────────────────────────────
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          -- ignored = true: incluye archivos listados en .gitignore
          -- Snacks excluye .git/ internamente — no se indexan metadatos del repo
          files = { hidden = true, ignored = true },
          grep  = { hidden = true, ignored = true },
          smart = { hidden = true, ignored = true }, -- <leader><leader>
        },
      },
    },
    keys = {
      -- ── Buscar archivos ignorados por .gitignore ────────────────────────
      -- <leader>fi: find ignored (no conflicto con LazyVim)
      {
        "<leader>fi",
        function() require("snacks").picker.files({ hidden = true, ignored = true }) end,
        desc = "Find all files (incl. gitignored)",
      },
      -- Para grep en archivos ignorados: usa <leader>sg y luego <a-i> en el picker
      -- (toggle ignore dentro del picker, sin conflicto con <leader>si = Icons)

      -- <C-f> → searchbox.nvim (search.lua) | <C-h> → searchbox replace
      -- <leader>sf → grug-far para replace en archivo (más potente)

      -- ── Navegación entre buffers (equivalente Ctrl+Tab) ─────────────────
      -- <C-Tab>: buffers abiertos ordenados por uso reciente
      {
        "<C-Tab>",
        function() require("snacks").picker.buffers() end,
        desc = "Switch buffer (Ctrl+Tab)",
        mode = { "n", "t" },
      },
      -- Ciclo rápido sin picker: Alt+flechas
      {
        "<A-Right>",
        "<cmd>bnext<cr>",
        desc = "Next buffer",
      },
      {
        "<A-Left>",
        "<cmd>bprev<cr>",
        desc = "Prev buffer",
      },
    },
  },
}
