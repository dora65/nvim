# Neovim Config (LazyVim + Windows 11)

## Stack
- LazyVim framework on Neovim 0.9+
- Plugin manager: lazy.nvim
- Terminal: WezTerm
- Theme activo: `sublime` (Monokai ST3)
- Temas disponibles: catppuccin, kanagawa, sonokai

## Estructura
- `lua/config/` → options, keymaps, autocmds, lazy.lua
- `lua/plugins/*.lua` → un archivo por dominio funcional
- `colors/sublime.lua` → entry point tema Sublime

## Reglas críticas (errores probados)
- Archivos de plugin vacíos → lazy.nvim falla. Siempre `return {}`
- `VimEnter` para layout → usar `UiEnter` (más estable)
- neo-tree: `action = "show"` NO `"focus"` (mueve cursor)
- `pcall(require, "plugin")` siempre en top-level de keymaps
- LazyVim extras van en `lazy.lua` spec, no en plugin files
- Este proyecto usa TABS REALES (^I) en archivos Lua — respetar indentación

## Catppuccin gotchas
- `styles` en setup opts: formato ARRAY `{ "italic" }`, NO hash `{ italic = true }`
- Tras cambios en highlight_overrides: limpiar cache `Remove-Item "$env:LOCALAPPDATA\nvim-data\catppuccin\*"`

## Sublime theme palette
- bg=`#1e1f1c`, accent=`#66d9ef` (cyan), keywords=`#f92672`, strings=`#e6db74`
- `accent` SOLO para FloatTitle, LazyButtonActive, ClaudeCodeTitle
- Borders: `#3e3d32` para TODOS (FloatBorder, SnacksBorder, etc.)

## Python en Windows
- Usar `/c/Python313/python.exe` (NO `python3` — alias roto)
- Siempre `PYTHONIOENCODING=utf-8` para Unicode
