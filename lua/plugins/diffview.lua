-- diffview.nvim: visualización profesional de diffs y merge conflicts
-- Standard absoluto para git diff visual. Complementa lazygit (no reemplaza):
--   lg = lazygit (commits, branches, stash, operaciones interactivas)
--   <leader>gd = diffview (diffs visuales, historial, merge conflicts 3-way)

return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>",         desc = "Diff view (staged+unstaged)" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File git history" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>",   desc = "Repo git history" },
    { "<leader>gx", "<cmd>DiffviewClose<cr>",         desc = "Close diff view" },
  },
  opts = {
    enhanced_diff_hl = true,  -- highlights más expresivos para cambios inline
    view = {
      default = {
        layout = "diff2_horizontal",
      },
      merge_tool = {
        layout = "diff3_horizontal",   -- 3-way merge: base | theirs | ours
        disable_diagnostics = true,    -- sin ruido LSP al resolver conflictos
      },
    },
    file_panel = {
      listing_style = "tree",
      tree_options  = { flatten_dirs = true, folder_statuses = "only_folded" },
    },
  },
}
