-- ─── nvim-ufo — Ultra Fold: peek + virtual text rico + provider chain ──────────
-- Transforma los folds ciegos en navegación visual completa:
--   zK → peek fold sin expandir (float con contenido completo)
--   zR / zM → abrir/cerrar todos los folds
--   Provider chain: LSP → Treesitter → indent (fallback inteligente)
-- Costo GPU: extmarks de texto puro — cero overhead en OpenGL/WebGPU
return {
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		event = "BufReadPre",
		init = function()
			-- foldcolumn=1: activa 1 columna numérica lateral mínima para marcadores visuales (v / >)
			-- Recupera la UX táctil de colapso visual sin robar excesivo espacio.
			vim.opt.foldcolumn    = "1"
			vim.opt.foldlevel     = 99
			vim.opt.foldlevelstart = 99
			vim.opt.foldenable    = true
		end,
		opts = {
			-- Provider chain por filetype: LSP primero (semántico), luego Treesitter, indent último
			-- lua_ls (lsp-setup.lua) ya provee folds semánticos para Lua desde el arranque
			provider_selector = function(bufnr, filetype, buftype)
				-- CRITICO: Evitar que UFO intente decorar buffers efímeros que mutan rápido
				-- (ej. snacks_notifier, cmp, neo-tree). Esto previene el crash de index out of bounds
				-- cuando snacks win redraw muta el buffer más rápido de lo que ufo recalcula folds.
				if buftype == "nofile" or buftype == "terminal" or buftype == "prompt" then
					return ""
				end
				local ft_map = {
					lua        = { "lsp", "treesitter" },
					python     = { "lsp", "treesitter" },
					cs         = { "lsp", "treesitter" },  -- C# con nvim-lspconfig
					typescript = { "lsp", "treesitter" },
					javascript = { "lsp", "treesitter" },
					json       = { "treesitter" },           -- jsonls folds suelen ser lentos
					markdown   = { "treesitter", "indent" },  -- pcall monkey-patch previene race cond
					yaml       = { "indent" },               -- Treesitter YAML fold es inestable
				}
				return ft_map[filetype] or { "treesitter", "indent" }
			end,

			-- NOTA: Se eliminó fold_virt_text_handler custom porque truncaba los títulos
			-- de las secciones markdown. UFO usará su comportamiento por defecto,
			-- o bien el motor nativo de Neovim 0.10.

			-- Preview float: bordes redondeados — coordina con vim.o.winborder = "rounded"
			preview = {
				win_config = {
					border    = "rounded",
					winblend  = 12,   -- coordina con pumblend de options.lua
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
				},
				mappings = {
					scrollU  = "<C-u>",
					scrollD  = "<C-d>",
					jumpTop  = "gg",
					jumpBot  = "G",
				},
			},

			-- Excluir filetypes donde los folds no tienen sentido
			close_fold_kinds_for_ft = {
				default = { "imports", "comment" },
			},
		},

		config = function(_, opts)
			local ufo = require("ufo")
			ufo.setup(opts)

			-- zR / zM: abrir/cerrar todos los folds (reemplaza los defaults vacíos de nvim)
			vim.keymap.set("n", "zR", ufo.openAllFolds,  { desc = "Open all folds (ufo)" })
			vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "Close all folds (ufo)" })

			-- zK: peek fold sin expandir — el killer feature
			-- Muestra el contenido del fold en un float. Press q/Esc para cerrar.
			vim.keymap.set("n", "zK", ufo.peekFoldedLinesUnderCursor, { desc = "Peek fold content" })

			-- zr / zm: incrementales (un nivel a la vez) — más preciso que zR/zM
			vim.keymap.set("n", "zr", function() ufo.openFoldsExceptKinds() end,    { desc = "Open folds except kinds" })
			vim.keymap.set("n", "zm", function() ufo.closeFoldsWith() end,           { desc = "Close folds with level" })
		end,
	},
}
