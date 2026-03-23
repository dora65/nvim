-- sublime.lua — Entry point del colorscheme "Sublime"
-- Base: catppuccin-mocha (hereda TODOS los highlights — sintaxis 100% identica)
-- Diferenciador: superficies y bordes ref: monokai.jsonc (granular, premium)
-- ThemeSync: escribe "sublime" → ~/.nvim_theme → WezTerm recarga "Sublime"
--
-- USO: :colorscheme sublime

-- 1. Cargar catppuccin mocha como base completa
vim.cmd.colorscheme("catppuccin")

-- 2. Identificar como "sublime" (ThemeSync → ~/.nvim_theme)
vim.g.colors_name = "sublime"

-- 3. Disparar "ColorScheme sublime" → activa sublime_overrides (autocmds.lua)
--    y re-dispara write_nvim_theme() → escribe "sublime" al archivo
vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "sublime", modeline = false })

-- 4. Re-aplicar sublime_overrides después de User VeryLazy
--    Problema: :colorscheme sublime en startup dispara ANTES de que
--    autocmds.lua registre el autocmd sublime_overrides (VeryLazy timing).
--    User VeryLazy garantiza que lazy.nvim terminó de cargar todo.
vim.api.nvim_create_autocmd("User", {
	pattern  = "VeryLazy",
	once     = true,
	callback = function()
		if (vim.g.colors_name or "") == "sublime" then
			vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "sublime", modeline = false })
		end
	end,
})
