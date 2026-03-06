-- vim-be-good — ejercicios y juegos para mejorar habilidades Vim
-- Herramienta de entrenamiento, no producción → cmd-lazy (no carga en startup)
-- Activar con :VimBeGood

return {
  {
    "ThePrimeagen/vim-be-good",
    cmd = "VimBeGood",
    keys = {
      { "<leader>uv", "<cmd>VimBeGood<cr>", desc = "Vim Be Good (training)" },
    },
  },
}
