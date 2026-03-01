-- This file contains the configuration for the oil.nvim plugin in Neovim.

return {
	-- Plugin: oil.nvim
	-- URL: https://github.com/stevearc/oil.nvim
	-- Description: A Neovim plugin for managing and navigating directories.
	"stevearc/oil.nvim",

	opts = {
		-- Oil solo disponible via keymap (-), neo-tree maneja el auto-open
		default_file_explorer = false,
		-- Lista de vistas disponibles
		view_options = {
			-- Mostrar archivos ocultos
			show_hidden = true,
			-- Configuración por tipo de archivo
			is_hidden_file = function(name, bufnr)
				return vim.startswith(name, ".")
			end,
			-- Configuración de archivos ignorados por Git
			is_gitignored = function(name, bufnr)
				local git_cmd = { "git", "check-ignore", name }
				local output = vim.fn.system(git_cmd)
				return vim.v.shell_error == 0
			end,
		},
		-- Configuración de ventanas flotantes
		float = {
			-- Abrir Oil en un panel flotante
			padding = 2,
			max_width = 60,
			max_height = 30,
			border = "single",
			win_options = {
				winblend = 3,
			},
		},
		-- Key mappings for oil.nvim actions
		keymaps = {
			["g?"] = "actions.show_help", -- Show help
			["<CR>"] = "actions.select", -- Select entry
			["<C-s>"] = { "actions.select", opts = { vertical = true } }, -- Open entry in vertical split
			["<C-d>"] = { "actions.select", opts = { horizontal = true } }, -- Open entry in horizontal split
			["<C-t>"] = { "actions.select", opts = { tab = true } }, -- Open entry in new tab
			["<C-p>"] = "actions.preview", -- Preview entry
			["<C-c>"] = "actions.close", -- Close oil.nvim
			["<C-l>"] = "actions.refresh", -- Refresh oil.nvim
			["-"] = "actions.parent", -- Go to parent directory
			["_"] = "actions.open_cwd", -- Open current working directory
			["`"] = "actions.cd", -- Change directory
			["~"] = "actions.tcd", -- Change directory for the current tab
			["gs"] = "actions.change_sort", -- Change sorting method
			["gx"] = "actions.open_external", -- Open entry with external application
			["g."] = "actions.toggle_hidden", -- Toggle hidden files
			["zi"] = "actions.toggle_hidden", -- Atajo adicional Vim-style para mejor visibilidad
		},
		use_default_keymaps = false, -- Do not use default key mappings
		-- Añadir barra de estado para mostrar el estado de archivos ocultos
		win_options = {
			statuscolumn = "",
			signcolumn = "no",
		},
	},

	-- Optional dependencies
	dependencies = {
		-- Plugin: nvim-web-devicons
		-- URL: https://github.com/nvim-tree/nvim-web-devicons
		-- Description: A Lua fork of vim-web-devicons for Neovim.
		"nvim-tree/nvim-web-devicons",
	},

	-- Configurar mensaje de ayuda más claro
	config = function(_, opts)
		require("oil").setup(opts)
		-- Crear un autocomando para mostrar un mensaje sobre cómo mostrar/ocultar archivos
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "oil",
			callback = function()
				vim.api.nvim_echo({
					{ "Oil: Presiona g. o zi para mostrar/ocultar archivos ocultos", "WarningMsg" },
				}, false, {})
			end,
			once = true,
		})
	end,
}
