-- screenkey.nvim — visualiza teclas presionadas en pantalla
-- Uso: demostraciones, grabaciones de pantalla, tutoriales
-- NO cargar en startup (lazy=false anterior era incorrecto para uso en producción)
-- Activar con :Screenkey | Desactivar con :Screenkey (toggle)

return {
  {
    "NStefan002/screenkey.nvim",
    version = "*",
    cmd = "Screenkey",
    keys = {
      { "<leader>uK", "<cmd>Screenkey<cr>", desc = "Toggle Screenkey" },
    },
    opts = {
      win_opts = {
        row = vim.o.lines - vim.o.cmdheight - 1,
        col = vim.o.columns - 1,
        relative = "editor",
        anchor = "SE",
        width = 40,
        height = 3,
        border = "rounded",
      },
    },
  },
}
