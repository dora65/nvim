-- nvim-tmux-navigation: DESACTIVADO
-- Razón: entorno Windows + WezTerm no usa tmux.
-- tmux es un multiplexor de terminales Linux/macOS; WezTerm tiene su propio sistema de panes/tabs.
-- La navegación <C-h/j/k/l> entre splits está configurada directamente en keymaps.lua.
-- Si en algún momento se adopta WSL + tmux, re-activar aquí.

return {
  { "alexghergh/nvim-tmux-navigation", enabled = false },
}
