return {
	-- ─── Smooth scrolling — animación premium al hacer scroll ──────────────────
	{
		"karb94/neoscroll.nvim",
		event = "VeryLazy",
		opts = {
			-- Scroll suave en TODOS los ambitos del teclado
			-- <C-f> excluido: reservado para busqueda (searchbox.nvim)
			-- <PageUp>/<PageDown> NO son mappings validos de neoscroll — van como keymaps en config
			mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-e>", "<C-y>", "zt", "zz", "zb" },
			hide_cursor = false,
			stop_eof = true,
			respect_scrolloff = true,
			cursor_scrolls_alone = true,
			easing = "cubic",  -- cubic: arranque más instantáneo que sine — mejor para navegación con teclado
			pre_hook = nil,
			post_hook = nil,
			performance_mode = false,
			duration_multiplier = 0.55,  -- 0.6→0.55: 8% más responsivo (sweet spot fluidez+control)
		},
		-- config: setup + mouse scroll suave (WezTerm envia ScrollWheel en alt-screen)
		config = function(_, opts)
			local ns = require("neoscroll")
			ns.setup(opts)
			-- 4 lineas x 70ms quadratic = scroll preciso (4 vs 5: más control por paso, menos overshooting)
			vim.keymap.set({ "n", "v" }, "<ScrollWheelUp>", function()
				ns.scroll(-4, { move_cursor = false, duration = 70 })
			end, { silent = true, desc = "Smooth scroll up" })
			vim.keymap.set({ "n", "v" }, "<ScrollWheelDown>", function()
				ns.scroll(4, { move_cursor = false, duration = 70 })
			end, { silent = true, desc = "Smooth scroll down" })
			-- PageUp/Down: keymaps.lua (VeryLazy) los define con step=half-page — no duplicar aquí
		end,
	},

	-- ─── Indent animation — líneas de indentación animadas ─────────────────────
	{
		"nvim-mini/mini.indentscope",
		event = "BufReadPre",
		-- CRITICO: opts debe ser function() para evitar "module not found" al parsear el spec.
		-- require("mini.indentscope") dentro de opts={} (table literal) se evalúa eagerly ANTES
		-- que Lazy.nvim cargue el plugin. opts=function() lo difiere hasta después del load.
		opts = function()
			return {
				symbol = "│",
				options = { try_as_border = true },
				draw = {
					delay = 50,
					-- quadratic out: arranque instantáneo + deceleración natural — mejor que exponential in-out
					-- para "ink drop": la línea aparece rápido y se asienta suavemente (no hay lag inicial)
					animation = require("mini.indentscope").gen_animation.quadratic({ easing = "out", duration = 3, unit = "step" }),
				},
			}
		end,
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				-- Ampliado: agregar UIs de snacks y fzf-lua para evitar indentscope en floats de UI
				pattern = {
					"markdown", "text", "help",
					"neo-tree", "Trouble", "lazy", "mason",
					"toggleterm", "terminal",
					"snacks_notifier", "snacks_dashboard",
					"fzf", "blink-cmp",
				},
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			})
		end,
	},

	-- ─── Cursor animado — WezTerm 240fps + WebGPU / smear-cursor premium ───────
	-- Filosofia: elegancia con caracter — trail visible pero no cometa
	-- stiffness 0.55: visible en movimientos rapidos, sin cola exagerada
	-- trailing_stiffness 0.35: cola suave y elegante al desplazarse
	-- smear_between_neighbor_lines: evita salto brusco en movimiento vertical 1 linea
	-- legacy_computing_symbols_support=false: seguro en Windows (evita glyph issues)
	{
		"sphamba/smear-cursor.nvim",
		event = "VeryLazy",
		opts = {
			-- Sweet spot fluido y elegante: baja stiffness = cola larga, natural (ink drop)
			-- FLUIDEZ: stiffness alto = cola corta/responsiva. trailing bajo = cola elegante.
			-- damping alto = sin oscilación al parar. distance alto = parada limpia (sin micro-flicker).
			-- 0.55/0.25: cola más larga tipo "mercurio" — arranque igualmente ágil, trailing más fluido
			stiffness = 0.55,                    -- Ligeramente menos rígido = cola más visible en saltos largos
			trailing_stiffness = 0.25,           -- Cola más elegante (0.30 era un poco corta para WezTerm 240fps)
			stiffness_insert_mode = 0.65,
			trailing_stiffness_insert_mode = 0.35,
			damping = 0.85,                      -- Fuerte amortiguación = movimiento robusto sin rebote/flicker
			damping_insert_mode = 0.88,
			distance_stop_animating = 0.5,  -- 0.5 celdas: sweet spot (evita micro-flicker en mov 1 celda)
			hide_target_hack = false,
			smear_between_neighbor_lines = true,
			legacy_computing_symbols_support = false,
			-- 4ms = 250fps: Render ultra fluido, respaldado por WezTerm WebGPU 240fps
			time_interval = 4,
			cursor_color = "#66d9ef",  -- sync con Cursor hl sublime: cyan monokai ST3
			transparent_bg_fallback_color = "#1e1f1c", -- bg real Monokai flat: CRITICO para no artifacts
		},
		config = function(_, opts)
			local smear = require("smear_cursor")
			smear.setup(opts)

			local function sync_smear_color()
				vim.schedule(function()
					-- cursor_color: sigue el highlight Cursor del tema activo
					local c_hl = vim.api.nvim_get_hl(0, { name = "Cursor", link = false })
					-- transparent_bg_fallback_color: bg real del editor
					-- Hardcodeado a #1e1f1c (Monokai flat) para garantizar NO artifacts (sombra negra)
					smear.setup({
						cursor_color = c_hl.bg and string.format("#%06x", c_hl.bg) or "#cba6f7",
						transparent_bg_fallback_color = "#1e1f1c",
					})
				end)
			end

			vim.api.nvim_create_autocmd("ColorScheme", { callback = sync_smear_color })
			vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = sync_smear_color })

			-- Desactivar en terminales (Claude, toggleterm, etc) basado en buftype
			-- Esto previene la "muerte permanente" si se navega a otra ventana usando click/shortcuts
			vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
				callback = function()
					if vim.bo.buftype == "terminal" then
						smear.enabled = false
					else
						smear.enabled = true
					end
				end,
			})
		end,
	},

	-- ─── Window animations — fade open/close/resize (mini.animate) ─────────────
	-- scroll=false: neoscroll lo cubre. cursor=false: smear-cursor lo cubre.
	-- resize: seguro (conflicto noice #761 es scroll-específico, no resize).
	-- open/close: habilitados para floats (toggleterm, snacks, fzf-lua, etc.)
	--   con filtro que excluye neo-tree (wipe+resize simultáneos = artefactos).
	{
		"nvim-mini/mini.animate",
		version = false,
		event = "VeryLazy",
		opts = function()
			local animate = require("mini.animate")

			-- Filtro: excluir filetypes que causan artefactos en open/close
			local skip_ft = {
				["neo-tree"] = true, ["toggleterm"] = true,
				["NvimTree"] = true, ["dashboard"] = true, ["alpha"] = true,
				-- snacks filetypes: notifier y input son floats de muy corta vida, animar los causa flicker
				["snacks_notifier"] = true, ["snacks_input"] = true,
			}
			local function float_winconfig(win_id)
				local ok, buf = pcall(vim.api.nvim_win_get_buf, win_id)
				if not ok then return nil end
				local ft = vim.bo[buf].filetype
				local bt = vim.bo[buf].buftype
				-- Solo floats, excluir neo-tree y splits normales
				if skip_ft[ft] or bt == "terminal" or bt == "nofile" or bt == "prompt" then return nil end
				local cfg = vim.api.nvim_win_get_config(win_id)
				if not cfg.relative or cfg.relative == "" then return nil end  -- solo floats
				return animate.gen_winconfig.slide({ direction = "from_center" })(win_id)  -- from_center: floats emergen/colapsan al centro (modal premium, from_edge es para paneles laterales)
			end

			return {
				scroll = { enable = false }, -- delegado a neoscroll
				cursor = { enable = false }, -- delegado a smear-cursor
				resize = {
					enable = true,
					-- 40ms cubic: arranque explosivo, deceleración en el último 10%. Responsividad pura.
					timing = animate.gen_timing.cubic({ duration = 40, unit = "total" }),
				},
				-- open: cubic deceleration — 80ms es el estándar matemático de "animación percibida pero instantánea"
				open = {
					enable = true,
					timing   = animate.gen_timing.cubic({ duration = 80, unit = "total" }),
					winconfig = float_winconfig,
				},
				-- close: cubic 40ms — desaparecer debe ser el doble de rápido que aparecer
				close = {
					enable = true,
					timing   = animate.gen_timing.cubic({ duration = 40, unit = "total" }),
					winconfig = float_winconfig,
				},
			}
		end,
	},
}
