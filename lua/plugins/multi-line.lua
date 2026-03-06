-- Multi-cursor editing — mg979/vim-visual-multi
-- Reemplaza terryma/vim-multiple-cursors (deprecado por el autor en 2019 explícitamente)
-- Docs: https://github.com/mg979/vim-visual-multi/wiki
-- <C-n>: selecciona palabra bajo cursor (siguiente ocurrencia)
-- <C-Down/Up>: cursor vertical
-- Tab: alterna entre modo cursor y modo extendido

return {
  {
    "mg979/vim-visual-multi",
    event = "VeryLazy",
    init = function()
      -- Deshabilitar mappings por defecto que conflictúan
      vim.g.VM_default_mappings = 0
      vim.g.VM_maps = {
        ["Find Under"]         = "<C-n>",
        ["Find Subword Under"] = "<C-n>",
        ["Select All"]         = "<leader>va",
        ["Start Regex Search"] = "<C-n>/",
        ["Visual All"]         = "<leader>vA",
      }
    end,
  },
}
