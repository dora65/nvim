return {
  "saghen/blink.cmp",
  lazy = true,
  opts = {
    -- ─── Fuentes por contexto ────────────────────────────────────────────────
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },

    -- ─── Cmdline Completion (v0.8+ syntax) ──────────────────────────────────
    cmdline = {
      enabled = true,
      -- Keymaps exclusivos para cmdline (separados de insert mode)
      keymap = {
        preset = "default",
        ["<Down>"] = { "select_next", "fallback" },
        ["<Up>"]   = { "select_prev", "fallback" },
        ["<CR>"]   = { "accept", "fallback" },
      },
      sources = function()
        local type = vim.fn.getcmdtype()
        -- Search (/) usa buffer words
        if type == '/' or type == '?' then return { 'buffer' } end
        -- Comandos (:) usa cmdline native
        if type == ':' or type == '@' then return { 'cmdline' } end
        return {}
      end,
      completion = {
        menu = { auto_show = true },
        ghost_text = { enabled = false },
      },
    },

    -- ─── Keymaps (Insert mode) ───────────────────────────────────────────────
    keymap = {
      preset = "default",
      ["<Down>"] = { "select_next", "fallback" },
      ["<Up>"]   = { "select_prev", "fallback" },
      ["<CR>"]   = { "accept", "fallback" },
      ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-e>"]  = { "hide", "fallback" },
    },

    -- ─── Completion UI ───────────────────────────────────────────────────────
    completion = {
      menu = {
        border = "rounded",
        draw = {
          columns = {
            { "label", "label_description", gap = 1 },
            { "kind_icon", "kind", gap = 1 },
          },
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 300,
        window = { border = "rounded" },
      },
      ghost_text = { enabled = true },
    },
  },
}
