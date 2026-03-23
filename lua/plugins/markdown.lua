return {
	-- ─── 1. Renderizado visual in-buffer ─────────────────────────────────────
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
		ft = { "markdown", "Avante" },
		-- config reemplaza el auto-setup de lazy: permite monkey-patch ANTES de setup()
		config = function(_, opts)
			-- FIX permanente para "Index out of bounds" en nvim_buf_get_text:
			-- render-markdown agenda callbacks via vim.schedule; para cuando ejecutan,
			-- el treesitter node puede tener posiciones fuera del buffer actual.
			-- Wrapping get_node_text con pcall captura el error en C antes de propagarse.
			-- Retornar "" es seguro: render-markdown omite el nodo y sigue renderizando.
			local orig_gnt = vim.treesitter.get_node_text
			vim.treesitter.get_node_text = function(node, source, options)
				local ok, result = pcall(orig_gnt, node, source, options)
				return ok and result or ""
			end
			-- FULL-RENDER: cuando vim.b.rm_render_full=true, env.range cubre el buffer completo.
			-- view.lua llama env.range(buf, win, 10) para calcular el rango visible + padding.
			-- Al retornar {0, line_count} el parser procesa TODO el documento en un solo ciclo.
			-- La condición offset > 0 protege la llamada de view:contains() que usa offset=0.
			local ok_env, env_mod = pcall(require, "render-markdown.lib.env")
			if ok_env then
				local orig_range = env_mod.range
				env_mod.range = function(buf, win, offset)
					if offset > 0 and vim.b[buf] and vim.b[buf].rm_render_full then
						return { 0, vim.api.nvim_buf_line_count(buf) }
					end
					return orig_range(buf, win, offset)
				end
			end
			require("render-markdown").setup(opts)
			-- ── Luminance hierarchy: sobreescribir DESPUÉS de setup() ──────────────
			-- render-markdown recalcula RenderMarkdownH1-H6 con su propia lógica en
			-- setup() → nuestros catppuccin highlight_overrides (compile-time) pierden.
			-- Solución: aplicar post-setup() + re-aplicar en cada ColorScheme.
			-- vim.schedule() garantiza que nuestro handler corre DESPUÉS del de render-md.
			local function apply_rm_hl()
				-- Heading text: jerarquía luminosa suave — H1 más brillante, H6 casi invisible
				-- Usando style="icon" no hay backgrounds; solo el texto con color graduado
				vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = "#d4d2cc", bold = true })
				vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = "#b8b6b0", bold = true })
				vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = "#9e9c96", bold = true })
				vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = "#868480" })
				vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = "#706e6a", italic = true })
				vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = "#5e5c58", italic = true })
				-- Bullet: peach más tenue (antes fd971f brillante)
				vim.api.nvim_set_hl(0, "RenderMarkdownBullet",    { fg = "#c87a3a" })
				-- Quote: icon │ en color muy sutil, texto hereda highlight markdown normal
				vim.api.nvim_set_hl(0, "RenderMarkdownQuote",     { fg = "#5a5850" })
				vim.api.nvim_set_hl(0, "RenderMarkdownQuoteLine", { fg = "#2a2926" })
				-- Code inline: bg sutil para distinguir sin gritar
				vim.api.nvim_set_hl(0, "RenderMarkdownCode",      { bg = "#272724" })
				vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { fg = "#c8c6c0", bg = "#2e2d2a" })
			end
			apply_rm_hl()
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("RenderMarkdownColors", { clear = true }),
				callback = function() vim.schedule(apply_rm_hl) end,
			})
		end,
		opts = {
			-- Activo por defecto: el archivo abre en Rendered (estado 3)
			-- <leader>mr cicla: Raw -> Hybrid -> Rendered
			enabled = true,
			-- Debounce: espera Nms tras cambios antes de re-renderizar
			-- 200ms previene la race condition "Index out of bounds" en treesitter
			-- (nvim_buf_get_text recibe nodo stale si el buffer cambia muy rapido)
			debounce = 200,
			-- Solo renderizar en Normal y Command — excluye Insert donde ocurre la race condition
			render_modes = { "n", "c" },
			-- Ocultar errores de treesitter en notificaciones (ya logueados en :messages)
			log_level = vim.log.levels.ERROR,
			-- CRITICO: sin esto, la linea bajo el cursor siempre muestra markdown crudo
			-- aunque concealcursor="ncv" este activo. anti_conceal es independiente de vim.
			-- Con false: el modo Rendered renderiza TODO incluyendo la linea del cursor.
			-- En Hybrid el comportamiento de cursor crudo lo controla concealcursor="" de vim.
			anti_conceal = { enabled = false },
			heading = {
				enabled = true,
				sign = false,      -- sin iconos en signcolumn (quita "líneas de color" izquierda)
				style = "icon",    -- icono + texto sin background full-width (más elegante)
				icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
				left_pad = 0,
				right_pad = 0,
			},
			bullet = {
				enabled = true,
				icons = { "●", "○", "◆", "◇" },
				right_pad = 1,
			},
			checkbox = {
				enabled = true,
				unchecked = { icon = "󰄱 " },
				checked = { icon = "󰱒 " },
				custom = {
					todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
				},
			},
			code = {
				enabled = true,
				sign = false,
				style = "full",
				border = "thin",
				width = "block",  -- ajusta al contenido (no full-width del terminal)
				min_width = 45,
				left_pad = 2,
				right_pad = 2,
				language_pad = 1,
			},
			pipe_table = {
				enabled = true,
				preset = "round",
				style = "full",
				cell = "padded",
				min_width = 0,
				alignment_char = "┴",
			},
			callout = {
				note      = { raw = "[!NOTE]",      rendered = "󰋽 Note",      highlight = "RenderMarkdownInfo"    },
				tip       = { raw = "[!TIP]",       rendered = "󰌶 Tip",       highlight = "RenderMarkdownSuccess" },
				important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint"    },
				warning   = { raw = "[!WARNING]",   rendered = "󰀪 Warning",   highlight = "RenderMarkdownWarn"    },
				caution   = { raw = "[!CAUTION]",   rendered = "󰃦 Caution",   highlight = "RenderMarkdownError"   },
			},
			link = {
				enabled = true,
				image = "󰥶 ",
				hyperlink = "󰌹 ",
				custom = {
					web = { pattern = "^http", icon = "󰖟 " },
				},
			},
			dash = { enabled = true, icon = "─", width = "full" },
			quote = { enabled = true, icon = "│" },  -- línea delgada vs bloque grueso ▋
		},
		keys = {
			-- ── Ciclo de vistas: Raw -> Hybrid -> Rendered ───────────────────────
			-- Raw:      conceal=0, render OFF  → sintaxis cruda completa
			-- Hybrid:   conceal=2, cursor raw  → render activo, cursor muestra raw (edicion comoda)
			-- Rendered: conceal=2, cursor off  → render 100%, sin sintaxis visible nunca
			{
				"<leader>mr",
				function()
					local modes = {
						-- wrap: gestionado por win_options del plugin (default=false, rendered=true)
						-- Al activar render: wrap=true + leftcol=0 automático (nvim#14050 workaround)
						{ level = 0, cursor = "",    rm = false, label = "Raw — sintaxis + scroll libre" },
						{ level = 2, cursor = "",    rm = true,  label = "Hybrid — render + cursor raw" },
						{ level = 2, cursor = "ncv", rm = true,  label = "Rendered — 100% renderizado" },
					}
					local idx = vim.b.md_view_state or 1
					idx = idx % #modes + 1
					vim.b.md_view_state = idx
					local m = modes[idx]
					vim.opt_local.conceallevel = m.level
					vim.opt_local.concealcursor = m.cursor
					local rm = require("render-markdown")
					local buf = vim.api.nvim_get_current_buf()
					local win = vim.api.nvim_get_current_win()
					if m.rm then
						-- Rendered (idx=3): full-render activo → buffer completo en un ciclo
						-- Hybrid  (idx=2): render normal por viewport (performance)
						vim.b[buf].rm_render_full = (idx == 3) or nil
						rm.enable()
						if idx == 3 then
							require("render-markdown.core.ui").update(buf, win, "full", true)
						end
					else
						vim.b[buf].rm_render_full = nil
						rm.disable()
					end
					vim.notify(m.label, vim.log.levels.INFO, { title = "Markdown" })
				end,
				ft = "markdown",
				desc = "Cycle view: Raw / Hybrid / Rendered",
			},

			-- ── PDF Export — usa la funcion 'pdf' del PowerShell profile ─────────
			{
				"<leader>mP",
				function()
					local file = vim.fn.expand("%:p")
					vim.notify("Generando PDF Light...", vim.log.levels.INFO, { title = "PDF" })
					vim.fn.jobstart({ "pwsh.exe", "-Command", "pdf '" .. file .. "'" }, {
						on_exit = function(_, code)
							vim.schedule(function()
								local msg = code == 0 and "PDF Light generado" or "Error al generar PDF"
								local lvl = code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
								vim.notify(msg, lvl, { title = "PDF" })
							end)
						end,
					})
				end,
				ft = "markdown",
				desc = "Export PDF Light",
			},
			{
				"<leader>mk",
				function()
					local file = vim.fn.expand("%:p")
					vim.notify("Generando PDF Dark...", vim.log.levels.INFO, { title = "PDF" })
					vim.fn.jobstart({ "pwsh.exe", "-Command", "pdf '" .. file .. "' -d" }, {
						on_exit = function(_, code)
							vim.schedule(function()
								local msg = code == 0 and "PDF Dark generado" or "Error al generar PDF"
								local lvl = code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
								vim.notify(msg, lvl, { title = "PDF" })
							end)
						end,
					})
				end,
				ft = "markdown",
				desc = "Export PDF Dark",
			},
			{
				"<leader>mS",
				function()
					local file = vim.fn.expand("%:p")
					vim.notify("Generando PDF Supreme...", vim.log.levels.INFO, { title = "PDF" })
					vim.fn.jobstart({ "pwsh.exe", "-Command", "pdf '" .. file .. "' -s" }, {
						on_exit = function(_, code)
							vim.schedule(function()
								local msg = code == 0 and "PDF Supreme generado" or "Error al generar PDF"
								local lvl = code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
								vim.notify(msg, lvl, { title = "PDF" })
							end)
						end,
					})
				end,
				ft = "markdown",
				desc = "Export PDF Supreme",
			},
		},
	},

	-- ─── 2. Preview en navegador ──────────────────────────────────────────────
	-- Reemplaza iamcco/markdown-preview.nvim (abandonado 2022, roto con Node.js v20+)
	-- live-preview.nvim: pure Lua, zero dependencias externas, funciona nativamente en Windows
	-- Tip: Ctrl+P en el navegador → "Guardar como PDF" = PDF inmediato sin xelatex
	{
		"brianhuster/live-preview.nvim",
		cmd = { "LivePreview" },
		ft = { "markdown" },
		opts = {
			port = 5500,
			browser = "default", -- usa el navegador por defecto del sistema
			sync_scroll = true,
			picker = "snacks.picker",
		},
		keys = {
			{ "<leader>mp", "<cmd>LivePreview start<cr>", ft = "markdown", desc = "Browser preview (open)" },
			{ "<leader>mc", "<cmd>LivePreview close<cr>", ft = "markdown", desc = "Browser preview (close)" },
		},
	},

	-- ─── 3. Paste de imagenes desde clipboard ─────────────────────────────────
	-- Screenshot con Win+Shift+S → vuelves a nvim → <leader>mi
	-- Guarda en ./assets/<timestamp>.png y escribe la sintaxis automaticamente
	{
		"HakonHarnes/img-clip.nvim",
		ft = { "markdown" },
		opts = {
			default = {
				dir_path = "assets",
				file_name = "%Y%m%d_%H%M%S",
				prompt_for_file_name = false,
				drag_and_drop = { enabled = true },
				use_absolute_path = false,
			},
			filetypes = {
				markdown = {
					url_encode_path = true,
					template = "![$CURSOR]($FILE_PATH)",
				},
			},
		},
		keys = {
			{ "<leader>mi", "<cmd>PasteImage<cr>", ft = "markdown", desc = "Paste image from clipboard" },
		},
	},

	-- ─── 4. Edicion y navegacion de tablas Markdown ──────────────────────────────
	-- Tab/S-Tab: navega celdas en insert mode (imprescindible en tablas anchas)
	-- gO: inserta tabla de contenidos al inicio del documento
	-- <C-Space>: toggle checkbox [ ] → [x]
	-- :MDTableFormat: formatea la tabla actual (alinea columnas)
	{
		"tadmccorkle/markdown.nvim",
		ft = "markdown",
		opts = {},
	},

	-- ─── 5. Navegación de links internos en Markdown ────────────────────────
	-- Enter sigue el link bajo el cursor: URLs externas al browser, archivos relativos en nvim
	-- Soporta: paths absolutos, relativos, ~/path, file.md#heading, [ref][label], <url>
	-- <BS> vuelve al archivo anterior (edit #)
	{
		"jghauser/follow-md-links.nvim",
		ft = "markdown",
	},
}
