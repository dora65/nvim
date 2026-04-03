# Neovim Config (LazyVim + Windows 11)

## Stack
LazyVim + Neovim 0.11+, lazy.nvim, WezTerm. Theme activo: `sublime` (Monokai ST3). Disponibles: catppuccin, kanagawa, sonokai.

## Estructura
`lua/config/` → options/keymaps/autocmds/lazy.lua | `lua/plugins/*.lua` → un archivo por dominio | `colors/sublime.lua` → entry point tema Sublime

## Reglas criticas
- Este proyecto usa TABS REALES (^I) en archivos Lua — respetar indentacion en cada edicion
