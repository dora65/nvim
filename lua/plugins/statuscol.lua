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
					-- 0. Fold markers: VSCode-style › / ⌄ via fillchars + ufo
					-- builtin.foldfunc renders the fold open/close states using fillchars chars
					-- NOTA: NO usar condition aquí — causa crash en ufo decorator (index out of bounds)
					{
						text  = { builtin.foldfunc, " " },
						click = "v:lua.ScFa",
					},
					-- 1. Signos unificados: Diagnostics y Gitsigns comparten LA MISMA columna.
					--    Máxima densidad (1 char): Si hay error y git change, Nvim usa el icono del error
					--    (mayor prioridad) y el color de fondo del git change. Oro puro espacial.
					{
						sign = {
							maxwidth  = 1,
							colwidth  = 1,
							auto      = false,
						},
						click = "v:lua.ScSa",
					},
					-- 2. Número de línea: relativo en otras, absoluto en línea actual
					{
						text  = { builtin.lnumfunc, " " },
						click = "v:lua.ScLa",
					},
				},
			})
		end,
	},
}
