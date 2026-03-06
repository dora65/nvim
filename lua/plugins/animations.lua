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

	-- ─── Cursor animado — calibrado para WezTerm 240fps + WebGPU/Mailbox ──────
	-- Filosofía: fluido pero imperceptible — el usuario siente suavidad, no ve el efecto
	-- stiffness 0.4: más suave que 0.8 (default), aprovecha los 240fps disponibles
	-- trailing_stiffness 0.3: cola más larga y elegante (vs 0.5 que se corta rápido)
	-- smear_between_neighbor_lines: evita salto brusco en movimiento vertical 1 línea
	-- legacy_computing_symbols_support=false: más seguro en Windows (evita glyph issues)
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			stiffness = 0.4,
			trailing_stiffness = 0.3,
			distance_stop_animating = 0.5,
			hide_target_hack = true,
			smear_between_neighbor_lines = true,
			legacy_computing_symbols_support = false,
			-- cursor_color sincronizado dinámicamente con el tema (ver ColorScheme autocmd abajo)
			cursor_color = "None",
		},
		config = function(_, opts)
			local smear = require("smear_cursor")
			smear.setup(opts)

			-- Sincronizar color smear con el tema activo:
			-- Lee Cursor.bg (acento del tema) y re-aplica a smear.
			-- Consistencia total: smear nvim = cursor WezTerm = cursor PowerShell (todos = accent)
			local function sync_smear_color()
				vim.schedule(function()
					local hl = vim.api.nvim_get_hl(0, { name = "Cursor", link = false })
					if hl.bg then
						smear.setup({ cursor_color = string.format("#%06x", hl.bg) })
					end
				end)
			end

			vim.api.nvim_create_autocmd("ColorScheme", { callback = sync_smear_color })
			vim.api.nvim_create_autocmd("VimEnter",    { once = true, callback = sync_smear_color })

			-- Desactivar en terminales: evita artifacts en Claude Code, toggleterm, etc.
			vim.api.nvim_create_autocmd("TermEnter", {
				callback = function() smear.enabled = false end,
			})
			vim.api.nvim_create_autocmd("TermLeave", {
				callback = function() smear.enabled = true end,
			})
		end,
	},

	-- ─── Window animations — fade open/close/resize (mini.animate) ─────────────
	-- scroll=false: neoscroll lo cubre. cursor=false: smear-cursor lo cubre.
	-- resize: seguro (conflicto noice #761 es scroll-específico, no resize).
	{
		"nvim-mini/mini.animate",
		version = false,
		event = "VeryLazy",
		opts = function()
			local animate = require("mini.animate")
			return {
				scroll = { enable = false }, -- delegado a neoscroll
				cursor = { enable = false }, -- delegado a smear-cursor
				resize = {
					enable = true,
					-- quadratic: más natural que lineal — acelera al inicio, suaviza al final
					timing = animate.gen_timing.quadratic({ duration = 80, unit = "total" }),
				},
				open = {
					enable = true,
					-- static(): posición final, solo fade opacidad (correcto para floats/splits)
					-- quadratic 150ms: rápido al inicio (responsividad), suave al final (elegancia)
					-- winblend 90→0: glass reveal — empieza casi transparente, llega a opaco
					timing = animate.gen_timing.quadratic({ duration = 150, unit = "total" }),
					winconfig = animate.gen_winconfig.static(),
					winblend = animate.gen_winblend.linear({ from = 90, to = 0 }),
				},
				close = {
					enable = true,
					-- linear 100ms: cierre limpio y rápido
					timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
					winconfig = animate.gen_winconfig.static(),
					winblend = animate.gen_winblend.linear({ from = 0, to = 90 }),
				},
			}
		end,
	},
}
