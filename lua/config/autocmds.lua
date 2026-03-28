-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- FileChangedShell: cuando nvim detecta que el disco cambió → recargar sin preguntar
-- Cubre el caso que autoread no alcanza: archivo cambia MIENTRAS el buffer está activo
-- (ej: Claude Code edita el archivo y el usuario guarda inmediatamente después)
vim.api.nvim_create_autocmd("FileChangedShell", {
	pattern = "*",
	callback = function() vim.v.fcs_choice = "reload" end,
	desc = "Auto-reload when file changes on disk (no prompt)",
})

-- SwapExists: auto-eliminar archivos .swp residuales sin preguntar
-- swapfile=false previene nuevos, esto limpia los existentes silenciosamente.
-- 'd' = delete swap + edit: nunca más el dialog de "recuperar versión anterior"
vim.api.nvim_create_autocmd("SwapExists", {
	pattern = "*",
	callback = function() vim.v.swapchoice = "d" end,
	desc = "Auto-delete residual swap files (swapfile=false + undofile=true as replacement)",
})

-- Desactivar globalmente spell check para todos los tipos de archivos
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "FileType" }, {
	pattern = "*",
	callback = function()
		vim.opt_local.spell = false
	end,
	desc = "Desactivar corrección ortográfica para todos los archivos",
})

-- Desactivar los plugins ALE o Syntastic si están interfiriendo con spell check
vim.g.ale_enabled = 0
vim.g.syntastic_check_on_open = 0
vim.g.syntastic_check_on_wq = 0

-- Función para crear grupos de autocomandos
local function augroup(name)
	return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

-- Markdown: experiencia visual óptima
-- Modos de vista controlados con <leader>mr (Raw → Hybrid → Rendered)
-- Estado inicial: Rendered (índice 3) → render completo, wrap=false, scroll libre
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	group = augroup("markdown_ux"),
	callback = function()
		-- Sin swap file en markdown: evita el dialogo multi-swap al abrir .md
		-- (los .md estan en git → crash recovery es redundante aqui)
		vim.opt_local.swapfile = false
		-- Rendered por defecto (estado 3): render activo al abrir, wrap=false, scroll libre
		-- <leader>mr cicla: Raw(1) -> Hybrid(2) -> Rendered(3)
		vim.opt_local.conceallevel = 2
		vim.opt_local.concealcursor = "ncv"
		vim.b.md_view_state = 3
		-- wrap=false: tablas en una sola línea, scroll horizontal libre
		-- Rendering funciona con leftcol=0; al scrollear derecha extmarks quedan fuera (nvim#14050)
		vim.opt_local.wrap = false
		vim.opt_local.textwidth = 0
		vim.opt_local.sidescroll = 1
		vim.opt_local.sidescrolloff = 5
		-- Folds: ufo con treesitter+indent (pcall en markdown.lua previene race condition)
		vim.opt_local.foldenable = true
		vim.opt_local.foldlevel = 99
		vim.opt_local.foldcolumn = "0"  -- ufo usa virt-text (▸ N), no columna visual

		-- <C-LeftMouse> y gx: manejados globalmente en keymaps.lua (sin timing issues).
		-- <C-]>: buffer-local en markdown — redirige a gx para evitar E426.
		--   Ctrl+] no tiene uso real en markdown (tags = C), lo mandamos a gx.
		vim.keymap.set(
			"n",
			"<C-]>",
			"gx",
			{ buffer = true, silent = true, remap = true, desc = "Open URL / redirect from tag lookup" }
		)

		-- Full-document render desde el arranque (modo Rendered = estado 3)
		vim.b.rm_render_full = true

		-- Auto-toggle: Insert=raw markdown (editar cómodo), Normal=100% renderizado
		-- InsertEnter: apaga render + conceallevel=0 (sintaxis visible para editar)
		-- InsertLeave: reactiva render completo + conceal total (lectura limpia)
		-- {clear=false}: buffer-local, auto-delete al cerrar buffer
		local _md_tog = vim.api.nvim_create_augroup("MarkdownInsertToggle", { clear = false })
		local buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_create_autocmd("InsertEnter", {
			buffer = buf,
			group = _md_tog,
			callback = function()
				vim.b.rm_render_full = nil
				pcall(function() require("render-markdown").disable() end)
				vim.opt_local.conceallevel = 0
			end,
		})
		vim.api.nvim_create_autocmd("InsertLeave", {
			buffer = buf,
			group = _md_tog,
			callback = function()
				vim.b.rm_render_full = true
				pcall(function() require("render-markdown").enable() end)
				vim.opt_local.conceallevel = 2
				vim.opt_local.concealcursor = "ncv"
			end,
		})

	end,
})

-- ── Focus visual: resaltar ventana activa, atenuar inactivas ──────────────
-- Cambia el separador de ventana al entrar/salir para feedback visual
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
	group = augroup("active_win_highlight"),
	callback = function()
		-- Ventana activa: cursorline visible, números brillantes
		vim.opt_local.cursorline = true
		vim.opt_local.winhighlight = ""
	end,
})

-- ── Restaurar números de línea para buffers normales ───────────────────────
-- El callback de neo-tree desactiva número en la ventana vacía inicial.
-- Al abrir un archivo real en esa ventana, los wo quedan en false → fix aquí.
vim.api.nvim_create_autocmd("BufWinEnter", {
	group = augroup("restore_line_numbers"),
	callback = function(args)
		local buf = args.buf
		local bt = vim.bo[buf].buftype
		local ft = vim.bo[buf].filetype
		local name = vim.api.nvim_buf_get_name(buf)
		-- Solo buffers normales con nombre real (no neo-tree, terminal, nofile, etc.)
		if bt == "" and ft ~= "neo-tree" and name ~= "" then
			vim.wo.number = true
			vim.wo.relativenumber = true
			vim.wo.signcolumn = "yes"
			vim.wo.foldcolumn = "1"
		end
	end,
})

vim.api.nvim_create_autocmd("WinLeave", {
	group = augroup("inactive_win_highlight"),
	callback = function()
		-- Ventana inactiva: sin cursorline, fondo atenuado
		vim.opt_local.cursorline = false
	end,
})

-- ─── Auto-ocultar terminales flotantes al perder el foco ────────────────────
-- WinLeave dispara cuando el foco SALE de la ventana (no cuando entra).
-- → Sin loop: WinLeave de Claude solo dispara al abandonar Claude, nunca al abrirlo.
-- vim.schedule evita reentrancia. nvim_win_is_valid evita errores si ya fue cerrado.
vim.api.nvim_create_autocmd("WinLeave", {
	group = augroup("float_term_autohide"),
	callback = function()
		local win = vim.api.nvim_get_current_win()
		local buf = vim.api.nvim_win_get_buf(win)
		local cfg = vim.api.nvim_win_get_config(win)
		if cfg.relative == "" or vim.bo[buf].buftype ~= "terminal" then return end

		local name = vim.api.nvim_buf_get_name(buf)
		vim.schedule(function()
			if not vim.api.nvim_win_is_valid(win) then return end
			if name:find("claude", 1, true) then
				-- Claude: ocultar (proceso vivo). Complementa on_blur de snacks.
				pcall(vim.api.nvim_win_hide, win)
			else
				-- Otras terminales flotantes (toggleterm): cerrar
				pcall(vim.api.nvim_win_close, win, false)
			end
		end)
	end,
})

-- Restaurar cursor de terminal al salir de nvim (DECSCUSR escape sequence)
-- \x1b[5 q = blinking bar (coincide con WezTerm BlinkingBar)
-- vim.opt.guicursor no funciona en VimLeave porque nvim ya cerró el TUI
vim.api.nvim_create_autocmd("VimLeave", {
	group = augroup("restore_cursor"),
	callback = function()
		io.stdout:write("\x1b[5 q")
	end,
})

-- Nota: el VimEnter para el startup con Oil esta en neo-tree.lua (init function)
-- porque autocmds.lua se carga en VeryLazy (despues de VimEnter)

-- Guardar último cwd al salir → WezTerm lo restaura en gui-startup
vim.api.nvim_create_autocmd("VimLeave", {
	group = augroup("save_last_cwd"),
	callback = function()
		local cwd = vim.uv.cwd()
		if not cwd then
			return
		end
		local path = vim.fn.expand("~") .. "\\.nvim_last_cwd"
		local f = io.open(path, "w")
		if f then
			f:write(cwd)
			f:close()
		end
	end,
})

-- Windows specific autocmds
if vim.fn.has("win32") == 1 then
	-- Fix line endings when writing files on Windows
	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = "*",
		callback = function()
			vim.opt.fileformat = "unix"
		end,
		group = augroup("fix_line_endings"),
	})

	-- Set file encodings appropriate for Windows
	vim.api.nvim_create_autocmd("BufReadPre", {
		pattern = "*",
		callback = function()
			vim.opt.fileencoding = "utf-8"
		end,
		group = augroup("file_encodings"),
	})
end

-- ─── UI/UX: Subrayar URLs para reconocer links clickeables al instante ──────
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
	group = augroup("highlight_urls"),
	desc = "Subrayar URLs para diferenciarlos visualmente",
	callback = function()
		vim.cmd([[highlight default link UnderlinedURL Underlined]])
		-- Limpiar si el window ya tenía el match para evitar duplicados
		pcall(vim.fn.matchdelete, vim.w.url_match_id or -1)
		-- Regex \v (very magic) rápida para vim -> subraya URLs
		vim.w.url_match_id = vim.fn.matchadd("UnderlinedURL", "\\vhttps?://[^\\s\"'<>()\\[\\]{}]+")
	end,
})

-- ─── Sincronizar tema con WezTerm ────────────────────────────────────────────
-- Escribe ~/.nvim_theme al iniciar y al cambiar colorscheme.
-- WezTerm observa ese archivo (wezterm.watch_config_file) y recarga automático.
local function write_nvim_theme()
	local theme = vim.g.colors_name or "sonokai"
	local path = vim.fn.expand("~") .. "\\.nvim_theme"
	local f = io.open(path, "w")
	if f then
		f:write(theme)
		f:close()
	end
end

vim.api.nvim_create_autocmd("VimEnter", {
	group = augroup("sync_theme_init"),
	once = true,
	callback = write_nvim_theme, -- escribe el tema activo al iniciar
})

vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	group = augroup("sync_theme_wezterm"),
	callback = write_nvim_theme, -- actualiza al cambiar tema
})

