-- ── Búsqueda y Reemplazo ─────────────────────────────────────────────────────
--
-- SEARCH IN FILE (equivalente VSCode Ctrl+F):
--   <C-f>      → SearchBox flotante top-right, resalta TODOS los matches en tiempo real
--              → dentro del box: Tab/<S-Tab> o F3/<S-F3> para siguiente/anterior
--              → <C-f> o <Esc> cierra el box
--
-- REPLACE IN FILE (equivalente VSCode Ctrl+H):
--   <leader>sR → Grug FAR en archivo actual (regex completo + preview visual)
--
-- REPLACE MULTI-FILE (equivalente VSCode Ctrl+Shift+H):
--   <leader>sr → Grug FAR en todo el proyecto (LazyVim default)
--
-- FLASH / JUMP (técnica nvim experta):
--   /texto  → flash labels (a,b,c…) sobre cada match → letra = salto directo
--   cgn     → cambiar primer match → . repite en siguiente (1 tecla por match)
--
-- SEARCH COUNTER:
--   n / N   → siguiente/anterior + contador [2/8] centrado (hlslens)
--   * / #   → buscar palabra bajo cursor

return {
	-- ── 0. Grug FAR: replace avanzado ───────────────────────────────────────
	-- <leader>sr  → reemplazar en TODO el proyecto (LazyVim default)
	-- <leader>sR  → reemplazar en archivo actual (pre-rellena palabra bajo cursor)
	-- visual + <leader>sR → reemplazar selección en archivo actual
	-- <leader>sw  → reemplazar palabra bajo cursor en TODO el proyecto
	-- Dentro del panel: <CR>=aplicar, q=cerrar, <C-r>=refrescar, <C-q>=qflist
	{
		"MagicDuck/grug-far.nvim",
		opts = {
			headerMaxWidth = 80,
			windowCreationCommand = "vsplit",
			-- Keymaps dentro del panel (intuitivos)
			keymaps = {
				replace = { n = "<CR>" }, -- Enter = aplicar reemplazos
				close = { n = "q" }, -- q = cerrar (como vim buffer)
				refresh = { n = "<C-r>" }, -- refrescar resultados
				qflist = { n = "<C-q>" }, -- mandar resultados a quickfix
				syncLocations = { n = "<C-s>" }, -- sync todos los archivos
				openLocation = { n = "o" }, -- abrir ubicación bajo cursor
				abort = { n = "<C-c>" }, -- cancelar búsqueda en curso
				historyOpen = { n = "<C-h>" }, -- historial de búsquedas
				toggleShowCommand = { n = "<C-p>" }, -- ver comando ripgrep generado
			},
			-- Spinner visual mientras ripgrep busca
			spinnerStates = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
		},
		keys = {
			-- Normal: pre-rellena la palabra bajo cursor + restringe al archivo
			{
				"<leader>sR",
				function()
					require("grug-far").open({
						prefills = {
							search = vim.fn.expand("<cword>"),
							paths = vim.fn.expand("%"),
						},
					})
				end,
				mode = "n",
				desc = "Replace word under cursor (current file)",
			},
			-- Visual: pre-rellena la selección + restringe al archivo
			{
				"<leader>sR",
				function()
					require("grug-far").open({
						prefills = { paths = vim.fn.expand("%") },
					})
				end,
				mode = "v",
				desc = "Replace selection (current file)",
			},
			-- Bonus: reemplazar palabra bajo cursor en TODO el proyecto
			{
				"<leader>sw",
				function()
					require("grug-far").open({
						prefills = { search = vim.fn.expand("<cword>") },
					})
				end,
				mode = "n",
				desc = "Replace word under cursor (project)",
			},
		},
	},

	-- ── 1. Flash.nvim: labels sobre matches durante / ────────────────────────
	{
		"folke/flash.nvim",
		opts = {
			search = { enabled = true },
			label = {
				uppercase = false,
				rainbow = { enabled = false }, -- colores manuales catppuccin abajo
				after = true,
				before = false,
				style = "overlay",
				min_length = 1,
				reuse = "lowercase",
			},
			highlight = {
				backdrop = true, -- backdrop en modo s/S jump
				matches = true,
				priority = 5000,
			},
			modes = {
				search = {
					enabled = true,
					-- SIN backdrop en search: el cursor de la cmdline queda visible
					highlight = { backdrop = false },
					jump = { history = true, register = true, nohlsearch = true },
				},
				char = {
					enabled = true,
					jump_labels = true,
					label = { exclude = "hjkliardc" },
					keys = { "f", "F", "t", "T", ";", "," },
				},
			},
		},
		-- Colores catppuccin mocha: consistentes con el tema
		config = function(_, opts)
			require("flash").setup(opts)
			local function set_hl()
				-- Backdrop: oscurece sin matar el contexto
				vim.api.nvim_set_hl(0, "FlashBackdrop", { fg = "#585b70" })
				-- Label: mauve brillante sobre fondo oscuro → muy legible
				vim.api.nvim_set_hl(0, "FlashLabel", { bg = "#cba6f7", fg = "#1e1e2e", bold = true })
				-- Match: todos los resultados en superficie resaltada
				vim.api.nvim_set_hl(0, "FlashMatch", { bg = "#313244", fg = "#cdd6f4" })
				-- Current: verde para el match activo/seleccionado
				vim.api.nvim_set_hl(0, "FlashCurrent", { bg = "#a6e3a1", fg = "#1e1e2e", bold = true })
			end
			set_hl()
			-- Reaplicar tras cambio de colorscheme
			vim.api.nvim_create_autocmd("ColorScheme", { pattern = "*", callback = set_hl })
		end,
	},

	-- ── 2. nvim-hlslens: contador [actual/total] al navegar con n/N ──────────
	{
		"kevinhwang91/nvim-hlslens",
		event = "BufReadPost",
		config = function()
			require("hlslens").setup({
				calm_down = true,
				nearest_only = true,
				nearest_float_when = "always",
			})

			local o = { noremap = true, silent = true }
			-- n/N + centra cursor automáticamente (zz)
			vim.keymap.set(
				"n",
				"n",
				[[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>zz]],
				o
			)
			vim.keymap.set(
				"n",
				"N",
				[[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>zz]],
				o
			)
			vim.keymap.set("n", "*", [[*<Cmd>lua require('hlslens').start()<CR>]], o)
			vim.keymap.set("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], o)
			vim.keymap.set("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], o)
			vim.keymap.set("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], o)
			-- <Esc> NO se mapea aquí: lo maneja keymaps.lua con lógica smart (nohlsearch + Noice dismiss + close float)
			-- Mapear <Esc> en hlslens sobreescribe el handler global en BufReadPost, rompiendo todo.
		end,
	},
}
