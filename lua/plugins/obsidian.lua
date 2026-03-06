return {
  "epwalsh/obsidian.nvim", -- Repositorio correcto
  version = "*",
dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>oc", "<cmd>ObsidianCheck<CR>", desc = "Check Checkbox" },
    { "<leader>ot", "<cmd>ObsidianTemplate<CR>", desc = "Insert Template" },
    { "<leader>oo", "<cmd>ObsidianOpen<CR>", desc = "Open in App" },
    { "<leader>ob", "<cmd>ObsidianBacklinks<CR>", desc = "Show Backlinks" },
    { "<leader>ol", "<cmd>ObsidianLinks<CR>", desc = "Show Links" },
    { "<leader>on", "<cmd>ObsidianNew<CR>", desc = "Create New Note" },
    { "<leader>os", "<cmd>ObsidianSearch<CR>", desc = "Search" },
    { "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>", desc = "Quick Switch" },
    { "<leader>od", "<cmd>ObsidianToday<CR>", desc = "Open Today Note" },
  },
  opts = { -- Usar opts para garantizar la inicialización automática
    workspaces = {
      {
        name = "JaedenNotes", -- Name of the workspace
        path = vim.fn.expand("~/Documents/Obsidian/JaedenNotes"), -- Path to the notes directory
      },
    },
    completion = {
      nvim_cmp = false,
      blink = true,
    },
    picker = {
      name = "snacks.pick",
    },
    new_notes_location = "current_dir",
    wiki_link_func = function(opts)
      if opts.id == nil then
        return string.format("[[%s]]", opts.label)
      elseif opts.label ~= opts.id then
        return string.format("[[%s|%s]]", opts.id, opts.label)
      else
        return string.format("[[%s]]", opts.id)
      end
    end,
    mappings = {
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      ["<leader>oh"] = { 
        action = function()
          return require("obsidian").util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
      ["<cr>"] = {
        action = function()
          return require("obsidian").util.smart_action()
        end,
        opts = { buffer = true, expr = true },
      },
    },
    -- Settings for templates
    templates = {
      subdir = "templates", -- Subdirectorio para templates
      date_format = "%Y-%m-%d-%a", -- Date format for templates
      time_format = "%H:%M", -- Time format for templates
    },
  },
  event = {
    "BufReadPre *.md",
    "BufNewFile *.md",
  },
  cmd = { "ObsidianSearch", "ObsidianNew", "ObsidianToday" },
}

