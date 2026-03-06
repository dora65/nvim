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
			require("render-markdown").setup(opts)
		end,
		opts = {
			-- Desactivado por defecto: el archivo abre en Raw
			-- <leader>mr cicla: Raw -> Hybrid -> Rendered
			enabled = false,
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
				sign = true,
				style = "full",
				icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
				left_pad = 1,
				right_pad = 1,
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
				sign = true,
				style = "full",
				border = "thin",
				width = "full",
				min_width = 45,
				left_pad = 2,
				right_pad = 2,
				language_pad = 1,
			},
			pipe_table = {
				enabled = true,
				style = "full",
				cell = "padded",
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
			quote = { enabled = true, icon = "▋" },
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
						{ level = 0, cursor = "", rm = false, label = "Raw — sintaxis visible" },
						{ level = 2, cursor = "", rm = true, label = "Hybrid — render + cursor raw" },
						{ level = 2, cursor = "ncv", rm = true, label = "Rendered — 100% renderizado" },
					}
					local idx = vim.b.md_view_state or 1
					idx = idx % #modes + 1
					vim.b.md_view_state = idx
					local m = modes[idx]
					vim.opt_local.conceallevel = m.level
					vim.opt_local.concealcursor = m.cursor
					local rm = require("render-markdown")
					if m.rm then
						rm.enable()
					else
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

	-- ─── 4. Navegación de links internos en Markdown ────────────────────────
	-- Enter sigue el link bajo el cursor: URLs externas al browser, archivos relativos en nvim
	-- Soporta: paths absolutos, relativos, ~/path, file.md#heading, [ref][label], <url>
	-- <BS> vuelve al archivo anterior (edit #)
	{
		"jghauser/follow-md-links.nvim",
		ft = "markdown",
	},
}
