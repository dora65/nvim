return {
	{ "folke/todo-comments.nvim", version = "*" },

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
							["<Esc>"]  = { function(picker) picker:close() end, mode = { "n", "i" } },
							["<C-Up>"] = false,
						},
					},
					list = { border = "rounded" },
					preview = { border = "rounded" },
				},
			},
			-- snacks.animate: desactivado — mini.animate maneja splits, snacks fade-in/out
			-- de floats causaba "efectos de opacidad extraños" al abrir/cerrar UI elements
			animate = { enabled = false },
			-- snacks.explorer = sidebar-estilo file explorer (diferente al picker flotante)
			-- LazyVim snacks_picker extra lo activa → conflicto con neo-tree en `nvim .`
			-- Desactivar: usamos neo-tree como sidebar y mini.files para operaciones
			explorer = { enabled = false },
			dashboard = { enabled = false },
		},
	},
}