-- ─── Gentleman Kanagawa Blur: nvim-web-devicons + post-load overrides ────────
-- El plugin aplica sus highlights en setup(), pero devicons necesita ser
-- re-llamado DESPUÉS porque es externo al sistema de integraciones del tema.
-- También forzamos NormalNC/Normal = NONE para garantizar la transparencia blur.
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "gentleman-kanagawa-blur",
	group = augroup("kanagawa_blur_overrides"),
	callback = function()
		-- Alias corto: permite :colorscheme kanagawa y referencias cs:find("kanagawa")
		vim.g.colors_name = "kanagawa"
		-- nvim-web-devicons: paleta Gentleman Kanagawa Blur por extensión
		local ok, devicons = pcall(require, "nvim-web-devicons")
		if ok then
			devicons.setup({
				override_by_extension = {
					lua       = { icon = "󰢱", color = "#7AA89F", name = "Lua" },
					py        = { icon = "󰌠", color = "#B7CC85", name = "Python" },
					rb        = { icon = "󰴭", color = "#CB7C94", name = "Ruby" },
					php       = { icon = "󰌟", color = "#A3B5D6", name = "PHP" },
					js        = { icon = "󰌞", color = "#FFE066", name = "Javascript" },
					ts        = { icon = "󰛦", color = "#7FB4CA", name = "Typescript" },
					jsx       = { icon = "󰜈", color = "#7FB4CA", name = "JSX" },
					tsx       = { icon = "󰜈", color = "#7FB4CA", name = "TSX" },
					vue       = { icon = "󰡄", color = "#B7CC85", name = "Vue" },
					svelte    = { icon = "",  color = "#DEBA87", name = "Svelte" },
					css       = { icon = "󰌜", color = "#7AA89F", name = "CSS" },
					scss      = { icon = "󰌜", color = "#A3B5D6", name = "SCSS" },
					html      = { icon = "󰌝", color = "#DEBA87", name = "HTML" },
					json      = { icon = "󰘦", color = "#FFE066", name = "JSON" },
					yaml      = { icon = "󰬻", color = "#DEBA87", name = "YAML" },
					yml       = { icon = "󰬻", color = "#DEBA87", name = "YAML" },
					toml      = { icon = "",  color = "#DEBA87", name = "TOML" },
					xml       = { icon = "󰗀", color = "#DEBA87", name = "XML" },
					rs        = { icon = "󰙱", color = "#DEBA87", name = "Rust" },
					go        = { icon = "󰟓", color = "#7FB4CA", name = "Go" },
					cs        = { icon = "󰌛", color = "#A3B5D6", name = "Csharp" },
					java      = { icon = "󰬷", color = "#DEBA87", name = "Java" },
					kt        = { icon = "󱈙", color = "#A3B5D6", name = "Kotlin" },
					sh        = { icon = "",  color = "#B7CC85", name = "Shell" },
					bash      = { icon = "",  color = "#B7CC85", name = "Bash" },
					ps1       = { icon = "󰨊", color = "#7FB4CA", name = "PowerShell" },
					vim       = { icon = "",  color = "#B7CC85", name = "Vim" },
					md        = { icon = "󰍔", color = "#8394A3", name = "Markdown" },
					mdx       = { icon = "󰍔", color = "#7AA89F", name = "MDX" },
					txt       = { icon = "󰊄", color = "#8394A3", name = "Text" },
					sql       = { icon = "󰆼", color = "#7AA89F", name = "SQL" },
					http      = { icon = "󰌤", color = "#B7CC85", name = "HTTP" },
					env       = { icon = "",  color = "#FFE066", name = "Env" },
					lock      = { icon = "󰌾", color = "#5C6170", name = "Lock" },
					png       = { icon = "󰋩", color = "#A3B5D6", name = "PNG" },
					jpg       = { icon = "󰋩", color = "#A3B5D6", name = "JPEG" },
					jpeg      = { icon = "󰋩", color = "#A3B5D6", name = "JPEG" },
					gif       = { icon = "󰋩", color = "#A3B5D6", name = "GIF" },
					svg       = { icon = "󰜡", color = "#CB7C94", name = "SVG" },
					tf        = { icon = "󱁢", color = "#A3B5D6", name = "Terraform" },
					dockerfile= { icon = "󰡨", color = "#7FB4CA", name = "Dockerfile" },
				},
			})
		end

	-- ── Paleta Gentleman Kanagawa ────────────────────────────────────────────
	local t   = "NONE"
	local K = {
		none     = "NONE",
		bg       = "#1e1f1c",     -- editor bg (warm olive, ref monokai.jsonc)
		bg_panel = "#1A1F28",     -- NeoTree sidebar (panel hierarchy)
		bg_cur   = "#252D3A",     -- popup/menu bg (Pmenu, completion)
		brd      = "#2A3140",     -- borders: muted
		fg       = "#F3F6F9",     -- texto primario
		fd       = "#C5CAD6",     -- texto secundario (7.8:1)
		fg_cmt   = "#8394A3",     -- UI dim text (5.6:1)
		acc      = "#E0C15A",     -- gold accent: solo títulos focalizados
		type_    = "#66d9ef",     -- tipos/builtins (cyan ST3)
		green_   = "#76946A",     -- git added (springGreen muted)
		amber_   = "#C0A36E",     -- git modified (carpYellow)
		teal_    = "#6A9589",     -- git untracked (waveAqua)
		red_     = "#C34043",     -- errores/delete
	}
	local hl = function(name, opts) vim.api.nvim_set_hl(0, name, opts) end

	-- ── Transparencia + floats: NONE = blur (WezTerm bg visible) ─────────────
	hl("NormalFloat", { bg = K.none })
	hl("FloatBorder", { fg = K.brd, bg = K.none })
	hl("FloatTitle",  { fg = K.acc, bg = K.none, bold = true })
	hl("FloatFooter", { fg = K.fg_cmt, bg = K.none })

	-- ── Borders: muted ────────────────────────────────────────────────────────
	hl("TelescopeBorder",            { fg = K.brd })
	hl("TelescopePromptBorder",      { fg = K.acc })
	hl("TelescopeResultsBorder",     { fg = K.brd })
	hl("TelescopePreviewBorder",     { fg = K.brd })
	hl("ToggleTermBorder",           { fg = K.brd })
	hl("SnacksBorder",               { fg = K.brd })
	hl("SnacksPickerBorder",         { fg = K.brd })
	hl("SnacksNotifyBorder",         { fg = K.brd })
	hl("WhichKeyBorder",             { fg = K.brd })
	hl("LspInfoBorder",              { fg = K.brd })
	hl("BlinkCmpMenuBorder",         { fg = K.brd, bg = K.none })
	hl("BlinkCmpDocBorder",          { fg = K.brd, bg = K.none })
	hl("BlinkCmpSignatureHelpBorder",{ fg = K.brd, bg = K.none })
	hl("ClaudeCodeBorder",           { fg = K.brd })
	hl("MasonBorder",                { fg = K.brd })

	-- ── Incline (filename float top-right) ────────────────────────────────────
	hl("InclineNormal",              { bg = K.none, fg = K.fg })
	hl("InclineNormalNC",            { bg = K.none, fg = K.fg_cmt })

	-- ── FzfLua ───────────────────────────────────────────────────────────────
	hl("FzfLuaBorder",               { fg = K.brd, bg = K.none })
	hl("FzfLuaNormal",               { bg = K.none })

	-- ── Grug-far ─────────────────────────────────────────────────────────────
	hl("GrugFarBorder",              { fg = K.brd })

	-- ── nvim-dbee ────────────────────────────────────────────────────────────
	hl("DbeeNormal",                 { bg = K.none, fg = K.fg })
	hl("DbeeBorder",                 { fg = K.brd, bg = K.none })
	hl("DbeeTitle",                  { fg = K.acc, bg = K.none, bold = true })

	-- ── Mini.files ───────────────────────────────────────────────────────────
	hl("MiniFilesNormal",            { bg = K.none, fg = K.fg })
	hl("MiniFilesBorder",            { fg = K.brd, bg = K.none })
	hl("MiniFilesTitleFocused",      { fg = K.acc, bg = K.none, bold = true })

	-- ── Pmenu (monokai: editorSuggestWidget.background = editor bg) ──────────
	hl("Pmenu",      { bg = K.bg, fg = K.fd })
	hl("PmenuSel",   { bg = "#1E2A3A",  fg = K.fg, bold = true })
	hl("PmenuSbar",  { bg = K.bg_cur })
	hl("PmenuThumb", { bg = K.fg_cmt })

	-- ── Neo-tree ──────────────────────────────────────────────────────────────
	hl("NeoTreeNormal",         { bg = K.bg_panel, fg = K.fg })
	hl("NeoTreeNormalNC",       { bg = K.bg_panel, fg = K.fg_cmt })
	hl("NeoTreeWinSeparator",   { fg = K.brd, bg = K.bg_panel })
	hl("NeoTreeEndOfBuffer",    { bg = K.bg_panel, fg = K.bg_panel })
	-- bg_cur "#252D3A" sobre bg_panel "#1A1F28" = 1.4:1 contraste (invisible)
	-- Fix: "#273D54" — blue accent +35% luminance → contraste 2.8:1 (claramente visible)
	hl("NeoTreeCursorLine",     { bg = "#1E4A7A" })  -- deep blue: ~3.2:1 vs #1A1F28
	hl("NeoTreeDimText",        { fg = K.fg_cmt })
	hl("NeoTreeIndentMarker",   { fg = K.brd })
	hl("NeoTreeExpander",       { fg = K.fg_cmt })
	hl("NeoTreeGitAdded",       { fg = K.green_ })
	hl("NeoTreeGitModified",    { fg = K.amber_ })
	hl("NeoTreeGitDeleted",     { fg = K.red_ })
	hl("NeoTreeGitUntracked",   { fg = K.teal_, italic = true })
	hl("NeoTreeGitIgnored",     { fg = K.fg_cmt })
	hl("NeoTreeGitStaged",      { fg = K.green_, bold = true })
	hl("NeoTreeGitConflict",    { fg = K.red_,   bold = true })
	hl("NeoTreeModified",       { fg = K.amber_ })
	hl("NeoTreeDirectoryIcon",  { fg = K.fg_cmt })
	hl("NeoTreeDirectoryName",  { fg = K.fg })
	hl("NeoTreeRootName",       { fg = K.acc, bold = true, italic = true })
	hl("NeoTreeFileName",       { fg = K.fg })
	hl("NeoTreeFileNameOpened", { fg = K.acc, bold = true })

	-- ── DropBar (breadcrumbs winbar) ──────────────────────────────────────────
	-- WinBar/WinBarNC ya definidos arriba — dropbar los hereda
	-- MenuNormalFloat = mismo bg que popup (K.bg) para integración uniforme
	-- Paleta: blue=#7FB4CA, purple=#B99BF2, cyan/type=#66d9ef, teal=#6A9589, amber=#C0A36E, red=#C34043
	hl("DropBarIconUISeparator",  { fg = K.fg_cmt })
	hl("DropBarMenuNormalFloat",  { bg = K.bg,     fg = K.fg })
	hl("DropBarMenuFloatBorder",  { fg = K.brd,    bg = K.bg })
	hl("DropBarMenuHoverEntry",   { bg = K.bg_cur, fg = K.fg, bold = true })
	hl("DropBarMenuCurrentContext", { bg = "#2E3748", fg = K.fd })
	hl("DropBarKindFile",         { fg = "#7FB4CA" })
	hl("DropBarKindFolder",       { fg = K.fg_cmt })
	hl("DropBarKindFunction",     { fg = "#B99BF2" })
	hl("DropBarKindMethod",       { fg = "#B99BF2" })
	hl("DropBarKindClass",        { fg = K.type_ })
	hl("DropBarKindModule",       { fg = K.type_ })
	hl("DropBarKindInterface",    { fg = K.type_ })
	hl("DropBarKindVariable",     { fg = K.fg })
	hl("DropBarKindProperty",     { fg = K.teal_ })
	hl("DropBarKindField",        { fg = K.teal_ })
	hl("DropBarKindConstant",     { fg = K.amber_ })
	hl("DropBarKindEnum",         { fg = K.amber_ })
	hl("DropBarKindKeyword",      { fg = K.red_ })
	hl("DropBarKindString",       { fg = "#98BB6C" })

	-- ── nvim-bqf (quickfix premium) ───────────────────────────────────────────
	hl("BqfPreviewBorder",  { fg = K.brd,  bg = K.none })
	hl("BqfPreviewTitle",   { fg = K.acc,  bg = K.none, bold = true })
	hl("BqfPreviewRange",   { bg = K.selection or "#1E2A3A", bold = true })
	hl("BqfPreviewBufLabel",{ fg = K.acc,  italic = true })
	hl("BqfSign",           { fg = K.acc })

	-- ── Editor chrome: ref monokai.jsonc ──────────────────────────────────────
	-- lineHighlightBackground = "#3e3d32" (olive, armónico con bg #1e1f1c)
	-- editorLineNumber.foreground = "#75715e"
	-- editorLineNumber.activeForeground = "#c2c2bf"
	hl("CursorLine",   { bg = "#3e3d32" })
	hl("CursorLineNr", { fg = "#c2c2bf", bold = true })
	hl("LineNr",       { fg = "#75715e" })

	-- ── Syntax: comments y selección ref syntax.json + monokai.jsonc ──────────
	-- comment.line / comment.block = "#75715e" italic (olive, firma ST3)
	-- editor.selectionBackground = "#49483e" monokai → kanagawa usa waveBlue
	hl("Comment",      { fg = "#75715e", italic = true })
	hl("@comment",     { fg = "#75715e", italic = true })
	hl("SpecialComment", { fg = "#75715e", italic = true })

	-- ── StatusLine / WinBar: transparentes ───────────────────────────────────
	hl("StatusLine",   { bg = t })
	hl("StatusLineNC", { bg = t, fg = K.fg_cmt })
	hl("WinBar",       { bg = t, fg = K.fg })
	hl("WinBarNC",     { bg = t, fg = K.fg_cmt })

	-- ── Lualine: reconfigurar mid-session — badge philosophy ─────────────────
	vim.schedule(function()
		if not (vim.g.colors_name or ""):find("kanagawa") then return end
		local ok, ll = pcall(require, "lualine")
		if not ok then return end
		local s0    = "#1E2228"
		local fg_on = "#1e1f1c"   -- dark fg para colored mode pills
		local fg_   = "#F3F6F9"   -- light fg para b/c sections
		local fd_   = "#8394A3"   -- dim fg para c section
		local function sec(mode_bg)
			return {
				a = { fg = fg_on, bg = mode_bg, gui = "bold" },
				b = { fg = fg_,   bg = s0 },
				c = { fg = fd_,   bg = s0 },
			}
		end
		local theme = {
			normal   = sec("#7FB4CA"),  -- K.blue
			insert   = sec("#B7CC85"),  -- K.green
			visual   = sec("#E0C15A"),  -- K.accent gold
			replace  = sec("#CB7C94"),  -- K.red
			command  = sec("#DEBA87"),  -- K.orange
			terminal = sec("#66d9ef"),  -- K.cyan
			inactive = {
				a = { fg = fd_, bg = s0 },
				b = { fg = fd_, bg = s0 },
				c = { fg = fd_, bg = s0 },
			},
		}
		local ok2, cfg = pcall(ll.get_config)
		if ok2 and cfg then
			cfg.options = cfg.options or {}
			cfg.options.theme = theme
			cfg.options.section_separators   = { left = "", right = "" }
			cfg.options.component_separators = { left = "│", right = "│" }
			ll.setup(cfg)
		end
	end)
	end,
})
-- ─── Monokai Premium: paleta refinada — ref: monokai.jsonc (VS Code) ─────────
-- Background #1e1f1c: warm dark, consistent con ref monokai.jsonc
-- Acento UI: cyan #66d9ef (NO rojo — rojo solo para errores/keywords)
-- Filosofía: sutil como Catppuccin/Kanagawa, no agresivo
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "sonokai",
	group = augroup("sonokai_overrides"),
	callback = function()
		local t = "NONE"
		-- Paleta Monokai Premium — ref: monokai.jsonc
		local M = {
			-- ── Superficies (depth hierarchy) ─────────────────────────────────────────
			bg_deep  = "#1e1e1a",  -- deepest: TabLineFill, outer frames
			bg_panel = "#1b1c19",  -- persistent panels: NeoTree sidebar (ligeramente más oscuro)
			bg       = "#1e1f1c",  -- main editor — ref: monokai.jsonc editor.background
			bg_float = "#2e2d27",  -- elevated floats: Pmenu, NormalFloat
			bg_cur   = "#3e3d32",  -- cursor line, hover states
			bg_sel   = "#49483e",  -- selection: warm amber, DNA Monokai
			bg_brd   = "#49483e",  -- borde neutro (warm amber)
			-- ── Foreground hierarchy ──────────────────────────────────────────────────
			fg       = "#f8f8f2",  -- texto primario (warm white, Monokai signature)
			fg_dim   = "#cfcfca",  -- texto secundario (80% luminance)
			fg_cmt   = "#75715e",  -- comentarios: warm brown-gray icónico
			-- ── Cromática Monokai auténtica ──────────────────────────────────────────
			red      = "#f92672",  -- keywords: if/for/return/class
			green    = "#a6e22e",  -- funciones: def/function declarations
			yellow   = "#e6db74",  -- strings: "hello world"
			orange   = "#fd971f",  -- parámetros, decoradores, inlay hints
			cyan     = "#66d9ef",  -- tipos, built-ins, UI accent
			purple   = "#ae81ff",  -- números, constantes, true/false/nil
		}
		local hl = function(name, opts)
			vim.api.nvim_set_hl(0, name, opts)
		end

		-- ── Superficie normal: transparente → WezTerm background visible ───────────
		hl("Normal",      { bg = t })
		hl("NormalNC",    { bg = t, fg = M.fg_cmt })
		hl("NormalFloat", { bg = M.bg_float, fg = M.fg })     -- ELEVADO sobre editor
		hl("FloatBorder", { fg = M.bg_brd, bg = M.bg_float }) -- borde warm amber
		hl("FloatTitle",  { fg = M.cyan, bg = M.bg_float, bold = true })
		hl("FloatFooter", { fg = M.fg_cmt, bg = M.bg_float })

		-- Separadores
		hl("WinSeparator", { fg = M.bg_brd, bg = t })
		hl("VertSplit",    { fg = M.bg_brd, bg = t })

		-- Cursor line / line numbers
		hl("CursorLine",   { bg = M.bg_cur })
		hl("CursorLineNr", { fg = M.yellow, bold = true })
		hl("LineNr",       { fg = M.fg_cmt })

		-- Pmenu: ELEVADO sobre editor (#2e2d27)
		hl("Pmenu",      { bg = M.bg_float, fg = M.fg_dim })
		hl("PmenuSel",   { bg = M.bg_sel, fg = M.fg, bold = true })
		hl("PmenuSbar",  { bg = M.bg_cur })
		hl("PmenuThumb", { bg = M.fg_cmt })

		-- Visual / selección: warm amber
		hl("Visual",    { bg = M.bg_sel })
		hl("VisualNOS", { bg = M.bg_sel })

		-- Búsqueda
		hl("Search",    { bg = M.bg_cur, fg = M.fg })
		hl("IncSearch", { bg = M.yellow, fg = M.bg, bold = true })
		hl("CurSearch", { bg = M.orange, fg = M.bg, bold = true })

		-- ─── Neo-tree: sistema de color refinado ────────────────────────────────────
		-- Principios: Catppuccin(semántica git) + Kanagawa(jerarquía por luminancia)
		-- Regla cardinal: cyan=acento UI, red=errores/keywords en CÓDIGO (no decoración)
		hl("NeoTreeNormal",        { bg = M.bg_panel, fg = M.fg })
		hl("NeoTreeNormalNC",      { bg = M.bg_panel, fg = M.fg_cmt })
		hl("NeoTreeWinSeparator",  { fg = M.bg_brd, bg = M.bg_panel })
		hl("NeoTreeEndOfBuffer",   { bg = M.bg_panel, fg = M.bg_panel })
		-- bg_cur "#3e3d32" sobre bg_panel "#1b1c19" = 1.53:1 contraste (muy sutil)
		-- Fix: bg_sel "#49483e" — Monokai list.activeSelectionBackground → 1.85:1 (claramente visible)
		hl("NeoTreeCursorLine",    { bg = "#5A5650" })  -- warm olive: ~2.5:1 vs #1b1c19
		hl("NeoTreeDimText",       { fg = M.fg_cmt })
		-- Indent guides: subtiles — ayuda de navegación, no decoración
		-- bg_cur (#3e3d32) vs bg_brd (#49483e): 15% más oscuro, menos intrusivo
		hl("NeoTreeIndentMarker",  { fg = M.bg_cur })
		hl("NeoTreeExpander",      { fg = M.fg_cmt })
		-- Git status — semántica consistente (Catppuccin/JetBrains standard):
		-- Added=green(nuevo/positivo), Modified=yellow(cambiado/neutral),
		-- Deleted=rojo ATENUADO(destructivo pero no alarmante), Untracked=orange(pendiente),
		-- Staged=green bold(ready to commit), Ignored=dim(irrelevante), Conflict=red bold(error real)
		hl("NeoTreeGitAdded",      { fg = M.green })
		hl("NeoTreeGitModified",   { fg = M.yellow })
		hl("NeoTreeGitDeleted",    { fg = "#c04060" })   -- rojo muted H~340° S65% L47%: destructivo sin neon
		hl("NeoTreeGitUntracked",  { fg = M.orange, italic = true }) -- orange=pendiente, italic=borrador
		hl("NeoTreeGitIgnored",    { fg = M.fg_cmt })               -- dim total: ignorados son invisibles
		hl("NeoTreeGitStaged",     { fg = M.green, bold = true })   -- bold = confirmación visual ready
		hl("NeoTreeGitConflict",   { fg = M.red,   bold = true })   -- único caso donde red neon es correcto
		hl("NeoTreeModified",      { fg = M.yellow })  -- dot de buffer sin guardar: mismo color que git modified
		-- Directorios: icono provee el acento cyan, nombre legible como archivos normales
		hl("NeoTreeDirectoryIcon", { fg = M.cyan })
		hl("NeoTreeDirectoryName", { fg = M.fg })       -- fg pleno: dirs tan legibles como files
		-- Root: elemento UI = acento identidad cyan (yellow era semántica de "string")
		hl("NeoTreeRootName",      { fg = M.cyan, bold = true, italic = true })
		-- Archivos: neutral, abiertos = acento UI de selección activa
		hl("NeoTreeFileName",      { fg = M.fg })
		hl("NeoTreeFileNameOpened",{ fg = M.cyan, bold = true }) -- cyan=UI accent (green era "funciones")

		-- ── DropBar (breadcrumbs winbar) ──────────────────────────────────────
		hl("DropBarIconUISeparator",  { fg = M.fg_cmt })
		hl("DropBarMenuNormalFloat",  { bg = M.bg_float, fg = M.fg })
		hl("DropBarMenuFloatBorder",  { fg = M.bg_brd,   bg = M.bg_float })
		hl("DropBarMenuHoverEntry",   { bg = M.bg_sel,   fg = M.fg, bold = true })
		hl("DropBarMenuCurrentContext", { bg = M.bg_cur, fg = M.fg_dim })
		hl("DropBarKindFile",         { fg = M.cyan })
		hl("DropBarKindFolder",       { fg = M.fg_cmt })
		hl("DropBarKindFunction",     { fg = M.green })
		hl("DropBarKindMethod",       { fg = M.green })
		hl("DropBarKindClass",        { fg = M.cyan })
		hl("DropBarKindModule",       { fg = M.cyan })
		hl("DropBarKindInterface",    { fg = M.cyan })
		hl("DropBarKindVariable",     { fg = M.fg })
		hl("DropBarKindProperty",     { fg = M.green })
		hl("DropBarKindField",        { fg = M.green })
		hl("DropBarKindConstant",     { fg = M.purple })
		hl("DropBarKindEnum",         { fg = M.purple })
		hl("DropBarKindKeyword",      { fg = M.red })
		hl("DropBarKindString",       { fg = M.yellow })

		-- ── nvim-bqf (quickfix premium) ───────────────────────────────────────
		hl("BqfPreviewBorder",  { fg = M.bg_brd })
		hl("BqfPreviewTitle",   { fg = M.cyan,  bold = true })
		hl("BqfPreviewRange",   { bg = M.bg_sel, bold = true })
		hl("BqfPreviewBufLabel",{ fg = M.cyan,  italic = true })
		hl("BqfSign",           { fg = M.cyan })

		-- StatusLine / WinBar: transparentes
		hl("StatusLine",   { bg = t, fg = M.fg })
		hl("StatusLineNC", { bg = t, fg = M.fg_cmt })
		hl("WinBar",       { bg = t, fg = M.fg })
		hl("WinBarNC",     { bg = t, fg = M.fg_cmt })

		-- SignColumn / Fold
		hl("SignColumn", { bg = t })
		hl("FoldColumn", { fg = M.bg_brd, bg = t })
		hl("Folded",     { fg = M.fg_cmt, bg = M.bg_cur, italic = true })

		-- Parens / Cursor
		hl("MatchParen", { fg = M.orange, bg = M.bg_sel, bold = true })
		hl("Cursor",     { fg = M.bg, bg = M.cyan })
		hl("lCursor",    { fg = M.bg, bg = M.cyan })
		hl("CursorIM",   { fg = M.bg, bg = M.cyan })

		-- Diff core
		hl("DiffAdd",    { bg = "#1a2e17" })
		hl("DiffChange", { bg = "#2a2813" })
		hl("DiffDelete", { bg = "#2d1320" })
		hl("DiffText",   { bg = "#3a3620", bold = true })

		-- LSP Diagnostics
		hl("DiagnosticError", { fg = M.red })
		hl("DiagnosticWarn",  { fg = M.yellow })
		hl("DiagnosticInfo",  { fg = M.cyan })
		hl("DiagnosticHint",  { fg = M.green })
		hl("DiagnosticVirtualTextError", { fg = M.red,    bg = t, italic = true })
		hl("DiagnosticVirtualTextWarn",  { fg = M.yellow, bg = t, italic = true })
		hl("DiagnosticVirtualTextInfo",  { fg = M.cyan,   bg = t })
		hl("DiagnosticVirtualTextHint",  { fg = M.green,  bg = t })
		hl("DiagnosticUnderlineError",   { sp = M.red,    undercurl = true })
		hl("DiagnosticUnderlineWarn",    { sp = M.yellow, undercurl = true })
		hl("DiagnosticUnderlineInfo",    { sp = M.cyan,   undercurl = true })
		hl("DiagnosticUnderlineHint",    { sp = M.green,  undercurl = true })
		hl("DiagnosticUnnecessary",      { fg = M.fg_cmt, italic = true })
		hl("LspInlayHint",      { fg = M.orange, bg = t, italic = true })
		hl("LspReferenceText",  { bg = M.bg_sel })
		hl("LspReferenceRead",  { bg = M.bg_sel })
		hl("LspReferenceWrite", { bg = M.bg_sel, bold = true })
		hl("LspInfoBorder",     { fg = M.bg_brd, bg = M.bg_float })
		hl("LspCodeLens",       { fg = M.fg_cmt, italic = true })

		-- LSP typemods (JetBrains/VS Code standard)
		hl("@lsp.typemod.function.async",          { fg = M.green,  italic = true })
		hl("@lsp.typemod.class.abstract",          { fg = M.cyan,   italic = true })
		hl("@lsp.typemod.variable.readonly",       { fg = M.purple })
		hl("@lsp.typemod.variable.defaultLibrary", { fg = M.cyan })
		hl("@lsp.typemod.keyword.deprecated",      { fg = M.fg_cmt, strikethrough = true })

		-- Which-key
		hl("WhichKeyFloat",           { bg = M.bg_float })
		hl("WhichKeyBorder",          { fg = M.bg_brd, bg = M.bg_float })
		hl("NoiceCmdlinePopupBorder", { fg = M.bg_brd, bg = t })
		hl("NoiceCmdlineIcon",        { fg = M.yellow })

		-- Blink.cmp: menú y kinds completos
		hl("BlinkCmpMenuBorder",          { fg = M.bg_brd, bg = t })
		hl("BlinkCmpDocBorder",           { fg = M.bg_brd, bg = t })
		hl("BlinkCmpDocSeparatorLine",    { fg = M.bg_brd })
		hl("BlinkCmpGhostText",           { fg = M.fg_cmt, italic = true })
		hl("BlinkCmpSignatureHelpBorder", { fg = M.bg_brd, bg = t })
		-- Kinds (color lanes Monokai)
		hl("BlinkCmpKindFunction",     { fg = M.green })
		hl("BlinkCmpKindMethod",       { fg = M.green })
		hl("BlinkCmpKindConstructor",  { fg = M.cyan })
		hl("BlinkCmpKindClass",        { fg = M.cyan })
		hl("BlinkCmpKindInterface",    { fg = M.cyan, italic = true })
		hl("BlinkCmpKindEnum",         { fg = M.cyan })
		hl("BlinkCmpKindEnumMember",   { fg = M.purple })
		hl("BlinkCmpKindConstant",     { fg = M.purple })
		hl("BlinkCmpKindField",        { fg = M.orange })
		hl("BlinkCmpKindProperty",     { fg = M.orange })
		hl("BlinkCmpKindVariable",     { fg = M.fg })
		hl("BlinkCmpKindKeyword",      { fg = M.red })
		hl("BlinkCmpKindModule",       { fg = M.fg_cmt })
		hl("BlinkCmpKindSnippet",      { fg = M.yellow })
		hl("BlinkCmpKindText",         { fg = M.fg_dim })
		hl("BlinkCmpKindOperator",     { fg = M.fg })
		hl("BlinkCmpKindUnit",         { fg = M.purple })
		hl("BlinkCmpKindValue",        { fg = M.yellow })
		hl("BlinkCmpKindReference",    { fg = M.orange })
		hl("BlinkCmpKindEvent",        { fg = M.purple })
		hl("BlinkCmpKindColor",        { fg = M.orange })
		hl("BlinkCmpKindFile",         { fg = M.cyan })
		hl("BlinkCmpKindFolder",       { fg = M.cyan })
		hl("BlinkCmpKindTypeParameter",{ fg = M.cyan })

		-- Rainbow delimiters: Monokai color lanes (espectral: calor→frío)
		hl("RainbowDelimiterRed",    { fg = M.red })
		hl("RainbowDelimiterOrange", { fg = M.orange })
		hl("RainbowDelimiterYellow", { fg = M.yellow })
		hl("RainbowDelimiterGreen",  { fg = M.green })
		hl("RainbowDelimiterCyan",   { fg = M.cyan })
		hl("RainbowDelimiterViolet", { fg = M.purple })
		hl("RainbowDelimiterBlue",   { fg = M.fg_dim })

		-- Telescope / Snacks picker: borde activo cyan (accent)
		hl("TelescopeNormal",        { bg = M.bg_float })
		hl("TelescopeBorder",        { fg = M.bg_brd, bg = M.bg_float })
		hl("TelescopePromptNormal",  { bg = M.bg_float })
		hl("TelescopePromptBorder",  { fg = M.cyan, bg = M.bg_float })
		hl("TelescopePromptTitle",   { fg = M.cyan, bg = M.bg_float, bold = true })
		hl("TelescopeResultsNormal", { bg = M.bg_float })
		hl("TelescopeResultsBorder", { fg = M.bg_brd, bg = M.bg_float })
		hl("TelescopePreviewNormal", { bg = M.bg_float })
		hl("TelescopePreviewBorder", { fg = M.bg_brd, bg = M.bg_float })
		hl("TelescopeSelection",     { bg = M.bg_cur, fg = M.fg })
		hl("SnacksPickerBorder",     { fg = M.cyan, bg = M.bg_float })
		hl("SnacksPickerPrompt",     { fg = M.cyan })
		hl("SnacksPickerSearch",     { fg = M.yellow })
		hl("SnacksNormal",           { bg = M.bg_float })
		hl("SnacksBorder",           { fg = M.cyan, bg = M.bg_float })

		-- Flash / Leap
		hl("FlashLabel", { fg = M.bg, bg = M.orange, bold = true })
		hl("FlashMatch", { fg = M.cyan, bg = M.bg_cur })

		-- Lazy / Mason
		hl("LazyNormal",       { bg = M.bg_float, fg = M.fg })
		hl("LazyButton",       { bg = M.bg_cur, fg = M.fg })
		hl("LazyButtonActive", { bg = M.cyan, fg = M.bg, bold = true })
		hl("LazyH1",           { bg = M.cyan, fg = M.bg, bold = true })
		hl("MasonNormal",      { bg = M.bg_float })

		-- Treesitter context
		hl("TreesitterContext",           { bg = M.bg_cur, italic = true })
		hl("TreesitterContextLineNumber", { fg = M.yellow, bg = M.bg_cur })
		hl("TreesitterContextBottom",     { sp = M.bg_brd, underline = true })
		hl("TreesitterContextSeparator",  { fg = M.bg_brd })

		-- Indent guides
		hl("MiniIndentscopeSymbol", { fg = M.bg_brd })
		hl("IndentBlanklineChar",   { fg = M.bg_brd })

		-- Claude Code / Terminal
		hl("ClaudeCodeBorder", { fg = M.cyan, bg = t })
		hl("ClaudeCodeTitle",  { fg = M.cyan, bg = t, bold = true })
		hl("ToggleTermBorder", { fg = M.bg_brd, bg = t })

		-- DiffView
		hl("DiffViewNormal",            { bg = M.bg_panel, fg = M.fg })
		hl("DiffViewFilePanelTitle",    { fg = M.yellow, bold = true })
		hl("DiffViewFilePanelCounter",  { fg = M.purple })
		hl("DiffViewFilePanelFileName", { fg = M.fg })
		hl("DiffViewDiffAdd",           { bg = "#1a2e17" })
		hl("DiffViewDiffDelete",        { bg = "#2d1320" })
		hl("DiffViewDiffChange",        { bg = "#2a2813" })
		hl("DiffViewDiffText",          { bg = "#3a3620", bold = true })

		-- Incline.nvim (filename float por ventana)
		hl("InclineNormal",   { bg = M.bg_float, fg = M.fg })
		hl("InclineNormalNC", { bg = M.bg_float, fg = M.fg_cmt })
		hl("InclineActive",   { bg = M.bg_sel,   fg = M.yellow, bold = true })

		-- Grug-far
		hl("GrugFarResultsMatch", { bg = M.bg_cur, fg = M.orange, bold = true })
		hl("GrugFarResultsPath",  { fg = M.cyan })

		-- Obsidian
		hl("ObsidianBullet",        { fg = M.cyan })
		hl("ObsidianTag",           { fg = M.purple, italic = true })
		hl("ObsidianHighlightText", { bg = M.bg_sel, fg = M.yellow })
		hl("ObsidianRefText",       { fg = M.cyan, underline = true })

		-- Oil.nvim
		hl("OilDir",        { fg = M.cyan, bold = true })
		hl("OilDirIcon",    { fg = M.cyan })
		hl("OilFile",       { fg = M.fg })
		hl("OilLink",       { fg = M.green, italic = true })
		hl("OilLinkTarget", { fg = M.green })
		hl("OilCopy",       { fg = M.orange, bold = true })
		hl("OilMove",       { fg = M.yellow, bold = true })
		hl("OilDelete",     { fg = M.red,    bold = true })
		hl("OilCreate",     { fg = M.green,  bold = true })

		-- nvim-dbee
		hl("DbeeNormal", { bg = M.bg_float, fg = M.fg })
		hl("DbeeBorder", { fg = M.cyan, bg = M.bg_float })
		hl("DbeeTitle",  { fg = M.cyan, bg = M.bg_float, bold = true })

		-- Kulala HTTP
		hl("KulalaNormal",                { bg = M.bg_float, fg = M.fg })
		hl("KulalaBorder",                { fg = M.cyan, bg = M.bg_float })
		hl("KulalaMethodGet",             { fg = M.green,  bold = true })
		hl("KulalaMethodPost",            { fg = M.yellow, bold = true })
		hl("KulalaMethodPut",             { fg = M.orange, bold = true })
		hl("KulalaMethodDelete",          { fg = M.red,    bold = true })
		hl("KulalaMethodPatch",           { fg = M.cyan,   bold = true })
		hl("KulalaMethodHead",            { fg = M.green,  bold = true })
		hl("KulalaStatusCodeSuccess",     { fg = M.green,  bold = true })
		hl("KulalaStatusCodeRedirect",    { fg = M.yellow, bold = true })
		hl("KulalaStatusCodeClientError", { fg = M.orange, bold = true })
		hl("KulalaStatusCodeServerError", { fg = M.red,    bold = true })
		hl("KulalaURL",           { fg = M.cyan, underline = true })
		hl("KulalaHeader",        { fg = M.green })
		hl("KulalaHeaderValue",   { fg = M.fg })
		hl("KulalaVariableName",  { fg = M.purple, italic = true })
		hl("KulalaVariableValue", { fg = M.orange })
		hl("KulalaComment",       { fg = M.fg_cmt, italic = true })
		hl("KulalaInlayHint",     { fg = M.fg_cmt })

		-- C# / LSP semántico
		hl("@lsp.type.interface",  { fg = M.cyan, italic = true })
		hl("@lsp.type.class",      { fg = M.cyan })
		hl("@lsp.type.method",     { fg = M.green })
		hl("@lsp.type.property",   { fg = M.fg_dim })
		hl("@lsp.type.parameter",  { fg = M.orange, italic = true })
		hl("@lsp.type.namespace",  { fg = M.fg_dim })
		hl("@lsp.type.enumMember", { fg = M.purple })
		hl("@function.method.call.c_sharp", { fg = M.green })
		hl("@function.method.c_sharp",      { fg = M.green })
		hl("@variable.member.c_sharp",      { fg = M.fg_dim })
		hl("@variable.c_sharp",             { fg = M.fg })
		hl("@type.c_sharp",                 { fg = M.cyan })
		hl("@keyword.modifier.c_sharp",     { fg = M.red, italic = true })

		-- RenderMarkdown
		hl("RenderMarkdownH1",     { fg = M.red,    bold = true })
		hl("RenderMarkdownH2",     { fg = M.orange, bold = true })
		hl("RenderMarkdownH3",     { fg = M.yellow, bold = true })
		hl("RenderMarkdownH4",     { fg = M.green,  bold = true })
		hl("RenderMarkdownH5",     { fg = M.cyan,   bold = true })
		hl("RenderMarkdownH6",     { fg = M.purple, bold = true })
		hl("RenderMarkdownH1Bg",   { bg = "#2a1a21" })
		hl("RenderMarkdownH2Bg",   { bg = "#2a2212" })
		hl("RenderMarkdownH3Bg",   { bg = "#2a2912" })
		hl("RenderMarkdownH4Bg",   { bg = "#1a2a1a" })
		hl("RenderMarkdownH5Bg",   { bg = "#1a262a" })
		hl("RenderMarkdownH6Bg",   { bg = "#221a2a" })
		hl("RenderMarkdownCode",       { bg = M.bg_cur })
		hl("RenderMarkdownCodeInline", { bg = M.bg_cur, fg = M.orange })
		hl("RenderMarkdownBullet",     { fg = M.cyan })
		hl("RenderMarkdownLink",       { fg = M.cyan, underline = true })
		hl("RenderMarkdownTodo",       { fg = M.yellow, bold = true })
		hl("RenderMarkdownQuote",      { fg = M.fg_cmt, italic = true })
		hl("RenderMarkdownDash",       { fg = M.bg_brd })
		hl("RenderMarkdownTableHead",  { fg = M.yellow, bold = true })
		hl("RenderMarkdownTableRow",   { fg = M.fg })
		hl("RenderMarkdownTableFill",  { fg = M.bg_brd })

		-- Mini.files
		hl("MiniFilesNormal",       { bg = M.bg_float, fg = M.fg })
		hl("MiniFilesBorder",       { fg = M.bg_brd, bg = M.bg_float })
		hl("MiniFilesTitle",        { fg = M.fg_cmt, bg = M.bg_float })
		hl("MiniFilesTitleFocused", { fg = M.cyan, bg = M.bg_float, bold = true })
		hl("MiniFilesDirectory",    { fg = M.cyan, bold = true })
		hl("MiniFilesCursorLine",   { bg = M.bg_cur })

		-- GitSigns
		hl("GitSignsAdd",      { fg = M.green })
		hl("GitSignsChange",   { fg = M.yellow })
		hl("GitSignsDelete",   { fg = M.red })
		hl("GitSignsAddNr",    { fg = M.green })
		hl("GitSignsChangeNr", { fg = M.yellow })
		hl("GitSignsDeleteNr", { fg = M.red })
		hl("GitSignsAddLn",    { bg = "#1a2e17" })
		hl("GitSignsChangeLn", { bg = "#2a2813" })

		-- Trouble.nvim
		hl("TroubleNormal",   { bg = M.bg_panel, fg = M.fg })
		hl("TroubleText",     { fg = M.fg })
		hl("TroubleCount",    { fg = M.yellow, bold = true })
		hl("TroubleIndent",   { fg = M.bg_brd })
		hl("TroubleLocation", { fg = M.fg_cmt })
		hl("TroubleFile",     { fg = M.cyan, bold = true })
		hl("TroubleSource",   { fg = M.fg_cmt })

		-- Todo-comments
		hl("TodoBgFIX",  { fg = M.bg, bg = M.red,    bold = true })
		hl("TodoBgHACK", { fg = M.bg, bg = M.yellow, bold = true })
		hl("TodoBgNOTE", { fg = M.bg, bg = M.green,  bold = true })
		hl("TodoBgPERF", { fg = M.bg, bg = M.cyan,   bold = true })
		hl("TodoBgTEST", { fg = M.bg, bg = M.purple, bold = true })
		hl("TodoBgTODO", { fg = M.bg, bg = M.yellow, bold = true })
		hl("TodoBgWARN", { fg = M.bg, bg = M.orange, bold = true })
		hl("TodoFgFIX",  { fg = M.red })
		hl("TodoFgHACK", { fg = M.yellow })
		hl("TodoFgNOTE", { fg = M.green })
		hl("TodoFgPERF", { fg = M.cyan })
		hl("TodoFgTEST", { fg = M.purple })
		hl("TodoFgTODO", { fg = M.yellow })
		hl("TodoFgWARN", { fg = M.orange })
		hl("TodoSignFIX",  { fg = M.red })
		hl("TodoSignHACK", { fg = M.yellow })
		hl("TodoSignNOTE", { fg = M.green })
		hl("TodoSignPERF", { fg = M.cyan })
		hl("TodoSignTEST", { fg = M.purple })
		hl("TodoSignTODO", { fg = M.yellow })
		hl("TodoSignWARN", { fg = M.orange })

		-- Snacks Notify
		hl("SnacksNotifyERROR",       { fg = M.red,    bg = t })
		hl("SnacksNotifyWARN",        { fg = M.yellow, bg = t })
		hl("SnacksNotifyINFO",        { fg = M.cyan,   bg = t })
		hl("SnacksNotifyDEBUG",       { fg = M.fg_cmt, bg = t })
		hl("SnacksNotifyBorderERROR", { fg = M.red })
		hl("SnacksNotifyBorderWARN",  { fg = M.yellow })
		hl("SnacksNotifyBorderINFO",  { fg = M.cyan })
		hl("SnacksNotifyBorderDEBUG", { fg = M.fg_cmt })
		hl("SnacksNotifyTitleERROR",  { fg = M.red,    bold = true })
		hl("SnacksNotifyTitleWARN",   { fg = M.yellow, bold = true })
		hl("SnacksNotifyTitleINFO",   { fg = M.cyan,   bold = true })
		hl("SnacksNotifyTitleDEBUG",  { fg = M.fg_cmt, bold = true })
		hl("SnacksNotifyIconERROR",   { fg = M.red })
		hl("SnacksNotifyIconWARN",    { fg = M.yellow })
		hl("SnacksNotifyIconINFO",    { fg = M.cyan })
		hl("SnacksNotifyIconDEBUG",   { fg = M.fg_cmt })

		-- TabLine: bg_deep para tab row (profundidad máxima)
		hl("TabLine",     { fg = M.fg_cmt, bg = M.bg_deep })
		hl("TabLineFill", { fg = t,        bg = M.bg_deep })
		hl("TabLineSel",  { fg = M.cyan,   bg = M.bg_cur, bold = true })

		-- Quickfix / Help
		hl("qfFileName",        { fg = M.cyan })
		hl("qfLineNr",          { fg = M.yellow })
		hl("qfError",           { fg = M.red })
		hl("helpHyperTextJump", { fg = M.cyan, underline = true })
		hl("helpHeadline",      { fg = M.yellow, bold = true })
		hl("helpSectionDelim",  { fg = M.bg_brd })

		-- ── Sintaxis Monokai ST3 auténtica ──────────────────────────────────
		-- STRINGS: amarillo #e6db74 — el color más icónico de toda la historia de Monokai
		hl("String",    { fg = M.yellow })
		hl("Character", { fg = M.yellow })
		hl("@string",          { fg = M.yellow })
		hl("@string.escape",   { fg = M.orange })
		hl("@string.special",  { fg = M.orange })
		hl("@string.regex",    { fg = M.orange })
		hl("@string.regexp",   { fg = M.orange })
		hl("@character",         { fg = M.yellow })
		hl("@character.special", { fg = M.orange })

		-- KEYWORDS: rojo #f92672
		hl("Keyword",     { fg = M.red, italic = true })
		hl("Conditional", { fg = M.red, italic = true })
		hl("Repeat",      { fg = M.red, italic = true })
		hl("Exception",   { fg = M.red })
		hl("Label",       { fg = M.red })
		hl("Statement",   { fg = M.red, italic = true })
		hl("@keyword",             { fg = M.red, italic = true })
		hl("@keyword.function",    { fg = M.red, italic = true })
		hl("@keyword.return",      { fg = M.red, italic = true })
		hl("@keyword.import",      { fg = M.red, italic = true })
		hl("@keyword.repeat",      { fg = M.red, italic = true })
		hl("@keyword.conditional", { fg = M.red, italic = true })
		hl("@keyword.exception",   { fg = M.red })
		hl("@keyword.operator",    { fg = M.red })
		hl("@keyword.directive",   { fg = M.red })
		hl("@keyword.modifier",    { fg = M.red, italic = true })

		-- FUNCIONES: verde lima #a6e22e
		hl("Function",              { fg = M.green })
		hl("@function",             { fg = M.green })
		hl("@function.builtin",     { fg = M.cyan })
		hl("@function.macro",       { fg = M.green, italic = true })
		hl("@function.method",      { fg = M.green })
		hl("@function.method.call", { fg = M.green })
		hl("@function.call",        { fg = M.green })
		hl("@constructor",          { fg = M.cyan })

		-- TIPOS: cyan #66d9ef
		hl("Type",             { fg = M.cyan })
		hl("StorageClass",     { fg = M.red, italic = true })
		hl("Structure",        { fg = M.cyan })
		hl("@type",            { fg = M.cyan })
		hl("@type.builtin",    { fg = M.cyan, italic = true })
		hl("@type.definition", { fg = M.cyan })
		hl("@type.qualifier",  { fg = M.red, italic = true })

		-- VARIABLES: fg limpio
		hl("Identifier",          { fg = M.fg })
		hl("@variable",           { fg = M.fg })
		hl("@variable.builtin",   { fg = M.red, italic = true })
		hl("@variable.parameter", { fg = M.orange, italic = true })
		hl("@variable.member",    { fg = M.fg_dim })

		-- CONSTANTES & NÚMEROS: púrpura #ae81ff
		hl("Constant",          { fg = M.purple })
		hl("Number",            { fg = M.purple })
		hl("Float",             { fg = M.purple })
		hl("Boolean",           { fg = M.purple })
		hl("@constant",         { fg = M.purple })
		hl("@constant.builtin", { fg = M.purple })
		hl("@constant.macro",   { fg = M.purple, italic = true })
		hl("@number",           { fg = M.purple })
		hl("@number.float",     { fg = M.purple })
		hl("@boolean",          { fg = M.purple })

		-- OPERADORES y PUNCTUATION
		hl("Operator",               { fg = M.fg })
		hl("@operator",              { fg = M.fg })
		hl("Delimiter",              { fg = M.fg_dim })
		hl("@punctuation.bracket",   { fg = M.fg })
		hl("@punctuation.delimiter", { fg = M.fg_dim })
		hl("@punctuation.special",   { fg = M.cyan })

		-- COMENTARIOS: marrón-gris cálido #75715e itálico
		hl("Comment",                { fg = M.fg_cmt, italic = true })
		hl("SpecialComment",         { fg = M.fg_cmt, italic = true })
		hl("@comment",               { fg = M.fg_cmt, italic = true })
		hl("@comment.todo",          { fg = M.orange, bold = true })
		hl("@comment.note",          { fg = M.cyan,   bold = true })
		hl("@comment.error",         { fg = M.red,    bold = true })
		hl("@comment.warning",       { fg = M.yellow, bold = true })
		hl("@comment.documentation", { fg = M.fg_cmt, italic = true })

		-- MÓDULOS / NAMESPACE
		hl("@module",    { fg = M.fg })
		hl("@namespace", { fg = M.fg })

		-- ATRIBUTOS / DECORADORES: naranja itálico
		hl("@attribute",         { fg = M.orange, italic = true })
		hl("@attribute.builtin", { fg = M.orange, italic = true })

		-- TAGS HTML/JSX/XML
		hl("Tag",            { fg = M.red })
		hl("@tag",           { fg = M.red })
		hl("@tag.attribute", { fg = M.orange })
		hl("@tag.delimiter", { fg = M.fg_dim })

		-- PREPROCESSOR
		hl("PreProc",     { fg = M.red })
		hl("Include",     { fg = M.red, italic = true })
		hl("Define",      { fg = M.red })
		hl("Macro",       { fg = M.green, italic = true })
		hl("Special",     { fg = M.cyan })
		hl("SpecialChar", { fg = M.orange })

		-- mini.icons: paleta Monokai ST3
		hl("MiniIconsBlue",   { fg = M.cyan })
		hl("MiniIconsCyan",   { fg = M.cyan })
		hl("MiniIconsGreen",  { fg = M.green })
		hl("MiniIconsYellow", { fg = M.yellow })
		hl("MiniIconsOrange", { fg = M.orange })
		hl("MiniIconsPurple", { fg = M.purple })
		hl("MiniIconsRed",    { fg = M.red })
		hl("MiniIconsAzure",  { fg = M.cyan })
		hl("MiniIconsGrey",   { fg = M.fg_cmt })

		-- nvim-web-devicons: colores Monokai ST3 por extensión de archivo
		local ok, devicons = pcall(require, "nvim-web-devicons")
		if ok then
			devicons.setup({
				override_by_extension = {
					lua       = { icon = "󰢱", color = M.cyan,   name = "Lua" },
					py        = { icon = "󰌠", color = M.green,  name = "Python" },
					rb        = { icon = "󰴭", color = M.red,    name = "Ruby" },
					php       = { icon = "󰌟", color = M.purple, name = "PHP" },
					js        = { icon = "󰌞", color = M.yellow, name = "Javascript" },
					ts        = { icon = "󰛦", color = M.cyan,   name = "Typescript" },
					jsx       = { icon = "󰜈", color = M.cyan,   name = "JSX" },
					tsx       = { icon = "󰜈", color = M.cyan,   name = "TSX" },
					vue       = { icon = "󰡄", color = M.green,  name = "Vue" },
					svelte    = { icon = "",  color = M.orange, name = "Svelte" },
					css       = { icon = "󰌜", color = M.cyan,   name = "CSS" },
					scss      = { icon = "󰌜", color = M.purple, name = "SCSS" },
					html      = { icon = "󰌝", color = M.orange, name = "HTML" },
					json      = { icon = "󰘦", color = M.yellow, name = "JSON" },
					yaml      = { icon = "󰬻", color = M.orange, name = "YAML" },
					yml       = { icon = "󰬻", color = M.orange, name = "YAML" },
					toml      = { icon = "",  color = M.orange, name = "TOML" },
					xml       = { icon = "󰗀", color = M.orange, name = "XML" },
					rs        = { icon = "󰙱", color = M.orange, name = "Rust" },
					go        = { icon = "󰟓", color = M.cyan,   name = "Go" },
					cs        = { icon = "󰌛", color = M.purple, name = "Csharp" },
					java      = { icon = "󰬷", color = M.orange, name = "Java" },
					kt        = { icon = "󱈙", color = M.purple, name = "Kotlin" },
					sh        = { icon = "",  color = M.green,  name = "Shell" },
					bash      = { icon = "",  color = M.green,  name = "Bash" },
					ps1       = { icon = "󰨊", color = M.cyan,   name = "PowerShell" },
					vim       = { icon = "",  color = M.green,  name = "Vim" },
					md        = { icon = "󰍔", color = M.fg_dim, name = "Markdown" },
					mdx       = { icon = "󰍔", color = M.cyan,   name = "MDX" },
					txt       = { icon = "󰊄", color = M.fg_dim, name = "Text" },
					sql       = { icon = "󰆼", color = M.cyan,   name = "SQL" },
					http      = { icon = "󰌤", color = M.green,  name = "HTTP" },
					env       = { icon = "",  color = M.yellow, name = "Env" },
					lock      = { icon = "󰌾", color = M.fg_cmt, name = "Lock" },
					png       = { icon = "󰋩", color = M.purple, name = "PNG" },
					jpg       = { icon = "󰋩", color = M.purple, name = "JPEG" },
					jpeg      = { icon = "󰋩", color = M.purple, name = "JPEG" },
					gif       = { icon = "󰋩", color = M.purple, name = "GIF" },
					svg       = { icon = "󰜡", color = M.red,    name = "SVG" },
					tf        = { icon = "󱁢", color = M.purple, name = "Terraform" },
					dockerfile= { icon = "󰡨", color = M.cyan,   name = "Dockerfile" },
				},
			})
		end
	end,
})

