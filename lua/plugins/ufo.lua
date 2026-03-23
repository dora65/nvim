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
			-- foldcolumn=0: sin columna numérica lateral (ahorra espacio)
			-- La info de folds se muestra en virt-text al final de línea (▸ N)
			vim.opt.foldcolumn    = "0"
			vim.opt.foldlevel     = 99
			vim.opt.foldlevelstart = 99
			vim.opt.foldenable    = true
		end,
		opts = {
			-- Provider chain por filetype: LSP primero (semántico), luego Treesitter, indent último
			-- lua_ls (lsp-setup.lua) ya provee folds semánticos para Lua desde el arranque
			provider_selector = function(_, filetype, _)
				local ft_map = {
					lua        = { "lsp", "treesitter" },
					python     = { "lsp", "treesitter" },
					cs         = { "lsp", "treesitter" },  -- C# con nvim-lspconfig
					typescript = { "lsp", "treesitter" },
					javascript = { "lsp", "treesitter" },
					json       = { "treesitter" },           -- jsonls folds suelen ser lentos
					markdown   = { "treesitter", "indent" },  -- pcall monkey-patch en markdown.lua previene la race condition
					yaml       = { "indent" },               -- Treesitter YAML fold es inestable
				}
				return ft_map[filetype] or { "treesitter", "indent" }
			end,

			-- Virtual text handler: muestra conteo + primer token del bloque colapsado
			-- Color del suffix: "Comment" group → olive #75715e en Sublime, overlay1 en Catppuccin
			-- Esto coordina con el estilo de comentarios de cada tema sin hardcodear colores
			fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
				local newVirtText = {}
				local suffix = ("  ▸ %d"):format(endLnum - lnum)
				local sufWidth = vim.fn.strdisplaywidth(suffix)
				local targetWidth = width - sufWidth
				local curWidth = 0
				for _, chunk in ipairs(virtText) do
					local chunkText = chunk[1]
					local chunkWidth = vim.fn.strdisplaywidth(chunkText)
					if targetWidth > curWidth + chunkWidth then
						table.insert(newVirtText, chunk)
					else
						chunkText = truncate(chunkText, targetWidth - curWidth)
						local hlGroup = chunk[2]
						table.insert(newVirtText, { chunkText, hlGroup })
						chunkWidth = vim.fn.strdisplaywidth(chunkText)
						if curWidth + chunkWidth < targetWidth then
							suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
						end
						break
					end
					curWidth = curWidth + chunkWidth
				end
				table.insert(newVirtText, { suffix, "Comment" })
				return newVirtText
			end,

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
