-- yazi.nvim — terminal file manager integrado (github.com/mikavilpas/yazi.nvim)
-- WezTerm tiene enable_kitty_graphics = true → preview de imágenes funciona nativamente
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │  PDF + IMAGEN PREVIEW  (configurar en yazi, no en nvim)                  │
-- │                                                                          │
-- │  Imágenes JPEG/PNG/WEBP: FUNCIONAN YA — WezTerm + kitty protocol        │
-- │                                                                          │
-- │  PDF inline (requiere poppler):                                          │
-- │    1. scoop install poppler          (provee pdftoppm)                   │
-- │    2. ~/.config/yazi/init.lua:                                           │
-- │         require("pdf"):setup({ render_cmd = "pdftoppm" })               │
-- │    3. ~/.config/yazi/yazi.toml:                                          │
-- │         [[plugin.prepend_previewers]]                                    │
-- │         mime = "application/pdf"                                         │
-- │         run  = "pdf"                                                     │
-- │    Más plugins: https://yazi-rs.github.io/docs/resources                │
-- └──────────────────────────────────────────────────────────────────────────┘

return {
	{
		"mikavilpas/yazi.nvim",
		event = "VeryLazy",
		dependencies = { "folke/snacks.nvim" },
		keys = {
			-- Abre en el dir del archivo actual, cursor posicionado sobre ese archivo
			{
				"<leader>fy",
				mode = { "n", "v" },
				"<cmd>Yazi<cr>",
				desc = "Yazi (current file)",
			},
			-- Abre desde el CWD del proyecto (útil como project-switcher)
			{
				"<leader>fY",
				"<cmd>Yazi cwd<cr>",
				desc = "Yazi (cwd)",
			},
			-- Retoma la última sesión: misma ruta, misma posición del cursor en yazi
			{
				"<leader>fz",
				"<cmd>Yazi toggle<cr>",
				desc = "Yazi (resume last)",
			},
		},

		---@type YaziConfig | {}
		opts = {
			-- ── Integración con el sistema ───────────────────────────────────────
			-- Reemplaza netrw al abrir directorios (`nvim .`, `nvim /ruta`)
			open_for_directories = true,

			-- ┌─ PREMIUM ─────────────────────────────────────────────────────────
			-- │ Los splits/tabs visibles de nvim se convierten en TABS de yazi.
			-- │ Si tienes 3 splits abiertos → yazi los muestra como 3 tabs propios.
			-- │ <Tab> dentro de yazi navega entre ellos. Cierra un tab = cierra split.
			-- │ Workflow: editas → abres yazi → navegas → vuelves al split exacto.
			-- └───────────────────────────────────────────────────────────────────
			open_multiple_tabs = true,

			-- ┌─ PREMIUM ─────────────────────────────────────────────────────────
			-- │ Mientras navegas en yazi, los buffers nvim en el MISMO directorio
			-- │ que el archivo bajo el cursor se resaltan suavemente en nvim.
			-- │ Contexto visual instantáneo: ves qué tienes abierto sin salir.
			-- └───────────────────────────────────────────────────────────────────
			highlight_hovered_buffers_in_same_directory = true,

			-- <c-y> dentro de yazi copia la ruta al portapapeles del sistema ("+")
			clipboard_register = "+",

			-- false: nvim mantiene su CWD original al cerrar yazi
			-- true : nvim adopta el directorio donde cerraste yazi
			--        Útil si usas yazi como project-switcher entre repos distintos.
			change_neovim_cwd_on_close = false,

			-- ── Keymaps dentro de yazi → controlan nvim sin salir ───────────────
			keymaps = {
				show_help = "<f1>",
				open_file_in_vertical_split = "<c-v>",
				open_file_in_horizontal_split = "<c-s>",
				open_file_in_tab = "<c-t>",
				-- Live grep (snacks) restringido al directorio ACTUAL de yazi
				grep_in_directory = "<c-g>",
				-- grug-far: find & replace restringido al directorio ACTUAL de yazi
				replace_in_directory = "<c-r>",
				-- Cicla entre los buffers nvim abiertos (sin salir de yazi)
				cycle_open_buffers = "<tab>",
				-- Copia la ruta relativa del archivo/selección al portapapeles
				copy_relative_path_to_selected_files = "<c-y>",
				-- Selección múltiple (<Space> en cada archivo) → quickfix de nvim
				send_to_quickfix_list = "<c-q>",
			},

			-- ┌─ PREMIUM: Multi-selección → UI de apertura ───────────────────────
			-- │ En yazi: marca archivos con <Space>, luego <Enter>
			-- │ → Dialog para elegir Tabs / Vsplits / Splits / Quickfix
			-- │ Sin este hook el default es enviar todo al quickfix directamente.
			-- └───────────────────────────────────────────────────────────────────
			yazi_opened_multiple_files = function(chosen_files, _config, _state)
				if not chosen_files or #chosen_files == 0 then
					return
				end
				vim.schedule(function()
					local n = #chosen_files
					local choice = vim.fn.confirm(
						string.format("Abrir %d archivos en:", n),
						"&Tabs\n&Vsplits\n&Splits\n&Quickfix\nC&ancelar",
						1
					)
					if choice == 1 then
						for _, f in ipairs(chosen_files) do
							vim.cmd("tabedit " .. vim.fn.fnameescape(tostring(f)))
						end
					elseif choice == 2 then
						for i, f in ipairs(chosen_files) do
							vim.cmd((i == 1 and "edit " or "vsplit ") .. vim.fn.fnameescape(tostring(f)))
						end
					elseif choice == 3 then
						for i, f in ipairs(chosen_files) do
							vim.cmd((i == 1 and "edit " or "split ") .. vim.fn.fnameescape(tostring(f)))
						end
					elseif choice == 4 then
						local qf = vim.tbl_map(function(f)
							return { filename = tostring(f), lnum = 1 }
						end, chosen_files)
						vim.fn.setqflist(qf, "r")
						vim.cmd("copen")
					end
				end)
			end,

			-- ── Ventana flotante ─────────────────────────────────────────────────
			floating_window_scaling_factor = 0.90,
			yazi_floating_window_border = "rounded",

			-- ── Highlights ───────────────────────────────────────────────────────
			highlight_groups = {
				-- Archivo bajo el cursor en yazi → resaltado como item seleccionado de menú
				hovered_buffer = { link = "PmenuSel" },
			},
		},
	},
}
