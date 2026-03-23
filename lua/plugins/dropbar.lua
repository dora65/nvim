-- ─── dropbar.nvim — Breadcrumbs IDE en el winbar nativo ──────────────────────
-- incline → filename del buffer; dropbar → contexto de símbolo en tiempo real
-- Self-contained: LSP → Treesitter → Markdown (sin nvim-navic)
-- Dropdown interactivo: navegar, filtrar y saltar por teclado o mouse
return {
	{
		"Bekaboo/dropbar.nvim",
		event = "BufReadPre",
		opts = {
			-- Iconos: symbols por kind + file/folder auto desde mini.icons
			-- use_devicons eliminado (deprecado) → file_icon/folder_icon son nil = auto-detect
			icons = {
				kinds = {
					symbols = {
						Array         = "󰅪 ",
						Boolean       = "󰨙 ",
						Class         = " ",
						Constant      = "󰏿 ",
						Constructor   = " ",
						Enum          = " ",
						EnumMember    = " ",
						Event         = " ",
						Field         = " ",
						File          = "󰈔 ",
						Folder        = "󰉖 ",
						Function      = "󰊕 ",
						H1Marker      = "󰉫 ",
						H2Marker      = "󰉬 ",
						H3Marker      = "󰉭 ",
						H4Marker      = "󰉮 ",
						H5Marker      = "󰉯 ",
						H6Marker      = "󰉰 ",
						Interface     = " ",
						Keyword       = "󰌋 ",
						MarkdownH1    = "󰉫 ",
						MarkdownH2    = "󰉬 ",
						MarkdownH3    = "󰉭 ",
						Method        = "󰆧 ",
						Module        = "󰏗 ",
						Namespace     = "󰅩 ",
						Null          = "󰢤 ",
						Number        = "󰎠 ",
						Object        = "󰅩 ",
						Operator      = "󰆕 ",
						Package       = "󰆦 ",
						Property      = " ",
						Reference     = "󰌷 ",
						Snippet       = "󰩫 ",
						String        = "󰉾 ",
						Struct        = " ",
						Text          = " ",
						Type          = " ",
						TypeParameter = "󰆩 ",
						Unit          = "󰑭 ",
						Value         = "󰎠 ",
						Variable      = "󰀫 ",
					},
				},
				ui = {
					bar  = { separator = "  ", extends = "…" },
					menu = { separator = " ",  indicator = " " },
				},
			},

			-- bar: update_events y attach_events
			bar = {
				update_events = {
					buf    = { "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI" },
					win    = { "WinResized" },
					global = { "DirChanged" },
				},
				attach_events = { "BufWinEnter", "BufWritePost" },
				enable = function(buf, win, _)
					if not vim.api.nvim_buf_is_valid(buf)
						or not vim.api.nvim_win_is_valid(win)
						or vim.api.nvim_win_get_config(win).zindex ~= nil then
						return false
					end
					local ft = vim.bo[buf].filetype
					local excluded = {
						"neo-tree", "toggleterm", "fzf", "lazy", "mason",
						"TelescopePrompt", "snacks_picker_input", "snacks_picker_list",
						"which-key", "help", "quickfix", "nofile", "noice",
						"NvimTree", "dashboard", "alpha", "aerial",
					}
					for _, v in ipairs(excluded) do
						if ft == v then return false end
					end
					return vim.bo[buf].buflisted
				end,
				padding = { left = 1, right = 0 },
			},

			-- Menú dropdown: lazy — source buffer NO salta al navegar; solo en <CR>
			menu = {
				quick_navigation = true,
				entry = { padding = { left = 1, right = 1 } },
				win_configs = {
					border = "rounded",
				},
				keymaps = {
					-- / abre fuzzy filter dentro del menú actual
					["/"] = function()
						local ok, api = pcall(require, "dropbar.api")
						if ok then api.fuzzy_find_toggle() end
					end,
				},
			},
		},

		keys = {
			-- gb: abre picker interactivo del breadcrumb (navegar contexto)
			-- gB: salta al inicio del contexto actual (función/clase)
			{ "gb", function() require("dropbar.api").pick() end,              desc = "Breadcrumb: pick" },
			{ "gB", function() require("dropbar.api").goto_context_start() end, desc = "Breadcrumb: context start" },
		},
	},
}
