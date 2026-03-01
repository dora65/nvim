return {
	-- ─── Smooth scrolling — animación premium al hacer scroll ──────────────────
	{
		"karb94/neoscroll.nvim",
		event = "VeryLazy",
		opts = {
			mappings = { "<C-u>", "<C-d>", "<C-b>", "zt", "zz", "zb" }, -- <C-f> reservado para búsqueda
			hide_cursor = false,
			stop_eof = true,
			respect_scrolloff = true,
			cursor_scrolls_alone = true,
			easing = "quadratic",
			pre_hook = nil,
			post_hook = nil,
			performance_mode = false,
			duration_multiplier = 0.6,
		},
	},

	-- ─── Indent animation — líneas de indentación animadas ─────────────────────
	{
		"nvim-mini/mini.indentscope",
		event = "BufReadPre",
		opts = {
			symbol = "│",
			options = { try_as_border = true },
			draw = {
				delay = 50,
				animation = function()
					return 5
				end,
			},
		},
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "help", "neo-tree", "Trouble", "lazy", "mason", "toggleterm", "terminal" },
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			})
		end,
	},

	-- ─── Cursor animado — transiciones suaves al mover el cursor ───────────────
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.8,
			trailing_stiffness = 0.5,
			distance_stop_animating = 0.5,
			hide_target_hack = true, -- evita doble cursor: oculta destino, muestra solo estela
		},
		config = function(_, opts)
			local smear = require("smear_cursor")
			smear.setup(opts)
			-- Desactivar en buffers terminales (Claude Code, toggleterm, etc.)
			vim.api.nvim_create_autocmd("TermEnter", {
				callback = function()
					smear.enabled = false
				end,
			})
			vim.api.nvim_create_autocmd("TermLeave", {
				callback = function()
					smear.enabled = true
				end,
			})
		end,
	},
}
