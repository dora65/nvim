return {
	{ "folke/todo-comments.nvim", version = "*" },

	{
		"amrbashir/nvim-docs-view",
		lazy = true,
		cmd = "DocsViewToggle",
		opts = {
			position = "right",
			width = 60,
		},
	},

	{
		"b0o/incline.nvim",
		event = "BufReadPre",
		priority = 1200,
		config = function()
			require("incline").setup({
				window = {
					margin = { vertical = 0, horizontal = 1 },
					padding = { left = 1, right = 1 },
					placement = { horizontal = "right", vertical = "top" },
				},
				hide = { cursorline = true },
				render = function(props)
					-- Colores dinámicos según tema activo
					local accent, text_color
					local cs = vim.g.colors_name or ""
					if cs:find("catppuccin") then
						local cp = require("catppuccin.palettes").get_palette("mocha")
						accent     = cp.peach
						text_color = cp.text
					elseif cs:find("kanagawa") or cs:find("gentleman") then
						accent     = "#E0C15A"  -- oro: acento firma Gentleman Kanagawa Blur
						text_color = "#F3F6F9"
					else  -- sonokai atlantis
						accent     = "#f39660"  -- orange
						text_color = "#e2e2e3"  -- fg
					end
					local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
					if filename == "" then
						filename = "[No Name]"
					end
					local modified = vim.bo[props.buf].modified
					local icon, icon_color = require("nvim-web-devicons").get_icon_color(filename)
					local res = {}
					if icon then
						table.insert(res, { icon .. " ", guifg = icon_color })
					end
					table.insert(res, {
						filename,
						gui    = modified and "bold,italic" or "bold",
						guifg  = modified and accent or text_color,
					})
					if modified then
						table.insert(res, { " ●", guifg = accent })
					end
					return res
				end,
			})
		end,
	},

	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		opts = {
			plugins = {
				gitsigns = true,
				tmux = true,
				kitty = { enabled = false, font = "+2" },
				twilight = { enabled = true },
			},
		},
	},

	{
		"folke/snacks.nvim",
		opts = {
			notifier = {},
			image = {},
			picker = {
				matcher = {
					fuzzy = true,
					smartcase = true,
					ignorecase = true,
					filename_bonus = true,
				},
				sources = {
					explorer = {
						matcher = {
							fuzzy = true,
							smartcase = true,
							ignorecase = true,
							filename_bonus = true,
							sort_empty = false,
						},
					},
				},
				win = {
					input = { border = "rounded" },
					list = { border = "rounded" },
					preview = { border = "rounded" },
				},
			},
			-- snacks.explorer = sidebar-estilo file explorer (diferente al picker flotante)
			-- LazyVim snacks_picker extra lo activa → conflicto con neo-tree en `nvim .`
			-- Desactivar: usamos neo-tree como sidebar y mini.files para operaciones
			explorer = { enabled = false },
			dashboard = { enabled = false },
		},
	},
}
