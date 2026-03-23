-- ─── statuscol.nvim — Status column profesional con carriles separados ──────────
-- Problema que resuelve: signcolumn = "yes:2" da 2 chars para TODOS los signos.
-- Gitsigns, diagnostics LSP y DAP compiten por esos 2 chars y se sobreescriben.
--
-- statuscol separa en carriles propios con click handlers:
--   [E/W diag] [142] [M/U git]  ← cada uno en su carril
--
-- Requiere nvim 0.9+ (statuscolumn option). Funciona junto con nvim-ufo:
--   foldcolumn=0 (sin columna visual); info de folds en virt-text (▸ N).
return {
	{
		"luukvbaal/statuscol.nvim",
		event = "BufReadPre",
		config = function()
			local builtin = require("statuscol.builtin")
			require("statuscol").setup({
				-- relculright: números relativos alineados a la derecha
				-- (comportamiento estándar que los usuarios esperan)
				relculright = true,

				-- ft_ignore: filetypes donde no aplicar statuscolumn custom
				-- (paneles especiales gestionan su propia presentación)
				ft_ignore = {
					"neo-tree", "toggleterm", "fzf", "lazy", "mason",
					"help", "quickfix", "nofile", "NvimTree", "dashboard",
					"TelescopePrompt", "snacks_picker_input", "snacks_picker_list",
				},

				-- Segmentos en orden izquierda→derecha:
				segments = {
					-- 1. Signos diagnósticos (LSP errors/warnings) — carril propio
					--    Sin esto, los signos de git los sobreescriben cuando ambos existen
					{
						sign = {
							namespace = { "diagnostic" },
							maxwidth  = 1,
							colwidth  = 1,
							auto      = false,
						},
						click = "v:lua.ScSa",
					},
					-- 3. Número de línea: relativo en otras, absoluto en línea actual
					--    builtin.lnumfunc ya maneja relative+absolute automáticamente
					{
						text  = { builtin.lnumfunc, " " },
						click = "v:lua.ScLa",
					},
					-- 4. Git signs (gitsigns via LazyVim) — carril propio al final
					--    Sin competir con diagnostics: ver AMBOS simultáneamente
					{
						sign = {
							namespace = { "gitsigns" },
							maxwidth  = 1,
							colwidth  = 1,
							auto      = false,
						},
						click = "v:lua.ScSa",
					},
				},
			})
		end,
	},
}