-- ─── Sublime: catppuccin-mocha identico + superficies y bordes Monokai ────────
-- Sistema de superficies ref: monokai.jsonc (excelencia premium, granular)
--
-- FILOSOFIA MONOKAI (ref: monokai.jsonc):
--   • Todos los paneles, sidebar, widgets, floats: MISMO bg (#1e1f1c) — sin elevacion falsa
--     (sideBar.background = activityBar.background = panel.background = editor.background)
--   • Profundidad por BORDES: sep=#2c2d2a (panel.border) / brd_w=#3e3d32 (editorWidget.border)
--   • Hover/inactive selection: #3e3d32 (list.hoverBackground)
--   • Active selection: #49483e (list.activeSelectionBackground) — amber warm signature
--   • Cursor line: #232321 (editor.lineHighlightBackground: #2d2d2d@20% sobre #1e1f1c)
--   • Accent UI activo/focus: #66d9ef (activityBar.activeBorder / badge.background / focusBorder)
--   • NormalNC: transparente — WezTerm inactive_pane_hsb gestiona el dimming de panes inactivos
--
-- IDENTIDAD CATPPUCCIN: sintaxis, acentos fg — 100% preservados
-- C.mauve (#cba6f7) preservado en paleta para uso futuro en sintaxis/decoracion
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "sublime",
	group = augroup("sublime_overrides"),
	callback = function()
		local t = "NONE"

		-- ── Superficies Sublime (ref: monokai.jsonc) ─────────────────────────────
		-- bg_flat : editor + sidebar + todos los widgets/floats — MISMO bg (monokai)
		-- bg_cur  : cursor line — muy sutil (monokai editor.lineHighlightBackground)
		-- bg_hover: hover / inactive selection (monokai list.hoverBackground)
		-- bg_sel  : active selection (monokai list.activeSelectionBackground)
		local bg_flat  = "#1e1f1c"  -- superficie unica: editor, sidebar, widgets, floats
		local bg_cur   = "#232321"  -- cursor line (monokai #2d2d2d@20% → solido)
		local bg_hover = "#3e3d32"  -- hover / search / treesitter-ctx
		local bg_sel   = "#49483e"  -- active selection / find-match (warm amber)

		-- ── Bordes Sublime (ref: monokai.jsonc) ──────────────────────────────────
		-- sep    : separadores panel/ventana (monokai panel.border = #2c2d2a@40%)
		-- brd_w  : bordes widget/float (monokai editorWidget.border = #3e3d32)
		-- accent : activo/focus/identidad (monokai activityBar.activeBorder = #66d9ef)
		--          C.mauve (#cba6f7) se preserva en paleta para sintaxis/decoracion
		local sep    = "#2c2d2a"  -- separadores panel (sutiles)
		local brd_w  = "#3e3d32"  -- widget borders (calidos, visibles)
		local accent = "#66d9ef"  -- activo / focus / identidad UI (monokai cyan)

		-- ── Paleta catppuccin mocha — FG/sintaxis/acentos 100% identicos ─────────
		local C = {
			text     = "#cdd6f4",
			subtext0 = "#a6adc8",
			subtext1 = "#bac2de",
			overlay0 = "#6c7086",
			overlay1 = "#7f849c",
			overlay2 = "#9399b2",
			surface0 = "#313244",
			surface1 = "#45475a",
			surface2 = "#585b70",
			crust    = "#11111b",
			mauve    = "#cba6f7",
			blue     = "#89b4fa",
			lavender = "#b4befe",
			peach    = "#fab387",
			teal     = "#94e2d5",
			sky      = "#89dceb",
			green    = "#a6e3a1",
			red      = "#f38ba8",
			yellow   = "#f9e2af",
			maroon   = "#eba0ac",
			sapphire = "#74c7ec",
		}

		local hl = function(name, opts) vim.api.nvim_set_hl(0, name, opts) end

		-- ────────────────────────────────────────────────────────────────────────
		-- CORE TRANSPARENCY STACK
		-- Normal:     transparente → WezTerm provee #1e1f1c como bg del terminal
		-- NormalNC:   transparente → WezTerm inactive_pane_hsb dimea panes inactivos
		--             (monokai no diferencia bg entre grupos de editor activos/inactivos)
		-- NormalFloat: bg_flat (#1e1f1c solido) — visible sobre editor transparente
		-- FloatBorder: brd_w (#3e3d32) — monokai editorWidget.border
		-- FloatTitle:  accent (#66d9ef) — monokai activityBar.activeBorder (titulo activo)
		-- ────────────────────────────────────────────────────────────────────────
		-- monokai.jsonc: editor.foreground = #c2c2bf (warm beige, más cálido que catppuccin text)
		-- Afecta texto no coloreado por sintaxis — rest de syntax colors se sobreescriben abajo
		hl("Normal",      { bg = t,       fg = "#c2c2bf" })
		hl("NormalNC",    { bg = t,       fg = C.overlay0 })
		hl("NormalFloat", { bg = bg_flat, fg = "#c2c2bf" })
		hl("FloatBorder", { fg = brd_w,   bg = bg_flat })
		hl("FloatTitle",  { fg = accent,  bg = bg_flat, bold = true })
		hl("FloatFooter", { fg = C.overlay0, bg = bg_flat })

		-- ────────────────────────────────────────────────────────────────────────
		-- SEPARADORES DE VENTANA / PANEL
		-- sep (#2c2d2a): monokai panel.border — sutil, organico, casi invisible
		-- ────────────────────────────────────────────────────────────────────────
		hl("WinSeparator", { fg = sep, bg = t })
		hl("VertSplit",    { fg = sep, bg = t })

		-- ────────────────────────────────────────────────────────────────────────
		-- EDITOR SURFACE
		-- CursorLine: bg_cur muy sutil (monokai lineHighlight = #2d2d2d@20% → #232321)
		-- LineNr: overlay0 catppuccin (4.1:1 contraste, principio Kanagawa)
		-- ────────────────────────────────────────────────────────────────────────
		hl("CursorLine",   { bg = bg_cur })
		hl("CursorLineNr", { fg = "#c2c2bf", bold = true })  -- monokai editorLineNumber.activeForeground
		hl("LineNr",       { fg = C.overlay0 })
		hl("ColorColumn",  { bg = bg_cur })

		-- ────────────────────────────────────────────────────────────────────────
		-- POPUP / COMPLETION (Pmenu)
		-- bg_flat: monokai editorSuggestWidget.background = #1e1f1c (plano)
		-- brd_w: monokai editorSuggestWidget.border = #3e3d32
		-- PmenuSel: bg_sel (monokai editorSuggestWidget.selectedBackground = #49483e)
		-- ────────────────────────────────────────────────────────────────────────
		hl("Pmenu",      { bg = bg_flat, fg = "#c2c2bf" })
		hl("PmenuSel",   { bg = bg_sel,  fg = "#e8e6e0", bold = true })
		hl("PmenuSbar",  { bg = bg_hover })
		hl("PmenuThumb", { bg = C.overlay1 })
		hl("PmenuBorder",{ fg = brd_w, bg = bg_flat })

		-- ────────────────────────────────────────────────────────────────────────
		-- VISUAL SELECTION / SEARCH
		-- Visual: bg_sel (monokai editor.selectionBackground = #49483e@70% → #49483e solid)
		-- Search: bg_hover warm amber (monokai editor.findMatchBackground = #49483e@70%)
		-- ────────────────────────────────────────────────────────────────────────
		-- Visual: solo bg — fg heredado de cada grupo de sintaxis (preserva token colors)
		-- fg explicito (#f8f8f2) anulaba colores ST3 en seleccion → eliminado
		hl("Visual",    { bg = bg_sel })
		hl("VisualNOS", { bg = bg_sel })
		hl("Search",    { bg = bg_hover, fg = C.text })
		hl("IncSearch", { bg = C.peach,  fg = C.crust, bold = true })
		hl("CurSearch", { bg = accent,   fg = bg_flat, bold = true })  -- match activo = cyan

		-- ────────────────────────────────────────────────────────────────────────
		-- CURSOR / MATCHPAREN
		-- Cursor: accent (#66d9ef) — monokai editorCursor.foreground = #66d9ef
		-- C.mauve preservado en paleta, aqui accent toma el rol de cursor
		-- ────────────────────────────────────────────────────────────────────────
		hl("Cursor",     { fg = bg_flat, bg = accent })
		hl("lCursor",    { fg = bg_flat, bg = accent })
		hl("CursorIM",   { fg = bg_flat, bg = accent })
		hl("MatchParen", { fg = C.peach, bg = bg_hover, bold = true })

		-- ────────────────────────────────────────────────────────────────────────
		-- STATUSLINE / WINBAR — transparentes (mismo stack que Normal.bg=NONE)
		-- El tema de lualine para sublime se aplica en lualine.lua opts=function()
		-- NO usar ll.setup() aquí: crea race condition al cambiar temas mid-session
		-- ────────────────────────────────────────────────────────────────────────
		hl("StatusLine",   { bg = t })
		hl("StatusLineNC", { bg = t, fg = C.overlay0 })
		hl("WinBar",       { bg = t, fg = "#868480" })  -- muted warm gray (era #c2c2bf demasiado brillante)
		hl("WinBarNC",     { bg = t, fg = "#52504c" })  -- ventana inactiva muy dim

		-- ────────────────────────────────────────────────────────────────────────
		-- SIGN COLUMN / FOLD
		-- ────────────────────────────────────────────────────────────────────────
		hl("SignColumn", { bg = t })
		hl("FoldColumn", { fg = brd_w, bg = t })
		hl("Folded",     { fg = C.blue, bg = bg_cur, italic = true })

		-- ────────────────────────────────────────────────────────────────────────
		-- TABLINE
		-- bg_flat: monokai tab bar = mismo bg que editor (#1e1f1c) — sin ruido visual
		-- TabLineSel: accent (#66d9ef) — monokai tab.activeBorderTop = cyan
		-- ────────────────────────────────────────────────────────────────────────
		hl("TabLine",     { fg = C.overlay0, bg = bg_flat })
		hl("TabLineFill", { fg = t,           bg = bg_flat })
		hl("TabLineSel",  { fg = C.text,      bg = bg_sel, bold = true })  -- Muted warm background, white text

		-- ────────────────────────────────────────────────────────────────────────
		-- DIFF — catppuccin tints preservados (tonos azul/verde/rojo)
		-- ────────────────────────────────────────────────────────────────────────
		hl("DiffAdd",    { bg = "#1a3a2a" })
		hl("DiffChange", { bg = "#1a2a3a" })
		hl("DiffDelete", { bg = "#3a1a1a" })
		hl("DiffText",   { bg = "#1a3a4a", bold = true })

		-- ────────────────────────────────────────────────────────────────────────
		-- LSP REFERENCES / INLAY HINTS
		-- bg_sel para referencias (monokai wordHighlight = #49483e@40%)
		-- LspInlayHint: overlay1 sobre bg_flat (inline en editor, flat y consistente)
		-- ────────────────────────────────────────────────────────────────────────
		hl("LspReferenceText",  { bg = bg_sel })
		hl("LspReferenceRead",  { bg = bg_sel })
		hl("LspReferenceWrite", { bg = bg_sel, bold = true })
		hl("LspInfoBorder",     { fg = brd_w, bg = bg_flat })
		hl("LspInlayHint",      { fg = "#75715e", bg = t, italic = true })  -- monokai editorInlayHint: olive dim, sin bg
		hl("LspCodeLensText",      { fg = C.overlay1, italic = true })
		hl("LspCodeLensSeparator", { fg = brd_w })

		-- ────────────────────────────────────────────────────────────────────────
		-- MINI.ICONS — Paleta suave Catppuccin Latte
		-- Ref: catppuccin-vsc-icons (Latte)
		-- Colores oscuros/profundos que suavizan el contraste sobre el fondo Monokai
		-- logrando la excelencia premium y el aspecto visual relajado de VSC
		-- ────────────────────────────────────────────────────────────────────────
		local L = {
			blue     = "#1e66f5",
			teal     = "#179299",
			green    = "#40a02b",
			yellow   = "#df8e1d",
			peach    = "#fe640b",
			mauve    = "#8839ef",
			red      = "#d20f39",
			sapphire = "#209fb5",
			overlay1 = "#8c8fa1",
			text     = "#4c4f69",
		}
		hl("MiniIconsBlue",   { fg = L.blue })      -- azul oscuro elegante
		hl("MiniIconsCyan",   { fg = L.teal })      -- cyan profundo
		hl("MiniIconsGreen",  { fg = L.green })     -- verde bosque
		hl("MiniIconsYellow", { fg = L.yellow })    -- mostaza oscuro
		hl("MiniIconsOrange", { fg = L.peach })     -- naranja tostado
		hl("MiniIconsPurple", { fg = L.mauve })     -- púrpura real
		hl("MiniIconsRed",    { fg = L.red })       -- rojo carmesí
		hl("MiniIconsAzure",  { fg = L.sapphire })  -- zafiro profundo
		hl("MiniIconsGrey",   { fg = L.overlay1 })  -- gris neutro/suave

		-- ────────────────────────────────────────────────────────────────────────
		-- NEO-TREE SIDEBAR
		-- bg_flat: monokai sideBar.background = #1e1f1c (identico al editor) — flat
		-- sep:     monokai sideBar.border = #2c2d2a (separa sin ruido)
		-- DirectoryIcon: Catppuccin Latte Blue equivalencia exacta con catppuccin-vsc-icons
		-- ────────────────────────────────────────────────────────────────────────
		hl("NeoTreeNormal",       { bg = bg_flat, fg = C.text })
		hl("NeoTreeNormalNC",     { bg = bg_flat, fg = C.subtext0 })
		hl("NeoTreeWinSeparator", { fg = sep,     bg = bg_flat })
		hl("NeoTreeEndOfBuffer",  { bg = bg_flat, fg = bg_flat })
		-- bg_hover "#3e3d32" sobre bg_flat "#1e1f1c" = 1.58:1 contraste (invisible en práctica)
		-- Fix: bg_sel "#49483e" — Monokai list.activeSelectionBackground → 1.85:1 (visible, cálido)
		-- bg_sel es semánticamente correcto: en un árbol, el cursor = selección activa
		hl("NeoTreeCursorLine",   { bg = "#706A5A" })  -- warm olive: ~2.95:1 vs #1e1f1c
		hl("NeoTreeDimText",      { fg = C.overlay0 })
		hl("NeoTreeIndentMarker", { fg = brd_w })
		-- Directorio: icono Catppuccin VSC Icons Latte (Outline muted)
		hl("NeoTreeDirectoryIcon", { fg = L.text })  -- Warm muted gray/brown
		hl("NeoTreeDirectory",     { fg = "#c2c2bf" })  -- nombre carpeta: monokai fg neutral
		hl("NeoTreeDirectoryName", { fg = "#c2c2bf" })
		-- Archivos: neutral, abiertos = Kanagawa fujiWhite (sin contraste extremo)
		hl("NeoTreeFileName",       { fg = "#c2c2bf" })
		hl("NeoTreeFileNameOpened", { fg = "#DCD7BA", bold = true })  -- Kanagawa fujiWhite: elegante, no brillante
		hl("NeoTreeRootName",       { fg = "#DCD7BA", bold = true, italic = true })
		-- File icon: hereda MiniIcons/devicons — NO sobreescribir (colores por tipo preservados)

		-- ────────────────────────────────────────────────────────────────────────
		-- TELESCOPE / SNACKS PICKER
		-- bg_flat: monokai quickInput.background = #1e1f1c
		-- brd_w:   widget.border = #3e3d32 (warm, sutil)
		-- Prompt/active border: accent (#66d9ef) — monokai focusBorder / input activo
		-- ────────────────────────────────────────────────────────────────────────
		hl("TelescopeNormal",        { bg = bg_flat })
		hl("TelescopeBorder",        { fg = brd_w,   bg = bg_flat })
		hl("TelescopePromptNormal",  { bg = bg_flat })
		hl("TelescopePromptBorder",  { fg = accent,  bg = bg_flat })  -- input activo = cyan
		hl("TelescopePromptTitle",   { fg = accent,  bg = bg_flat, bold = true })
		hl("TelescopeResultsNormal", { bg = bg_flat })
		hl("TelescopeResultsBorder", { fg = brd_w,   bg = bg_flat })
		hl("TelescopePreviewNormal", { bg = bg_flat })
		hl("TelescopePreviewBorder", { fg = brd_w,   bg = bg_flat })
		hl("TelescopeSelection",     { bg = bg_sel,  fg = C.text })

		hl("SnacksPickerBorder",        { fg = brd_w,      bg = bg_flat })
		hl("SnacksNormal",              { bg = bg_flat })
		hl("SnacksBorder",              { fg = brd_w,      bg = bg_flat })  -- widget generico = brd_w
		hl("SnacksPickerMatch",         { fg = C.peach,    bold = true })   -- letras coincidentes fuzzy: orange ST3
		hl("SnacksPickerDir",           { fg = C.overlay1, italic = true }) -- path directorio: dim olive
		hl("SnacksPickerFile",          { fg = "#c2c2bf" })                 -- nombre archivo: text neutro
		hl("SnacksPickerPrompt",        { fg = accent,     bold = true })   -- "> " del input: cyan accent
		hl("SnacksPickerSearch",        { fg = C.yellow })                  -- texto buscado resaltado: yellow ST3
		hl("SnacksPickerListCursorLine",{ bg = bg_hover,   fg = "#e8e6e0" }) -- fila activa: warm bg hover

		-- ────────────────────────────────────────────────────────────────────────
		-- BLINK.CMP COMPLETION
		-- bg_flat: monokai editorSuggestWidget.background = #1e1f1c
		-- brd_w:   monokai editorSuggestWidget.border = #3e3d32
		-- ────────────────────────────────────────────────────────────────────────
		hl("BlinkCmpMenuBorder",          { fg = brd_w,      bg = bg_flat })
		hl("BlinkCmpDocBorder",           { fg = brd_w,      bg = bg_flat })
		hl("BlinkCmpDocSeparatorLine",    { fg = brd_w })
		hl("BlinkCmpGhostText",           { fg = C.overlay0, italic = true })
		hl("BlinkCmpSignatureHelpBorder", { fg = brd_w,      bg = bg_flat })

		-- ────────────────────────────────────────────────────────────────────────
		-- WHICH-KEY / NOICE
		-- bg_flat: monokai quickInput = #1e1f1c
		-- brd_w:   monokai editorWidget.border = #3e3d32
		-- ────────────────────────────────────────────────────────────────────────
		hl("WhichKeyFloat",           { bg = bg_flat })
		hl("WhichKeyBorder",          { fg = brd_w,   bg = bg_flat })
		hl("NoiceCmdlinePopupBorder", { fg = brd_w,   bg = t })
		hl("NoiceCmdlineIcon",        { fg = accent })

		-- ────────────────────────────────────────────────────────────────────────
		-- LAZY / MASON
		-- bg_flat: monokai quickInput.background = #1e1f1c
		-- ────────────────────────────────────────────────────────────────────────
		hl("LazyNormal",       { bg = bg_flat, fg = C.text })
		hl("LazyButton",       { bg = bg_hover, fg = C.text })
		hl("LazyButtonActive", { bg = accent,   fg = bg_flat, bold = true })
		hl("LazyH1",           { bg = accent,   fg = bg_flat, bold = true })
		hl("MasonNormal",      { bg = bg_flat })

		-- ────────────────────────────────────────────────────────────────────────
		-- TREESITTER CONTEXT (sticky header)
		-- bg_hover: suficientemente visible sobre el editor transparente
		-- ────────────────────────────────────────────────────────────────────────
		hl("TreesitterContext",           { bg = bg_hover, italic = true })
		hl("TreesitterContextLineNumber", { fg = accent, bg = bg_hover })
		hl("TreesitterContextBottom",     { sp = brd_w,   underline = true })
		hl("TreesitterContextSeparator",  { fg = brd_w })

		-- ────────────────────────────────────────────────────────────────────────
		-- INDENT GUIDES
		-- brd_w para scope, bg_hover para char (monokai editorIndentGuide)
		-- ────────────────────────────────────────────────────────────────────────
		hl("MiniIndentscopeSymbol", { fg = brd_w })
		hl("IndentBlanklineChar",   { fg = bg_hover })

		-- ────────────────────────────────────────────────────────────────────────
		-- FLASH / LEAP — paleta Monokai ST3 auténtica
		-- Label  : orange bg (#fd971f) — máximo contraste, letra de salto clara
		-- Current: yellow bg (#e6db74) — string yellow, match activo bajo cursor
		-- Match  : green fg sobre bg_hover — chars que coinciden, calmos pero visibles
		-- Backdrop: dim (#5a5a54) — Monokai Night dim, apaga todo lo que NO es target
		-- ────────────────────────────────────────────────────────────────────────
		hl("FlashLabel",    { fg = "#1e1f1c", bg = "#fd971f", bold = true })
		hl("FlashCurrent",  { fg = "#1e1f1c", bg = "#e6db74" })
		hl("FlashMatch",    { fg = "#a6e22e", bg = bg_hover })
		hl("FlashBackdrop", { fg = "#5a5a54" })

		-- ────────────────────────────────────────────────────────────────────────
		-- CLAUDE CODE / TOGGLETERM
		-- Borders: accent (#66d9ef) — ventana activa/enfocada = cyan monokai
		-- ────────────────────────────────────────────────────────────────────────
		-- Claude Code float: bg_flat (mismo que NormalFloat) — no contraste artificial
		-- Borde: brd_w sutil cuando inactivo, accent cyan solo en titulo (UI monokai)
		-- ClaudeCodeBorderFocus: no existe aun en claudecode.nvim pero se preconfigura
		hl("ClaudeCodeBorder",      { fg = brd_w,     bg = t })
		hl("ClaudeCodeTitle",       { fg = accent,    bg = t, bold = true })
		-- SnacksWin: snacks.nvim usa estos grupos para el contenedor del float
		hl("SnacksWin",             { bg = bg_flat,   fg = C.text })
		hl("SnacksWinBorder",       { fg = brd_w,     bg = bg_flat })
		hl("SnacksWinFooter",       { fg = C.overlay0, bg = bg_flat })
		hl("SnacksWinFooterKey",    { fg = accent,    bg = bg_flat, bold = true })
		hl("SnacksPickerPrompt",    { fg = accent })         -- prompt activo = cyan
		hl("SnacksPickerSearch",    { fg = "#e6db74" })      -- monokai yellow para coincidencias blink
		hl("SnacksPickerTitle",     { fg = accent,    bold = true })
		hl("ToggleTermBorder",      { fg = brd_w,     bg = t })
		hl("ToggleTermNormal",      { bg = bg_flat })

		-- ────────────────────────────────────────────────────────────────────────
		-- NVIM-DBEE
		-- bg_flat: monokai flat, accent border = activo/identidad cyan
		-- ────────────────────────────────────────────────────────────────────────
		hl("DbeeNormal", { bg = bg_flat, fg = C.text })
		hl("DbeeBorder", { fg = brd_w,   bg = bg_flat })  -- widget border = sutil
		hl("DbeeTitle",  { fg = accent,  bg = bg_flat, bold = true })

		-- ────────────────────────────────────────────────────────────────────────
		-- KULALA HTTP CLIENT
		-- ────────────────────────────────────────────────────────────────────────
		hl("KulalaNormal", { bg = bg_flat, fg = C.text })
		hl("KulalaBorder", { fg = brd_w,   bg = bg_flat })  -- widget border = sutil

		-- ────────────────────────────────────────────────────────────────────────
		-- MINI.FILES (file browser flotante)
		-- bg_flat: monokai widget flat, brd_w: widget border
		-- ────────────────────────────────────────────────────────────────────────
		hl("MiniFilesNormal",       { bg = bg_flat,  fg = C.text })
		hl("MiniFilesBorder",       { fg = brd_w,    bg = bg_flat })
		hl("MiniFilesTitle",        { fg = C.overlay1, bg = bg_flat })
		hl("MiniFilesTitleFocused", { fg = accent,   bg = bg_flat, bold = true })
		hl("MiniFilesCursorLine",   { bg = bg_sel })

		-- ────────────────────────────────────────────────────────────────────────
		-- DIFFVIEW
		-- bg_flat: monokai flat (consistente con NeoTree/editor)
		-- ────────────────────────────────────────────────────────────────────────
		hl("DiffViewNormal",            { bg = bg_flat, fg = C.text })
		hl("DiffViewFilePanelTitle",    { fg = C.peach, bold = true })
		hl("DiffViewFilePanelCounter",  { fg = C.lavender })
		hl("DiffViewFilePanelFileName", { fg = C.text })
		hl("DiffViewDiffAdd",    { bg = "#1a3a2a" })
		hl("DiffViewDiffDelete", { bg = "#3a1a1a" })
		hl("DiffViewDiffChange", { bg = "#1a2a3a" })
		hl("DiffViewDiffText",   { bg = "#1a3a4a", bold = true })

		-- ────────────────────────────────────────────────────────────────────────
		-- INCLINE (filename float por ventana)
		-- bg_flat: widget plano monokai-style
		-- ────────────────────────────────────────────────────────────────────────
		hl("InclineNormal",   { bg = bg_flat, fg = C.text })
		hl("InclineNormalNC", { bg = bg_flat, fg = C.overlay0 })
		hl("InclineActive",   { bg = bg_sel,  fg = C.peach, bold = true })

		-- ────────────────────────────────────────────────────────────────────────
		-- TROUBLE.NVIM (panel lateral de diagnosticos)
		-- bg_flat: monokai flat (consistente con NeoTree/DiffView/editor)
		-- ────────────────────────────────────────────────────────────────────────
		hl("TroubleNormal",   { bg = bg_flat, fg = C.text })
		hl("TroubleText",     { fg = C.text })
		hl("TroubleIndent",   { fg = brd_w })
		hl("TroubleLocation", { fg = C.overlay0 })
		hl("TroubleFile",     { fg = C.blue, bold = true })
		hl("TroubleSource",   { fg = C.overlay0 })

		-- ────────────────────────────────────────────────────────────────────────
		-- MINI.MAP — minimap panel (complementa satellite.nvim)
		-- ────────────────────────────────────────────────────────────────────────
		hl("MiniMapNormal",           { fg = C.overlay0,  bg = bg_flat })
		hl("MiniMapSymbolView",       { fg = brd_w,        bg = bg_flat })  -- viewport indicator
		hl("MiniMapSymbolLine",       { fg = accent,       bg = bg_flat })  -- cursor line: cyan
		hl("MiniMapSymbolSearch",     { fg = C.peach,      bg = bg_flat })  -- búsqueda: peach
		hl("MiniMapSymbolError",      { fg = "#f92672",    bg = bg_flat })  -- error: ST3 red
		hl("MiniMapSymbolWarn",       { fg = "#e6db74",    bg = bg_flat })  -- warn: ST3 yellow
		hl("MiniMapSymbolInfo",       { fg = "#66d9ef",    bg = bg_flat })  -- info: ST3 cyan
		hl("MiniMapSymbolHint",       { fg = "#ae81ff",    bg = bg_flat })  -- hint: ST3 purple
		hl("MiniMapSymbolGitAdd",     { fg = "#81b88b",    bg = bg_flat })  -- git add: monokai green
		hl("MiniMapSymbolGitChange",  { fg = "#e2c08d",    bg = bg_flat })  -- git change: amber
		hl("MiniMapSymbolGitDelete",  { fg = "#c74e39",    bg = bg_flat })  -- git del: muted red
		
		-- ────────────────────────────────────────────────────────────────────────
		-- SATELLITE SCROLLBAR
		-- bg NONE sobre editor transparente (mauve/peach/semantic colores catppuccin)
		-- ────────────────────────────────────────────────────────────────────────
		hl("SatelliteBar",            { fg = C.overlay0, bg = t })
		hl("SatelliteCursor",         { fg = C.blue,     bg = t })  -- scrollbar: blue catppuccin, no accent
		hl("SatelliteSearch",         { fg = C.peach,    bg = t })
		-- Satellite diagnostics: paleta Monokai ST3 (sync con DiagnosticError/Warn/Info/Hint)
		hl("SatelliteDiagnosticError",{ fg = "#f92672",  bg = t })  -- monokai red
		hl("SatelliteDiagnosticWarn", { fg = "#e6db74",  bg = t })  -- monokai yellow
		hl("SatelliteDiagnosticInfo", { fg = "#66d9ef",  bg = t })  -- monokai cyan
		hl("SatelliteDiagnosticHint", { fg = "#ae81ff",  bg = t })  -- monokai purple
		hl("SatelliteGitsignsAdd",    { fg = "#81b88b",  bg = t })  -- monokai muted green
		hl("SatelliteGitsignsChange", { fg = "#e2c08d",  bg = t })  -- monokai amber
		hl("SatelliteGitsignsDelete", { fg = "#c74e39",  bg = t })  -- monokai muted red

		-- ────────────────────────────────────────────────────────────────────────
		-- DROPBAR: breadcrumb neutro y limpio (VS Code style)
		-- Filosofía: path=neutral, kinds=muy sutil. Información útil sin ruido visual.
		local db_fg   = "#9e9c96"  -- muted warm gray (era #c2c2bf demasiado brillante)
		local db_dim  = "#5e5c58"  -- dim: path segments, folders, separadores
		local db_sep  = "#2c2d2a"  -- separador: casi invisible
		hl("DropBarIconUISeparator",    { fg = db_sep })
		hl("DropBarCurrentContext",     { fg = db_fg,  bold = false })
		hl("DropBarMenuNormalFloat",    { bg = bg_flat, fg = db_fg })
		hl("DropBarMenuFloatBorder",    { fg = brd_w,   bg = bg_flat })
		hl("DropBarMenuHoverEntry",     { bg = bg_hover, fg = db_fg })
		hl("DropBarMenuCurrentContext", { bg = bg_cur,   fg = db_fg })
		-- Path segments: neutral — no colorear carpetas ni archivo, solo mostrar
		hl("DropBarKindFile",           { fg = db_fg })
		hl("DropBarKindFolder",         { fg = db_fg })   -- mismo que DropBarKindFile: neutral warm-white
		hl("DropBarKindModule",         { fg = db_dim })
		hl("DropBarKindNamespace",      { fg = db_dim })
		hl("DropBarKindPackage",        { fg = db_dim })
		-- Code structure: Latte sutil pero distinguible (ayuda a navegar)
		hl("DropBarKindFunction",       { fg = L.green })
		hl("DropBarKindMethod",         { fg = L.green })
		hl("DropBarKindConstructor",    { fg = L.green })
		hl("DropBarKindClass",          { fg = L.sapphire })
		hl("DropBarKindInterface",      { fg = L.teal })
		hl("DropBarKindStruct",         { fg = L.sapphire })
		hl("DropBarKindType",           { fg = L.sapphire })
		hl("DropBarKindTypeParameter",  { fg = L.peach })
		hl("DropBarKindProperty",       { fg = L.teal })
		hl("DropBarKindField",          { fg = L.teal })
		hl("DropBarKindVariable",       { fg = db_fg })
		hl("DropBarKindConstant",       { fg = L.peach })
		hl("DropBarKindEnum",           { fg = L.yellow })
		hl("DropBarKindEnumMember",     { fg = L.yellow })
		hl("DropBarKindKeyword",        { fg = db_dim })
		hl("DropBarKindString",         { fg = db_fg })
		hl("DropBarKindNumber",         { fg = db_fg })
		hl("DropBarKindBoolean",        { fg = db_fg })
		hl("DropBarKindArray",          { fg = db_fg })
		hl("DropBarKindObject",         { fg = db_fg })
		hl("DropBarKindEvent",          { fg = db_dim })
		hl("DropBarKindOperator",       { fg = db_sep })
		-- Markdown headings: gradiente cálido para orientar en documentos
		-- Breadcrumb headings: jerarquía luminancia (Kanagawa principle)
		-- sync con @markup.heading.N — NO rainbow, gradiente warm-white→olive
		hl("DropBarKindMarkdownH1",     { fg = "#b8b6b0", bold = true })  -- H1: muted warm white
		hl("DropBarKindMarkdownH2",     { fg = "#9e9c96" })               -- H2: warm gray
		hl("DropBarKindMarkdownH3",     { fg = "#868480" })               -- H3: medium dim
		hl("DropBarKindMarkdownH4",     { fg = "#6e6c68" })               -- H4: dim
		hl("DropBarKindMarkdownH5",     { fg = "#5c5a56", italic = true })-- H5: very dim italic
		hl("DropBarKindMarkdownH6",     { fg = "#4e4c48", italic = true })-- H6: barely visible
		-- ────────────────────────────────────────────────────────────────────────
		-- NVIM-BQF (quickfix UI premium)
		-- bg_flat: monokai flat — preview flotante sobre editor transparente
		-- accent (#66d9ef): borde activo y título (monokai focusBorder)
		-- bg_sel: rango resaltado en el preview (list.activeSelectionBackground)
		-- ────────────────────────────────────────────────────────────────────────
		hl("BqfPreviewBorder",  { fg = brd_w,   bg = t })
		hl("BqfPreviewTitle",   { fg = accent,  bg = t,   bold = true })
		hl("BqfPreviewRange",   { bg = bg_sel,  bold = true })
		hl("BqfPreviewBufLabel",{ fg = accent,  italic = true })
		hl("BqfSign",           { fg = accent })

		-- ────────────────────────────────────────────────────────────────────────
		-- RENDERMARKDOWN: code blocks con bg_hover (visible sobre editor transparente)
		-- ────────────────────────────────────────────────────────────────────────
		-- Headings: gradiente luminancia sync con @markup.heading.N
		-- Bg: tints warm casi imperceptibles (blend #c2c2bf + #1e1f1c ~4%) → visual rest
		hl("RenderMarkdownH1",                { fg = "#e8e6e0", bold = true })
		hl("RenderMarkdownH2",                { fg = "#cccac4", bold = true })
		hl("RenderMarkdownH3",                { fg = "#b0aea8", bold = true })
		hl("RenderMarkdownH4",                { fg = "#969490", bold = true })
		hl("RenderMarkdownH5",                { fg = "#7c7a76", italic = true })
		hl("RenderMarkdownH6",                { fg = "#75715e", italic = true })
		hl("RenderMarkdownH1Bg",              { bg = "#262420" })  -- warm tint sutil
		hl("RenderMarkdownH2Bg",              { bg = "#252320" })
		hl("RenderMarkdownH3Bg",              { bg = "#252320" })
		hl("RenderMarkdownH4Bg",              { bg = "#242220" })
		hl("RenderMarkdownH5Bg",              { bg = "#232221" })
		hl("RenderMarkdownH6Bg",              { bg = "#232221" })
		hl("RenderMarkdownCode",              { bg = "#272822" })  -- Monokai original bg (code blocks)
		hl("RenderMarkdownCodeInline",        { bg = "#272822", fg = "#fd971f" })  -- orange = SM.param
		hl("RenderMarkdownBullet",            { fg = "#fd971f" })              -- orange ST3 (Kanagawa: structural recedes)
		hl("RenderMarkdownLink",              { fg = "#66d9ef", underline = true })
		hl("RenderMarkdownTodo",              { fg = "#fd971f", bold = true })
		hl("RenderMarkdownQuote",             { fg = "#8a8878", italic = true })  -- Kanagawa: recede
		hl("RenderMarkdownQuoteLine",         { fg = "#3e3d32" })                 -- barra | blockquote: mismo que border (casi invisible)
		hl("RenderMarkdownDash",              { fg = "#75715e", bold = true })
		hl("RenderMarkdownTableHead",         { fg = "#66d9ef", bold = true })
		hl("RenderMarkdownTableRow",          { fg = "#c2c2bf" })
		hl("RenderMarkdownTableFill",         { fg = "#75715e" })
		hl("RenderMarkdownChecked",           { fg = "#a6e22e" })              -- [x] = green
		hl("RenderMarkdownUnchecked",         { fg = "#75715e" })              -- [ ] = dim
		hl("RenderMarkdownCalloutNote",       { fg = "#66d9ef", bold = true })  -- NOTE = cyan
		hl("RenderMarkdownCalloutWarning",    { fg = "#e6db74", bold = true })  -- WARNING = yellow
		hl("RenderMarkdownCalloutTip",        { fg = "#a6e22e", bold = true })  -- TIP = green
		hl("RenderMarkdownCalloutImportant",  { fg = "#ae81ff", bold = true })  -- IMPORTANT = purple
		hl("RenderMarkdownCalloutCaution",    { fg = "#f92672", bold = true })  -- CAUTION = red
		hl("RenderMarkdownSign",              { fg = "#66d9ef" })

		-- ────────────────────────────────────────────────────────────────────────
		-- GRUG-FAR / OBSIDIAN (search & notes panels)
		-- ────────────────────────────────────────────────────────────────────────
		hl("GrugFarResultsMatch", { bg = bg_sel,  fg = C.peach, bold = true })
		hl("GrugFarResultsPath",  { fg = C.blue })
		hl("ObsidianBullet",        { fg = C.teal })   -- teal: distinguible sin ser agresivo
		hl("ObsidianTag",           { fg = C.lavender, italic = true })
		hl("ObsidianHighlightText", { bg = bg_sel, fg = C.yellow })
		hl("ObsidianRefText",       { fg = C.blue, underline = true })

		-- ────────────────────────────────────────────────────────────────────────
		-- SNACKS NOTIFY — bordes y titulos (bg viene de NormalFloat = bg_flat)
		-- ────────────────────────────────────────────────────────────────────────
		hl("SnacksNotifyBorderERROR", { fg = C.red })
		hl("SnacksNotifyBorderWARN",  { fg = C.yellow })
		hl("SnacksNotifyBorderINFO",  { fg = C.teal })
		hl("SnacksNotifyBorderDEBUG", { fg = C.overlay0 })

		-- ────────────────────────────────────────────────────────────────────────
		-- OIL.NVIM (file browser en buffer)
		-- ────────────────────────────────────────────────────────────────────────
		hl("OilDir",    { fg = C.lavender, bold = true })
		hl("OilDirIcon",{ fg = C.lavender })
		hl("OilFile",   { fg = C.text })

		-- ────────────────────────────────────────────────────────────────────────
		-- DIAGNOSTICS — paleta Monokai ST3 completa
		-- Error=red #f92672, Warn=yellow #e6db74, Info=cyan #66d9ef, Hint=purple #ae81ff
		-- VirtualText: fg+italic con bg tintado muy sutil (monokai.jsonc editorError.*)
		-- Underline: undercurl nativo (WezTerm underline_thickness=2)
		-- Sign: mismo fg sin bg (signcolumn usa bg del editor)
		-- ────────────────────────────────────────────────────────────────────────
		hl("DiagnosticError",              { fg = "#f92672" })
		hl("DiagnosticWarn",               { fg = "#e6db74" })
		hl("DiagnosticInfo",               { fg = "#66d9ef" })
		hl("DiagnosticHint",               { fg = "#ae81ff" })

		hl("DiagnosticVirtualTextError",   { fg = "#f92672", bg = "#2a1018", italic = true })
		hl("DiagnosticVirtualTextWarn",    { fg = "#e6db74", bg = "#2a2510", italic = true })
		hl("DiagnosticVirtualTextInfo",    { fg = "#66d9ef", bg = "#0e2030", italic = true })
		hl("DiagnosticVirtualTextHint",    { fg = "#ae81ff", bg = "#1e1528", italic = true })

		hl("DiagnosticUnderlineError",     { undercurl = true, sp = "#f92672" })
		hl("DiagnosticUnderlineWarn",      { undercurl = true, sp = "#e6db74" })
		hl("DiagnosticUnderlineInfo",      { undercurl = true, sp = "#66d9ef" })
		hl("DiagnosticUnderlineHint",      { undercurl = true, sp = "#ae81ff" })

		hl("DiagnosticFloatingError",      { fg = "#f92672" })
		hl("DiagnosticFloatingWarn",       { fg = "#e6db74" })
		hl("DiagnosticFloatingInfo",       { fg = "#66d9ef" })
		hl("DiagnosticFloatingHint",       { fg = "#ae81ff" })

		hl("DiagnosticSignError",          { fg = "#f92672" })
		hl("DiagnosticSignWarn",           { fg = "#e6db74" })
		hl("DiagnosticSignInfo",           { fg = "#66d9ef" })
		hl("DiagnosticSignHint",           { fg = "#ae81ff" })

		hl("DiagnosticUnnecessary",        { fg = C.overlay0, italic = true })  -- código muerto dim
		hl("DiagnosticDeprecated",         { fg = "#75715e", strikethrough = true })

		-- ────────────────────────────────────────────────────────────────────────
		-- RAINBOW DELIMITERS — paleta Monokai ST3 espectral (sync sonokai overrides)
		-- Orden: calor → frío — bracket nesting visualmente guiado
		-- ────────────────────────────────────────────────────────────────────────
		hl("RainbowDelimiterRed",    { fg = "#f92672" })  -- L1: keyword red
		hl("RainbowDelimiterOrange", { fg = "#fd971f" })  -- L2: param orange
		hl("RainbowDelimiterYellow", { fg = "#e6db74" })  -- L3: string yellow
		hl("RainbowDelimiterGreen",  { fg = "#a6e22e" })  -- L4: function green
		hl("RainbowDelimiterCyan",   { fg = "#66d9ef" })  -- L5: storage cyan
		hl("RainbowDelimiterViolet", { fg = "#ae81ff" })  -- L6: constant purple
		hl("RainbowDelimiterBlue",   { fg = "#75715e" })  -- L7: comment olive (dim para nesting profundo)

		-- ────────────────────────────────────────────────────────────────────────
		-- SYNTAX: COMENTARIOS — firma Monokai clasica
		-- #75715e: olive/brown ST3 — identidad visual mas calida que overlay0 (#6c7086 cool)
		-- monokai.jsonc ref: editorCodeLens.foreground = #75715e, inactiveForeground = #75715e
		-- italic: standard de los top temas (Monokai, Dracula, Tokyo Night, Catppuccin)
		-- ────────────────────────────────────────────────────────────────────────
		local cmt = "#75715e"  -- monokai comment color (olive, calido)
		hl("Comment",                  { fg = cmt, italic = true })
		hl("SpecialComment",           { fg = cmt, bold = true })
		hl("@comment",                 { fg = cmt, italic = true })
		hl("@comment.line",            { fg = cmt, italic = true })
		hl("@comment.block",           { fg = cmt, italic = true })
		hl("@comment.documentation",   { fg = cmt, italic = true })  -- doc strings
		hl("@lsp.type.comment",        { fg = cmt, italic = true })

		-- ────────────────────────────────────────────────────────────────────────
		-- WHITESPACE CHARS (listchars: space=·, tab=→, trail=•)
		-- #4e4d40: ligeramente mas brillante que bg_hover (#3e3d32) — visible pero sutil
		-- Ref: monokai editorWhitespace.foreground = #3e3d32 (VS Code aplica con blending,
		--      en nvim necesitamos +~20% luminance para equivalencia visual)
		-- ────────────────────────────────────────────────────────────────────────
		hl("Whitespace",    { fg = "#4e4d40" })  -- space dots: calidos, sutiles
		hl("NonText",       { fg = "#3e3d32" })  -- extends/precedes: practicamente invisibles
		hl("SpecialKey",    { fg = "#4e4d40" })  -- tab arrows

		-- ────────────────────────────────────────────────────────────────────────
		-- MONOKAI SUBLIME TEXT 3 — SYNTAX HIGHLIGHT PALETTE
		-- Ref: monokai.jsonc symbolIcon.* + classic ST3 .tmTheme
		-- Mantiene identidad catppuccin para UI/decoracion; overridea sintaxis con ST3
		--
		-- Paleta ST3:
		--   RED    #f92672 : keywords control (if/for/while/return/and/not/in)
		--   CYAN   #66d9ef : storage type (function/var/let/const/static/async) + built-ins
		--   GREEN  #a6e22e : entity names (function names, type/class/method names)
		--   YELLOW #e6db74 : strings (todas las formas: quoted, raw, template)
		--   ORANGE #fd971f : parameters de función (variable.parameter)
		--   PURPLE #ae81ff : números, booleans, constantes, escape sequences
		--   OLIVE  #75715e : comentarios italic (ya definido arriba)
		--   WHITE  #c2c2bf : variables, operadores, texto por defecto
		-- ────────────────────────────────────────────────────────────────────────
		local SM = {
			kw    = "#e05577",  -- keyword control (if/for/while/return/in/not/and/or)
			                   -- refinado: #f92672 HSL(338°,95%,56%) → #e05577 HSL(345°,69%,61%) (-25% sat)
			store = "#66d9ef",  -- storage type/modifier + builtins (function/var/const/async)
			fn    = "#a6e22e",  -- entity names (funciones, tipos, clases, métodos)
			str   = "#e6db74",  -- strings
			num   = "#ae81ff",  -- numbers, booleans, constants, escape chars
			param = "#fd971f",  -- function parameters (variable.parameter)
		}

		-- KEYWORDS: control flow = red italic
		-- ST3 clasico: storage.type era italic, keywords control no.
		-- Estandar premium moderno (Catppuccin/Kanagawa/Tokyo Night/Dracula): todos italic.
		-- Excepcion: exception/operator/debug — acciones brutas sin italic (semántica de urgencia).
		hl("@keyword",                    { fg = SM.kw, italic = true })
		hl("@keyword.conditional",        { fg = SM.kw, italic = true })  -- if/else/switch/match
		hl("@keyword.repeat",             { fg = SM.kw, italic = true })  -- for/while/do/loop
		hl("@keyword.return",             { fg = SM.kw, italic = true })  -- return/yield return
		hl("@keyword.exception",          { fg = SM.kw })                 -- throw/catch/finally (sin italic: urgencia)
		hl("@keyword.import",             { fg = SM.kw, italic = true })  -- import/using/require/include
		hl("@keyword.operator",           { fg = SM.kw })                 -- 'and'/'or'/'not'/'is'/'in' (operadores)
		hl("@keyword.debug",              { fg = SM.kw })
		-- storage.type = cyan italic: FIRMA AUTENTICA MONOKAI ST3
		-- 'function'/'var'/'let'/'const'/'class'/'static'/'async' = #66d9ef italic
		-- En ST3 esto era la regla de oro: storage.type.* = italic cyan
		hl("@keyword.function",           { fg = SM.store, italic = true })  -- 'function'/'def' declaration keyword
		hl("@keyword.storage",            { fg = SM.store, italic = true })  -- var/let/const/val/ref
		hl("@keyword.modifier",           { fg = SM.store, italic = true })  -- static/public/private/protected/override/sealed
		hl("@keyword.coroutine",          { fg = SM.store, italic = true })  -- async/await/yield (coroutine modifiers)

		-- FUNCTIONS: def=green (entity.name.function), call=cyan — Monokai Night key distinction
		hl("@function",                   { fg = SM.fn })
		hl("@function.call",              { fg = SM.store })   -- llamadas = cyan (#66d9ef)
		hl("@function.method",            { fg = SM.fn })
		hl("@function.method.call",       { fg = SM.store })   -- method calls = cyan
		hl("@constructor",                { fg = SM.fn })

		-- TYPES: names = green (ST3: entity.name.type)
		hl("@type",                       { fg = SM.fn })
		hl("@type.definition",            { fg = SM.fn })

		-- BUILT-INS: support functions/types/constants = cyan (ST3: support.*)
		hl("@type.builtin",               { fg = SM.store })  -- int, str, bool, etc.
		hl("@function.builtin",           { fg = SM.store })  -- print, len, require, etc.
		hl("@variable.builtin",           { fg = SM.param, italic = true })  -- self, this, super = orange italic

		-- STRINGS: yellow (ST3: string = #e6db74)
		hl("@string",                     { fg = SM.str })
		hl("@string.regexp",              { fg = SM.str })
		hl("@string.special",             { fg = SM.str })
		hl("@string.special.path",        { fg = SM.str })
		hl("@string.escape",              { fg = SM.num })   -- escape sequences = purple

		-- NUMBERS / CONSTANTS / BOOLEANS: purple (ST3: constant.*)
		hl("@number",                     { fg = SM.num })
		hl("@number.float",               { fg = SM.num })
		hl("@boolean",                    { fg = SM.num })
		hl("@constant",                   { fg = SM.num })
		hl("@constant.builtin",           { fg = SM.num })   -- nil, None, true, false

		-- PARAMETERS: orange (ST3: variable.parameter = #fd971f)
		hl("@variable.parameter",         { fg = SM.param })
		hl("@variable.parameter.builtin", { fg = SM.param })

		-- LSP SEMANTIC TOKENS — override catppuccin con paleta ST3
		hl("@lsp.type.function",          { fg = SM.fn })
		hl("@lsp.type.method",            { fg = SM.fn })
		hl("@lsp.type.class",             { fg = SM.fn })
		hl("@lsp.type.struct",            { fg = SM.fn })
		hl("@lsp.type.enum",              { fg = SM.fn })
		hl("@lsp.type.type",              { fg = SM.fn })
		hl("@lsp.type.interface",         { fg = SM.store, italic = true }) -- interfaces = cyan italic (ST3 firma)
		hl("@lsp.type.namespace",         { fg = SM.store }) -- namespaces = cyan
		hl("@lsp.type.typeParameter",     { fg = SM.param, italic = true }) -- T, K, V = orange italic
		hl("@lsp.type.parameter",         { fg = SM.param, italic = true })
		hl("@lsp.type.enumMember",        { fg = SM.num })   -- enum values = purple (constantes)
		hl("@lsp.type.decorator",         { fg = SM.fn, italic = true })    -- @Attribute = green italic
		hl("@lsp.type.keyword",           { fg = SM.kw })
		hl("@lsp.typemod.function.async",         { fg = SM.fn, italic = true })   -- async fn = green italic
		hl("@lsp.typemod.function.builtin",       { fg = SM.store })
		hl("@lsp.typemod.class.abstract",         { fg = SM.fn, italic = true })   -- abstract class = green italic
		hl("@lsp.typemod.variable.readonly",      { fg = SM.num })                 -- const/readonly = purple
		hl("@lsp.typemod.variable.defaultLibrary",{ fg = SM.store })
		hl("@lsp.typemod.keyword.deprecated",     { fg = "#75715e", strikethrough = true })

		-- VARIABLES: #c2c2bf warm white (ST3: variable = #e0e0e0, monokai fg)
		hl("@variable",                        { fg = "#c2c2bf" })
		hl("@variable.member",                 { fg = "#c2c2bf" })  -- obj.property
		hl("@lsp.type.variable",               { fg = "#c2c2bf" })  -- override catppuccin
		hl("@lsp.type.property",               { fg = "#c2c2bf" })

		-- OPERATORS: red (ST3: keyword.operator = #f92672)
		hl("@operator",                        { fg = SM.kw })

		-- PUNCTUATION (ST3: brackets neutral, delimiters dim)
		hl("@punctuation.bracket",             { fg = "#c2c2bf" })
		hl("@punctuation.delimiter",           { fg = "#75715e" })
		hl("@punctuation.special",             { fg = SM.store })   -- ${} interpolation = cyan

		-- TAGS HTML/JSX/XML (ST3: tag.name=red, attribute=green, delimiter=near-white)
		hl("@tag",                             { fg = SM.kw })
		hl("@tag.attribute",                   { fg = SM.fn })
		hl("@tag.delimiter",                   { fg = "#c2c2bf" })

		-- STRINGS SPECIAL
		hl("@string.special.url",              { fg = SM.store, underline = true })

		-- ── MARKDOWN: principios Kanagawa aplicados ───────────────────────────────────────────
		-- Principio 1 (Jerarquía luminancia): H1=máximo brillo, H6=comment-dim
		--   NO variedad de colores — gradiente blanco→oliva comunica jerarquía sin ruido
		-- Principio 2 (UI recede): blockquote es contexto, NO alarma → muted olive
		-- Principio 3 (Marcadores semánticos): # = orange (syntax.json: #FD9621)

		-- Marcador # : orange (syntax.json: punctuation.definition.heading.markdown = #FD9621)
		hl("@markup.heading.marker",  { fg = SM.param })

		-- Jerarquía luminancia: 6 pasos warm-white → olive-dim
		hl("@markup.heading",         { fg = "#d0cfc9", bold = true })              -- fallback genérico
		hl("@markup.heading.1",       { fg = "#e8e6e0", bold = true })              -- H1: máximo brillo
		hl("@markup.heading.2",       { fg = "#cccac4", bold = true })              -- H2: brillante
		hl("@markup.heading.3",       { fg = "#b0aea8", bold = true })              -- H3: medio
		hl("@markup.heading.4",       { fg = "#969490", bold = true })              -- H4: dim
		hl("@markup.heading.5",       { fg = "#7c7a76", italic = true })            -- H5: muy dim italic
		hl("@markup.heading.6",       { fg = "#75715e", italic = true })            -- H6: comment-level

		-- Formato inline
		hl("@markup.strong",          { fg = SM.fn,  bold = true })                  -- **bold** = green
		hl("@markup.italic",          { italic = true })                              -- style-only: italic inherits fg
		hl("@markup.strikethrough",   { fg = "#75715e", strikethrough = true })
		hl("@markup.raw.inline",      { fg = SM.param })                             -- `code` = orange
		hl("@markup.raw.block",       { fg = "#c2c2bf" })

		-- Links: cyan + underline (syntax.json: markup.underline.link = #66D9EF)
		hl("@markup.link",            { fg = SM.store, underline = true })
		hl("@markup.link.label",      { fg = SM.store })
		hl("@markup.link.url",        { fg = SM.store, underline = true })

		-- Lists: red ST3 (syntax.json: punctuation.definition.list = #F92672)
		hl("@markup.list",            { fg = SM.param })                             -- orange ST3 (structural, recede vs content)
		hl("@markup.list.checked",    { fg = SM.fn })                                -- [x] = green
		hl("@markup.list.unchecked",  { fg = "#75715e" })                            -- [ ] = dim

		-- Blockquote: contexto recede, no alarma (Kanagawa principle)
		-- syntax.json usa red #F92672, pero cita != error/urgencia
		hl("@markup.quote",           { fg = "#8a8878", italic = true })             -- muted warm olive

		-- ────────────────────────────────────────────────────────────────────────
		-- GIT: NEOTREE + GITSIGNS — colores monokai.jsonc gitDecoration.*
		-- Ref: gitDecoration.modifiedResourceForeground = #e2c08d (warm amber)
		--      gitDecoration.untrackedResourceForeground = #73c991 (muted green)
		--      gitDecoration.deletedResourceForeground = #c74e39 (muted red)
		-- ────────────────────────────────────────────────────────────────────────
		-- NeoTree: nombre de archivo coloreado segun git status
		hl("NeoTreeGitAdded",       { fg = "#81b88b" })           -- monokai: addedResourceFg
		hl("NeoTreeGitModified",    { fg = "#e2c08d" })           -- monokai: modifiedResourceFg (warm amber)
		hl("NeoTreeGitDeleted",     { fg = "#c74e39" })           -- monokai: deletedResourceFg
		hl("NeoTreeGitUntracked",   { fg = "#73c991" })           -- monokai: untrackedResourceFg
		hl("NeoTreeGitIgnored",     { fg = "#8c8c8c", italic = true })  -- monokai: ignoredResourceFg
		hl("NeoTreeGitConflict",    { fg = "#e4676b", bold = true })   -- monokai: conflictingResourceFg
		hl("NeoTreeGitRenamed",     { fg = "#73c991" })
		hl("NeoTreeGitUnstaged",    { fg = "#e2c08d" })           -- amber: hay cambios sin stagear
		hl("NeoTreeGitStaged",      { fg = "#a6e22e" })           -- bright green: listo para commit
		hl("NeoTreeGitChangeType",  { fg = "#e2c08d" })
		-- (NeoTreeDirectoryIcon/Directory/Normal definidos en sección NEO-TREE arriba)
		-- GitSigns: columna de signos — monokai muted (menos saturados)
		hl("GitSignsAdd",              { fg = "#81b88b" })
		hl("GitSignsChange",           { fg = "#e2c08d" })
		hl("GitSignsDelete",           { fg = "#c74e39" })
		hl("GitSignsAddNr",            { fg = "#81b88b" })
		hl("GitSignsChangeNr",         { fg = "#e2c08d" })
		hl("GitSignsDeleteNr",         { fg = "#c74e39" })
		hl("GitSignsAddLn",            { bg = "#1a2e1a" })
		hl("GitSignsChangeLn",         { bg = "#2a2510" })
		hl("GitSignsStagedAdd",        { fg = "#a6e22e" })
		hl("GitSignsStagedChange",     { fg = "#a6e22e" })
		hl("GitSignsStagedDelete",     { fg = "#a6e22e" })
		hl("GitSignsCurrentLineBlame", { fg = "#75715e", italic = true })

		-- ────────────────────────────────────────────────────────────────────────
		-- NVIM-WEB-DEVICONS — paleta catppuccin refinada Kanagawa para Sublime
		-- Colores por extensión: sapphire (#74c7ec) para langs principales (warm fit monokai)
		-- Same semantic mapping as MiniIcons above — consistencia total
		-- ────────────────────────────────────────────────────────────────────────
		local ok_dev, devicons = pcall(require, "nvim-web-devicons")
		if ok_dev then
			devicons.setup({
				override_by_extension = {
					lua       = { icon = "󰢱", color = "#74c7ec", name = "Lua" },        -- sapphire
					ts        = { icon = "󰛦", color = "#74c7ec", name = "TypeScript" }, -- sapphire
					js        = { icon = "󰌞", color = "#f9e2af", name = "JavaScript" }, -- yellow
					tsx       = { icon = "󰛦", color = "#74c7ec", name = "TSX" },
					jsx       = { icon = "󰌞", color = "#f9e2af", name = "JSX" },
					py        = { icon = "󰌠", color = "#cba6f7", name = "Python" },     -- mauve
					rs        = { icon = "󱘗", color = "#fab387", name = "Rust" },       -- peach/orange
					go        = { icon = "󰟓", color = "#74c7ec", name = "Go" },         -- sapphire
					cs        = { icon = "󰌛", color = "#74c7ec", name = "CSharp" },     -- sapphire
					cpp       = { icon = "󰙲", color = "#74c7ec", name = "CPP" },
					c         = { icon = "󰙱", color = "#74c7ec", name = "C" },
					html      = { icon = "󰌝", color = "#fab387", name = "Html" },       -- peach (warm)
					css       = { icon = "󰌜", color = "#cba6f7", name = "CSS" },        -- mauve
					scss      = { icon = "󰟦", color = "#f38ba8", name = "SCSS" },       -- red
					json      = { icon = "󰘦", color = "#a6e3a1", name = "JSON" },       -- green
					yaml      = { icon = "󰈙", color = "#a6e3a1", name = "YAML" },       -- green
					toml      = { icon = "󰘦", color = "#fab387", name = "TOML" },       -- peach
					md        = { icon = "󰍔", color = "#74c7ec", name = "Markdown" },   -- sapphire
					sh        = { icon = "󱩾", color = "#a6e3a1", name = "Shell" },      -- green
					vim       = { icon = "", color = "#a6e3a1", name = "Vim" },        -- green
					nvim      = { icon = "", color = "#a6e3a1", name = "Nvim" },       -- green
					sql       = { icon = "󰆼", color = "#74c7ec", name = "SQL" },        -- sapphire
					gitignore = { icon = "󰊢", color = "#75715e", name = "GitIgnore" },  -- olive dim
					env       = { icon = "󰙴", color = "#f9e2af", name = "Env" },        -- yellow
					log       = { icon = "󰋽", color = "#75715e", name = "Log" },        -- olive dim
					txt       = { icon = "󰈙", color = "#c2c2bf", name = "Text" },       -- neutral
				},
			})
		end

		-- ── Italic garantizado — defer_fn 150ms aplica DESPUÉS de TODO ──────────
		-- vim.schedule no es suficiente: plugins VeryLazy cargan DESPUÉS del ColorScheme
		-- y pueden pisar italic. defer_fn 150ms garantiza ser lo ÚLTIMO en ejecutarse.
		vim.defer_fn(function()
			local cmt = "#75715e"
			-- Legacy syntax (cuando treesitter NO está activo en el buffer)
			vim.api.nvim_set_hl(0, "Comment",       { fg = cmt, italic = true })
			vim.api.nvim_set_hl(0, "SpecialComment", { fg = cmt, italic = true, bold = true })
			-- Treesitter captures (cuando treesitter SÍ está activo)
			vim.api.nvim_set_hl(0, "@comment",               { fg = cmt, italic = true })
			vim.api.nvim_set_hl(0, "@comment.line",          { fg = cmt, italic = true })
			vim.api.nvim_set_hl(0, "@comment.block",         { fg = cmt, italic = true })
			vim.api.nvim_set_hl(0, "@comment.documentation", { fg = cmt, italic = true })
			vim.api.nvim_set_hl(0, "@lsp.type.comment",      { fg = cmt, italic = true })
			-- Keywords italic — storage.type firma Monokai ST3
			vim.api.nvim_set_hl(0, "@keyword",             { fg = "#e05577", italic = true })
			vim.api.nvim_set_hl(0, "@keyword.function",    { fg = "#66d9ef", italic = true })
			vim.api.nvim_set_hl(0, "@keyword.storage",     { fg = "#66d9ef", italic = true })
			vim.api.nvim_set_hl(0, "@keyword.modifier",    { fg = "#66d9ef", italic = true })
			vim.api.nvim_set_hl(0, "@keyword.coroutine",   { fg = "#66d9ef", italic = true })
			vim.api.nvim_set_hl(0, "@keyword.return",      { fg = "#e05577", italic = true })
			vim.api.nvim_set_hl(0, "@keyword.import",      { fg = "#e05577", italic = true })
			vim.api.nvim_set_hl(0, "@keyword.repeat",      { fg = "#e05577", italic = true })
			vim.api.nvim_set_hl(0, "@keyword.conditional", { fg = "#e05577", italic = true })
			-- Parameters italic — ST3: variable.parameter = orange italic
			vim.api.nvim_set_hl(0, "@variable.parameter", { fg = "#fd971f", italic = true })
			vim.api.nvim_set_hl(0, "@lsp.type.parameter",  { fg = "#fd971f", italic = true })
			vim.api.nvim_set_hl(0, "@lsp.type.typeParameter", { fg = "#fd971f", italic = true })
		end, 150)
	end,
})

-- ─── Markdown: syntax highlights nivel Monokai Night (ref: syntax.json) ─────
-- Fuente: syntax.json textMateRules adaptadas a Neovim @markup.* + markdown* + RenderMarkdown*
-- Paleta EXACTA de Monokai Night — mismos hex que syntax.json, sin aproximaciones
-- Dispara en ColorScheme * → aplica para CUALQUIER tema activo (catppuccin/kanagawa/sonokai)
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	group = augroup("markdown_highlights"),
	callback = function()
		local h = function(name, opts) vim.api.nvim_set_hl(0, name, opts) end
		-- Paleta Monokai Night exacta (ref: syntax.json)
		local red    = "#F92672"  -- bullets, blockquote, keywords
		local green  = "#A6E22E"  -- bold, italic, checked [x], functions
		local cyan   = "#66D9EF"  -- links, ordered list numbers, code lang ID
		local orange = "#FD9621"  -- heading # marker, inline code content, params
		local violet = "#967EFB"  -- numbered list content, nested bullets, footnotes
		local gray   = "#75715E"  -- comments, strikethrough text, unchecked [ ]
		local dim    = "#5A5A54"  -- strikethrough delimiters, link brackets [ ], HR ---
		local silver = "#BDBDBD"  -- heading text H2+, table body, fence closing
		local white  = "#E0E0E0"  -- body text, heading H1 text
		local bright = "#F8F8F2"  -- inline code backtick, code fence opening
		local purple = "#AE81FF"  -- numbers, constants

		-- @markup.* — Treesitter markdown captures
		-- Headings: paleta Monokai completa por nivel (H1=keyword red → H6=violet)
		-- Razon: jerarquia visual semantica — el mismo codigo de color que el lenguaje usa
		-- para keywords(red)/accent(cyan)/funciones(green)/strings(orange)/constantes(purple)
		h("@markup.heading",                { fg = white,  bold = true })
		h("@markup.heading.1.markdown",     { fg = red,    bold = true })  -- keywords red
		h("@markup.heading.2.markdown",     { fg = cyan,   bold = true })  -- accent cyan
		h("@markup.heading.3.markdown",     { fg = green,  bold = true })  -- funciones green
		h("@markup.heading.4.markdown",     { fg = orange, bold = true })  -- params orange
		h("@markup.heading.5.markdown",     { fg = purple, bold = true })  -- constantes purple
		h("@markup.heading.6.markdown",     { fg = violet, bold = true })  -- violet
		h("@markup.heading.marker",         { fg = orange })
		h("@markup.bold",                   { bold = true })                         -- style-only
		h("@markup.italic",                 { italic = true })                       -- style-only
		h("@markup.strikethrough",          { fg = gray,   strikethrough = true })
		-- inline code: orange + bg sutil para distinction visual (ref: JetBrains/Rider)
		-- bg="#272822" = Monokai bg original, 1 nivel arriba de "#1e1f1c" → no quiebra blur
		h("@markup.raw.inline",             { fg = orange, bg = "#272822" })
		h("@markup.raw.block",              { fg = silver })
		h("@markup.link",                   { fg = cyan })
		h("@markup.link.url",               { fg = cyan,   underline = true })
		h("@markup.link.label",             { fg = violet, italic = true })
		h("@markup.list",                   { fg = red })
		h("@markup.list.checked",           { fg = green })
		h("@markup.list.unchecked",         { fg = gray })
		h("@markup.quote",                  { fg = red,    italic = true })
		h("@markup.math",                   { fg = violet })
		-- Task 3: comentarios HTML <!-- --> en Markdown — italic garantizado
		-- @comment captura los nodos 'comment' en la injeccion HTML del gramatica Markdown
		-- Explicito aqui porque catppuccin base puede sobreescribir el valor en algunos casos
		h("@comment",                       { fg = gray,   italic = true })
		h("@comment.html",                  { fg = gray,   italic = true })

		-- markdown* — Legacy vim highlight groups
		h("markdownHeadingDelimiter",       { fg = orange })
		h("markdownH1",                     { fg = white,  bold = true })
		h("markdownH2",                     { fg = white,  bold = true })
		h("markdownH3",                     { fg = silver, bold = true })
		h("markdownH4",                     { fg = silver, bold = true })
		h("markdownH5",                     { fg = silver, bold = true })
		h("markdownH6",                     { fg = silver, bold = true })
		h("markdownBold",                   { fg = green,  bold = true })
		h("markdownItalic",                 { fg = green,  italic = true })
		h("markdownBoldItalic",             { fg = green,  bold = true, italic = true })
		h("markdownCode",                   { fg = orange })
		h("markdownCodeBlock",              { fg = silver })
		h("markdownCodeDelimiter",          { fg = bright })
		h("markdownBlockquote",             { fg = red,    italic = true })
		h("markdownListMarker",             { fg = red })
		h("markdownOrderedListMarker",      { fg = cyan })
		h("markdownRule",                   { fg = dim,    bold = true })
		h("markdownUrl",                    { fg = cyan,   underline = true })
		h("markdownLinkText",               { fg = cyan })
		h("markdownLinkTextDelimiter",      { fg = dim })
		h("markdownLinkDelimiter",          { fg = dim })
		h("markdownIdDeclaration",          { fg = violet })

		-- RenderMarkdown* — render-markdown.nvim groups
		-- Fg: alineados con @markup.heading.N (misma jerarquia cromatica)
		-- Bg: tints sutiles derivados del color del heading sobre el bg Sublime #1e1f1c
		--     Calculo: blend(heading_color, #1e1f1c, 8%) → visible en opaco y en blur
		h("RenderMarkdownH1",               { fg = red,    bold = true })
		h("RenderMarkdownH2",               { fg = cyan,   bold = true })
		h("RenderMarkdownH3",               { fg = green,  bold = true })
		h("RenderMarkdownH4",               { fg = orange, bold = true })
		h("RenderMarkdownH5",               { fg = purple, bold = true })
		h("RenderMarkdownH6",               { fg = violet, bold = true })
		-- Bg tints: lo suficientemente visibles para demarcar la linea del heading
		-- lo suficientemente sutiles para no competir con el contenido
		h("RenderMarkdownH1Bg",             { bg = "#2a1820" })  -- red tint
		h("RenderMarkdownH2Bg",             { bg = "#152528" })  -- cyan tint
		h("RenderMarkdownH3Bg",             { bg = "#1a2710" })  -- green tint
		h("RenderMarkdownH4Bg",             { bg = "#2a2010" })  -- orange tint
		h("RenderMarkdownH5Bg",             { bg = "#201828" })  -- purple tint
		h("RenderMarkdownH6Bg",             { bg = "#271520" })  -- violet tint
		-- Code: bg="#272822" = Monokai original bg (ligeramente mas claro que #1e1f1c)
		-- Visible tanto con Normal transparente (blur WezTerm) como con bg solido
		h("RenderMarkdownCode",             { bg = "#272822" })
		h("RenderMarkdownCodeInline",       { fg = orange, bg = "#272822" })
		h("RenderMarkdownBullet",           { fg = red })
		h("RenderMarkdownLink",             { fg = cyan,   underline = true })
		h("RenderMarkdownTodo",             { fg = orange, bold = true })
		h("RenderMarkdownQuote",            { fg = red,    italic = true })
		h("RenderMarkdownDash",             { fg = dim,    bold = true })
		h("RenderMarkdownTableHead",        { fg = cyan,   bold = true })
		h("RenderMarkdownTableRow",         { fg = silver })
		h("RenderMarkdownTableFill",        { fg = dim })
		-- Checkboxes: verde=completado, gris=pendiente (alineado con @markup.list.*)
		h("RenderMarkdownChecked",          { fg = green })
		h("RenderMarkdownUnchecked",        { fg = gray })
		-- Callouts: colores semanticos Monokai (mismos que diagnosticos LSP)
		h("RenderMarkdownCalloutNote",      { fg = cyan,   bold = true })
		h("RenderMarkdownCalloutWarning",   { fg = orange, bold = true })
		h("RenderMarkdownCalloutTip",       { fg = green,  bold = true })
		h("RenderMarkdownCalloutImportant", { fg = purple, bold = true })
		h("RenderMarkdownCalloutCaution",   { fg = red,    bold = true })
		h("RenderMarkdownSign",             { fg = cyan })
	end,
})

-- ─── Catppuccin: italic garantizado — timing-safe ────────────────────────────
-- PROBLEMA: autocmds.lua se carga via User LazyVimAutocmds (DESPUÉS de que catppuccin
-- ya disparó ColorScheme en startup). Un ColorScheme autocmd no catchea el startup.
-- SOLUCIÓN: función definida una vez, invocada en DOS contextos:
--   1. Directamente al cargar autocmds.lua (post-LazyVimAutocmds = colorscheme ya activo)
--   2. Vía ColorScheme handler para cambios manuales de tema en runtime
local function catppuccin_italic_overrides()
	if not (vim.g.colors_name and vim.g.colors_name:find("catppuccin")) then return end
	local hl = function(name, def) vim.api.nvim_set_hl(0, name, def) end
	-- ── Comentarios: overlay0 + italic — firma Sublime Text 3 ───────────
	hl("Comment",                     { fg = "#6c7086", italic = true })
	hl("@comment",                    { fg = "#6c7086", italic = true })
	hl("@comment.line",               { fg = "#6c7086", italic = true })
	hl("@comment.block",              { fg = "#6c7086", italic = true })
	hl("@comment.documentation",      { fg = "#89dceb", italic = true }) -- sky: JSDoc/docstrings resaltan
	hl("SpecialComment",              { fg = "#6c7086", italic = true })
	hl("@lsp.type.comment",           { fg = "#6c7086", italic = true })
	-- ── Keywords: mauve + italic ──────────────────────────────────────────
	hl("Keyword",                     { fg = "#cba6f7", italic = true })
	hl("Statement",                   { fg = "#cba6f7", italic = true })
	hl("Conditional",                 { fg = "#cba6f7", italic = true })
	hl("Repeat",                      { fg = "#cba6f7", italic = true })
	hl("StorageClass",                { fg = "#cba6f7", italic = true })
	hl("Include",                     { fg = "#94e2d5", italic = true }) -- teal: import/using/require
	-- ── Parameters: peach + italic — firma ST3 (orange lane) ─────────────
	hl("@variable.parameter",         { fg = "#fab387", italic = true })
	hl("@variable.parameter.builtin", { fg = "#fab387", bold = true, italic = true })
	hl("@lsp.type.parameter",         { fg = "#fab387", italic = true })
	-- ── Builtins: italic = "magia del lenguaje" ──────────────────────────
	hl("@function.builtin",           { fg = "#fab387", italic = true })
	hl("@variable.builtin",           { fg = "#cba6f7", italic = true })
	-- ── Inlay hints: Half-intensity italic ───────────────────────────────
	hl("LspInlayHint",                { fg = "#7f849c", bg = "NONE", italic = true })
end

-- Guard: solo aplicar si el tema FINAL es catppuccin (no sublime u otro overlay)
-- Problema: sublime.lua llama vim.cmd.colorscheme("catppuccin") → dispara ColorScheme catppuccin*
-- → schedula catppuccin_italic_overrides → pero para entonces vim.g.colors_name ya es "sublime"
-- → catppuccin_italic_overrides sobreescribiría los highlights de Sublime (keywords mauve vs red)
local function safe_catppuccin_italic()
	vim.defer_fn(function()
		if (vim.g.colors_name or ""):find("^catppuccin") then
			catppuccin_italic_overrides()
		end
	end, 150)
end

-- 1. Invocación directa al cargar autocmds.lua
--    User LazyVimAutocmds dispara DESPUÉS de que el colorscheme ya está activo → timing correcto
safe_catppuccin_italic()

-- 2. Autocmd para cambios manuales de tema en runtime (:colorscheme catppuccin)
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("CatppuccinItalicFinal", { clear = true }),
	pattern = "catppuccin*",
	callback = safe_catppuccin_italic,
})
-- ─── ShaDa: limpieza preventiva de archivos tmp (Windows bug) ──────────────────────────
-- En Windows, crashes dejan main.shada.tmp.X huérfanos → E138 al salir.
-- Fix: eliminar en VimEnter solo los de más de 1 hora (evita borrar los de otra sesión activa).
vim.api.nvim_create_autocmd("VimEnter", {
	group = vim.api.nvim_create_augroup("shada_cleanup", { clear = true }),
	once = true,
	callback = function()
		local shada_dir = vim.fn.stdpath("data") .. "/shada"
		local files = vim.fn.glob(shada_dir .. "/main.shada.tmp.*", false, true)
		for _, f in ipairs(files) do
			local age = os.time() - vim.fn.getftime(f)
			if age > 3600 then -- older than 1 hour → huérfano seguro
				os.remove(f)
			end
		end
	end,
})

-- ─── Sublime startup timing fix ─────────────────────────────────────────────────────────
-- autocmds.lua carga en VeryLazy — después de que LazyVim aplica colorscheme.
-- sublime_overrides aun no existía cuando se disparó ColorScheme en startup.
-- Fix idéntico al de catppuccin_italic_overrides: re-disparar si ya es sublime.
vim.schedule(function()
	if (vim.g.colors_name or "") == "sublime" then
		vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "sublime", modeline = false })
	end
end)
