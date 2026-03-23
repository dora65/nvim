-- ─── nvim-bqf — Quickfix UI premium: preview flotante + fuzzy filter ─────────
-- El quickfix nativo es una lista plana sin contexto visual.
-- Cuando grug-far envía resultados al quickfix, navegar es ciego.
--
-- nvim-bqf añade sin configuración adicional:
--   p         → toggle preview flotante del resultado bajo el cursor
--   zf        → fuzzy filter de la lista con fzf-lua (ya instalado)
--   <Tab>/<S-Tab> → marcar múltiples entradas para acción en lote
--   za        → toggle auto-preview (preview sigue al cursor)
--
-- Zero-config: funciona out-of-the-box. Drop-in sobre quickfix nativo.
return {
	{
		"kevinhwang91/nvim-bqf",
		ft = "qf",   -- carga solo cuando se abre el quickfix (ft = "qf")
		opts = {
			-- auto_enable: activar automáticamente en el quickfix window
			auto_enable = true,

			-- auto_resize_height: adaptar alto del preview al contenido
			auto_resize_height = true,

			-- Preview: float a la derecha del quickfix
			-- winblend 12: coordina con pumblend de options.lua
			preview = {
				win_height        = 12,
				win_vheight       = 12,
				delay_syntax      = 80,
				border            = "rounded",
				winblend          = 12,
				-- show_title: muestra el path del buffer en el preview
				show_title        = true,
				-- should_preview_cb: no hacer preview de filetypes masivos
				should_preview_cb = function(bufnr, _)
					local ft = vim.bo[bufnr].filetype
					local skip = { "bin", "so", "exe", "dll", "a", "lib" }
					for _, s in ipairs(skip) do
						if ft == s then return false end
					end
					return true
				end,
			},

			-- func_map: keymaps dentro del quickfix
			-- Mantener defaults de bqf + solo ajustar conflictos con tu config
			func_map = {
				open        = "<CR>",
				openc       = "o",
				tab         = "t",
				tabb        = "T",
				tabc        = "<C-t>",
				split       = "<C-s>",
				vsplit      = "<C-v>",
				prevfile    = "<C-p>",
				nextfile    = "<C-n>",
				prevhist    = "<",
				nexthist    = ">",
				lastleave   = "'\"",
				stoggleup   = "<S-Tab>",
				stoggledown = "<Tab>",
				stogglevm   = "<Tab>",
				stogglebuf  = "'<Tab>",
				sclear      = "z<Tab>",
				filter      = "zn",
				filterr     = "zN",
				fzffilter   = "zf",   -- fuzzy filter con fzf-lua
				ptogglemode = "zp",
				ptoggleitem = "p",
				ptoggleauto = "P",
				pscrollup   = "<C-b>",
				pscrolldown = "<C-f>",
				pscrollorig = "zo",
			},

			-- filter: integración con fzf-lua (ya instalado — ibhagwan/fzf-lua)
			filter = {
				fzf = {
					action_for = {
						["ctrl-t"] = "tabedit",
						["ctrl-v"] = "vsplit",
						["ctrl-x"] = "split",
						["ctrl-q"] = "signtoggle",
						["ctrl-c"] = "closeall",
					},
					extra_opts = { "--bind", "ctrl-o:toggle-all", "--prompt", "BQF> " },
				},
			},
		},
	},
}
