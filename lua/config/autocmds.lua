-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

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
-- Modos de vista controlados con <leader>mr (Raw → Hybrid → Reader)
-- Estado inicial: Hybrid (índice 2) → render activo, cursor line muestra raw
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	group = augroup("markdown_ux"),
	callback = function()
		-- Sin swap file en markdown: evita el dialogo multi-swap al abrir .md
		-- (los .md estan en git → crash recovery es redundante aqui)
		vim.opt_local.swapfile = false
		-- Raw por defecto: ves la sintaxis completa, sin renderizado
		-- <leader>mr cicla: Raw(1) -> Hybrid(2) -> Reader(3)
		vim.opt_local.conceallevel = 0
		vim.opt_local.concealcursor = ""
		vim.b.md_view_state = 1
		-- Tipografía de lectura
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
		vim.opt_local.textwidth = 0
		-- Sin números de línea relativos en modo lectura (opcional, comenta si prefieres)
		-- vim.opt_local.relativenumber = false

		-- <C-LeftMouse> y gx: manejados globalmente en keymaps.lua (sin timing issues).
		-- <C-]>: buffer-local en markdown — redirige a gx para evitar E426.
		--   Ctrl+] no tiene uso real en markdown (tags = C), lo mandamos a gx.
		vim.keymap.set(
			"n",
			"<C-]>",
			"gx",
			{ buffer = true, silent = true, remap = true, desc = "Open URL / redirect from tag lookup" }
		)
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
		hl("NeoTreeCursorLine",    { bg = M.bg_cur })
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
