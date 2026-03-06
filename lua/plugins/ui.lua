return {
	{ "folke/todo-comments.nvim", version = "*" },

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
					if filename == "" then filename = "[No Name]" end
					local modified = vim.bo[props.buf].modified
					local icon, icon_color = require("nvim-web-devicons").get_icon_color(filename)
					local res = {}

					-- Diagnósticos: badges compactos solo cuando hay errores/warnings
					local diags = vim.diagnostic.get(props.buf)
					local errors, warns = 0, 0
					for _, d in ipairs(diags) do
						if d.severity == vim.diagnostic.severity.ERROR then errors = errors + 1
						elseif d.severity == vim.diagnostic.severity.WARN then warns = warns + 1
						end
					end
					if errors > 0 then table.insert(res, { " ■" .. errors, guifg = "#f38ba8" }) end
					if warns  > 0 then table.insert(res, { " ▲" .. warns,  guifg = "#f9e2af" }) end
					if errors > 0 or warns > 0 then
						table.insert(res, { "  ", guifg = text_color })
					end

					if icon then
						table.insert(res, { icon .. " ", guifg = icon_color })
					end
					table.insert(res, {
						filename,
						gui   = modified and "bold,italic" or "bold",
						guifg = modified and accent or text_color,
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
					-- Overrides documentados (snacks/picker/config/defaults.lua win.input.keys):
					-- Por defecto <Esc>="cancel" (sale de insert, NO cierra el picker)
					-- <C-Up>="history_back" (intercepta nuestro toggle global <C-Up>)
					-- CRÍTICO: deben ir en win.input.keys — top-level keys no se aplican al buffer
					input = {
						border = "rounded",
						keys = {
							["<Esc>"]  = { "close", mode = { "n", "i" } },
							["<C-Up>"] = false,
						},
					},
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
