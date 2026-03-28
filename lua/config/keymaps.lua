-- Keymaps - loaded on VeryLazy event
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

----- SCROLL + CENTER -----
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

----- ESCAPE universal -----
vim.keymap.set({ "i", "n" }, "<C-c>", [[<C-\><C-n>]])

-- <C-q> TERMINAL MODE: oculta el panel Claude si el buffer activo es Claude.
-- Si no es Claude, pasa <C-q> al proceso (XON/DC1 — algunos shells lo usan).
-- Complementa el snacks_win_opts.keys en claudecode.lua (cobertura total).
vim.keymap.set("t", "<C-q>", function()
	if vim.api.nvim_buf_get_name(0):find("claude", 1, true) then
		vim.api.nvim_win_hide(vim.api.nvim_get_current_win())
	else
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-q>", true, true, true), "t", false)
	end
end, { desc = "Claude: hide panel (terminal mode)" })

-- <C-q> INSERT MODE: muestra/inicia Claude sin salir de insert mode.
-- El float abre encima del cursor, regresando al texto cuando se cierra.
vim.keymap.set("i", "<C-q>", function()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local cfg = vim.api.nvim_win_get_config(win)
		if
			vim.api.nvim_buf_get_name(buf):find("claude", 1, true)
			and vim.bo[buf].buftype == "terminal"
			and cfg.relative ~= ""
		then
			vim.api.nvim_win_hide(win)
			return
		end
	end
	vim.cmd("ClaudeCode")
end, { desc = "Claude: toggle panel (insert mode)" })

----- CLIPBOARD: Ctrl+C/X/V/A — estilo VS Code -----
vim.keymap.set("v", "<C-c>", '"+y<Esc>', { desc = "Copy to clipboard" })
vim.keymap.set("v", "<C-x>", '"+d', { desc = "Cut to clipboard" })
vim.keymap.set("n", "<C-v>", '"+p', { desc = "Paste from clipboard" })
vim.keymap.set("i", "<C-v>", "<C-r>+", { desc = "Paste from clipboard (insert)" })
vim.keymap.set("v", "<C-v>", '"+p', { desc = "Paste over selection" })
vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Select all" })

----- SELECCIÓN: Shift+flechas estilo VS Code -----
vim.keymap.set("n", "<S-Right>", "v<Right>", { desc = "Select char right" })
vim.keymap.set("n", "<S-Left>", "v<Left>", { desc = "Select char left" })
vim.keymap.set("n", "<S-Up>", "v<Up>", { desc = "Select line up" })
vim.keymap.set("n", "<S-Down>", "v<Down>", { desc = "Select line down" })
vim.keymap.set("v", "<S-Right>", "<Right>", { desc = "Extend right" })
vim.keymap.set("v", "<S-Left>", "<Left>", { desc = "Extend left" })
vim.keymap.set("v", "<S-Up>", "<Up>", { desc = "Extend up" })
vim.keymap.set("v", "<S-Down>", "<Down>", { desc = "Extend down" })

----- HOME / END + SHIFT -----
vim.keymap.set({ "n", "v" }, "<Home>", "^", { desc = "First non-blank char" })
vim.keymap.set({ "n", "v" }, "<End>", "$", { desc = "End of line" })
vim.keymap.set("i", "<Home>", "<C-o>^", { desc = "First non-blank (insert)" })
vim.keymap.set("i", "<End>", "<C-o>$", { desc = "End of line (insert)" })
vim.keymap.set("n", "<S-Home>", "v^", { desc = "Select to line start" })
vim.keymap.set("n", "<S-End>", "v$h", { desc = "Select to line end" })
vim.keymap.set("v", "<S-Home>", "^", { desc = "Extend to line start" })
vim.keymap.set("v", "<S-End>", "$h", { desc = "Extend to line end" })

----- SAVE -----
vim.keymap.set({ "n", "i" }, "<C-s>", function()
	if vim.fn.empty(vim.fn.expand("%:t")) == 1 then
		-- Buffer sin nombre → Save As (igual que VS Code)
		vim.ui.input({ prompt = "Save as: ", completion = "file" }, function(name)
			if not name or name == "" then
				return
			end
			local ok, err = pcall(vim.cmd, "saveas " .. vim.fn.fnameescape(name))
			if ok then
				vim.notify(vim.fn.expand("%:t") .. " saved!", vim.log.levels.INFO)
			else
				vim.notify("Error: " .. err, vim.log.levels.ERROR)
			end
		end)
		return
	end
	local ok, err = pcall(vim.cmd, "silent! wall")
	if ok then
		vim.notify("All buffers saved", vim.log.levels.INFO)
	else
		vim.notify("Error: " .. err, vim.log.levels.ERROR)
	end
end, { desc = "Save all buffers / Save As (unnamed)" })

----- SPLIT NAVIGATION: Ctrl+Alt+Arrows -----
vim.keymap.set("n", "<C-A-Left>", "<C-w>h", { desc = "Go to left split" })
vim.keymap.set("n", "<C-A-Down>", "<C-w>j", { desc = "Go to lower split" })
vim.keymap.set("n", "<C-A-Up>", "<C-w>k", { desc = "Go to upper split" })
vim.keymap.set("n", "<C-A-Right>", "<C-w>l", { desc = "Go to right split" })

----- SPLIT RESIZE: Ctrl+Shift+Arrows — context-aware, equivalente a VS Code -----
-- La flecha indica la dirección en que se mueve el borde ACTIVO del panel:
--   Panel izquierdo  (neo-tree, leftmost):  borde activo = DERECHO  → Right=crecer, Left=encoger
--   Panel derecho    (main, rightmost):     borde activo = IZQUIERDO → Left=crecer,  Right=encoger
--   Panel superior   (main con terminal):   borde activo = INFERIOR  → Down=crecer,  Up=encoger
--   Panel inferior   (terminal, bottommost): borde activo = SUPERIOR → Up=crecer,    Down=encoger
-- mini.animate intercepta :resize/:vertical resize → animación cubic premium automática.
local _RS = 4  -- paso (cols/filas por keypress)

local function _resize_h(dir)
	-- rightmost: borde activo = izquierdo → flecha izquierda = crecer (XOR invierte lógica)
	local rightmost = vim.fn.winnr() == vim.fn.winnr("l")
	local grow = (dir == "right") ~= rightmost
	vim.cmd("vertical resize " .. (grow and "+" or "-") .. _RS)
end

local function _resize_v(dir)
	-- bottommost: borde activo = superior → flecha arriba = crecer (XOR invierte lógica)
	local bottommost = vim.fn.winnr() == vim.fn.winnr("j")
	local grow = (dir == "down") ~= bottommost
	vim.cmd("resize " .. (grow and "+" or "-") .. _RS)
end

vim.keymap.set("n", "<C-S-Left>",  function() _resize_h("left")  end, { silent = true, desc = "Resize split ←" })
vim.keymap.set("n", "<C-S-Right>", function() _resize_h("right") end, { silent = true, desc = "Resize split →" })
vim.keymap.set("n", "<C-S-Up>",    function() _resize_v("up")    end, { silent = true, desc = "Resize split ↑" })
vim.keymap.set("n", "<C-S-Down>",  function() _resize_v("down")  end, { silent = true, desc = "Resize split ↓" })

----- SPLIT NAVIGATION: Ctrl+hjkl -----
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left split" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower split" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper split" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right split" })

----- COPY PATH -----
vim.keymap.set("n", "<leader>yp", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify(path, vim.log.levels.INFO, { title = "Path copied" })
end, { desc = "Copy absolute path" })

vim.keymap.set("n", "<leader>yr", function()
	local path = vim.fn.expand("%:.")
	vim.fn.setreg("+", path)
	vim.notify(path, vim.log.levels.INFO, { title = "Relative path copied" })
end, { desc = "Copy relative path" })

vim.keymap.set("n", "<leader>yn", function()
	local name = vim.fn.expand("%:t")
	vim.fn.setreg("+", name)
	vim.notify(name, vim.log.levels.INFO, { title = "Filename copied" })
end, { desc = "Copy filename" })

----- GX + CTRL+CLICK: abrir URLs y links internos de Markdown -----
-- Estrategia:
--   1) Buscar [texto](target) en la linea bajo el cursor
--      → https?:// → abre en browser con vim.ui.open()
--      → path local → abre en Neovim con :edit (relativo al dir del archivo actual)
--   2) Si no hay markdown link, buscar URL con <cfile> y <cWORD>
--      → https?:// → abre en browser
-- vim.ui.open() es nativo de Neovim 0.10+, usa explorer.exe en Windows.
-- <C-LeftMouse> y <C-S-LeftMouse> son GLOBALES (sin timing issues de autocmd).
-- WezTerm con mouse=a pasa todos los clicks a Neovim — este handler los atrapa.
local function _open_url_at_cursor()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1

	-- Paso 1: buscar markdown link [texto](target) bajo el cursor
	local md_target = nil
	local s = 1
	while s <= #line do
		local ms, me, link = line:find("%[.-%]%((.-)%)", s)
		if not ms then
			break
		end
		if col >= ms and col <= me and link ~= "" then
			md_target = link
			break
		end
		s = me + 1
	end

	if md_target then
		-- URL externa → browser
		if md_target:match("^https?://") then
			vim.ui.open(md_target)
			return true
		end
		-- Funcion para buscar heading por slug en el buffer actual
		local function goto_heading(slug)
			local words = {}
			for w in slug:gmatch("[^-]+") do
				table.insert(words, w)
			end
			if #words == 0 then
				return
			end
			local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			for i, l in ipairs(lines) do
				if l:match("^#") then
					local lower = l:lower()
					local pos = 1
					local all_found = true
					for _, w in ipairs(words) do
						local found = lower:find(w:lower(), pos, true)
						if not found then
							all_found = false
							break
						end
						pos = found + #w
					end
					if all_found then
						vim.api.nvim_win_set_cursor(0, { i, 0 })
						vim.cmd("normal! zz")
						return
					end
				end
			end
			vim.notify("Heading no encontrado: #" .. slug, vim.log.levels.WARN)
		end
		-- Separar path y ancla #heading
		local path, anchor = md_target:match("^(.-)#(.+)$")
		if not path then
			path = md_target
			anchor = nil
		end
		-- Ancla al mismo archivo (ej: #mi-seccion)
		if path == "" then
			if anchor then
				goto_heading(anchor)
			end
			return true
		end
		-- Path con archivo → resolver relativo al dir actual
		local dir = vim.fn.expand("%:p:h")
		local resolved = vim.fs.normalize(dir .. "/" .. path)
		if vim.fn.filereadable(resolved) == 1 then
			vim.cmd("edit " .. vim.fn.fnameescape(resolved))
			if anchor then
				goto_heading(anchor)
			end
		else
			vim.notify("Archivo no encontrado: " .. resolved, vim.log.levels.WARN)
		end
		return true
	end

	-- Paso 2: sin markdown link, buscar URL externa con <cfile> / <cWORD>
	local target = vim.fn.expand("<cfile>")
	if not target:match("^https?://") then
		local word = vim.fn.expand("<cWORD>")
		local url = word:match("(https?://[^%s\"'<>%(%)%[%]{}]+)")
		if url then
			target = url
		end
	end
	if target ~= "" and target:match("^https?://") then
		vim.ui.open(target)
		return true
	end
	return false
end

vim.keymap.set("n", "gx", _open_url_at_cursor, { desc = "Open URL/link under cursor" })

-- Ctrl+Click: EXCLUSIVO para URLs y links Markdown (Evita conflictos)
local function _open_url_mouse()
	local pos = vim.fn.getmousepos()
	if pos.winid ~= 0 then
		vim.api.nvim_set_current_win(pos.winid)
		vim.api.nvim_win_set_cursor(pos.winid, { pos.line, pos.column - 1 })
	end
	_open_url_at_cursor()
end

-- Ctrl+Shift+Click: Atrás (Go Back) como lo pediste expresamente
vim.keymap.set("n", "<C-LeftMouse>", _open_url_mouse, { desc = "Ctrl+Click: Open URL/Markdown Link" })
vim.keymap.set("n", "<C-S-LeftMouse>", "<C-o>", { desc = "Ctrl+Shift+Click: Go Back (Like Ctrl+o)" })

----- NAVEGACION ADELANTE / ATRAS (EQUIVALENTE A VSCODE) -----
-- Ya corregimos wezterm.lua para que no intercepte Ctrl+Shift+-
-- Ctrl + Shift + - (Atrás) -> equivale a <C-o> en Neovim
-- Ctrl + Shift + + (Adelante) -> equivale a <C-i> en Neovim
vim.keymap.set("n", "<C-S-->", "<C-o>", { desc = "Go to Previous Location (VSCode Back)" })
vim.keymap.set("n", "<C-S-+>", "<C-i>", { desc = "Go to Next Location (VSCode Forward)" })

----- MINI.FILES (explorador flotante, reemplaza oil) -----
-- Abre mini.files en el directorio del buffer actual (o CWD si no hay archivo)
-- Presiona `-` de nuevo para subir al directorio padre (dentro de mini.files)
vim.keymap.set("n", "-", function()
	local buf = vim.api.nvim_buf_get_name(0)
	require("mini.files").open(buf ~= "" and buf or vim.uv.cwd())
end, { desc = "Browse files (mini.files)" })

----- SEARCH IN FILE: Ctrl+F — panel centrado flotante -----
-- Flujo:
--   <C-f>/<leader>/  → panel flotante centrado (glassmorphism via winblend)
--   Escribe          → fuzzy search en tiempo real, resultados con contexto de línea
--   ↑↓               → navega; el buffer debajo sigue el cursor (preview nativo)
--   Enter            → salta + TODOS los matches quedan resaltados (n/N con [2/8])
--   <C-r>            → transición a Find & Replace: cierra y abre grug-far con el patrón actual
--   Esc              → cierra sin saltar
--
-- Fix: picker.filter es un método Lua, no tabla → llamar picker:filter() para obtener el objeto

-- ─── SEARCH: Ctrl+F — panel flotante centrado ────────────────────────────────
-- Enter  → salta a la línea + highlights persistentes (n/N con contador [2/8])
-- <C-h>  → abre grug-far con el patrón ya escrito (transición a replace)
local _SEARCH_LAYOUT = {
	layout = {
		box = "vertical", width = 0.65, min_width = 60, height = 0.55, row = 0.18,
		border = "rounded", title = "  Search in File ", title_pos = "center",
		{ win = "input", height = 1, border = "bottom" },
		{ win = "list",  border = "none" },
	},
}

local function _lines_panel()
	local ok, sn = pcall(require, "snacks")
	if not ok then return end
	sn.picker.lines({
		layout = _SEARCH_LAYOUT,
		win = {
			input = {
				wo   = { winblend = 12 },
				keys = {
					-- <C-h> dentro del panel: abre grug-far con el patrón actual
					["<C-h>"] = {
						function(picker)
							local ok2, f = pcall(function() return picker:filter() end)
							local pattern = ""
							if ok2 and type(f) == "table" then
								local ok3, pat = pcall(function() return f:pattern() end)
								pattern = (ok3 and pat) or f.pattern or f.search or ""
							end
							picker:close()
							vim.schedule(function()
								require("grug-far").open({
									prefills = {
										search = pattern,
										paths  = vim.fn.expand("%"),
									},
								})
							end)
						end,
						mode = { "i", "n" },
						desc = "→ Find & Replace (grug-far)  [C-h]",
					},
				},
			},
			list = { wo = { winblend = 12 } },
		},
		confirm = function(picker, item)
			local ok2, f = pcall(function() return picker:filter() end)
			local pattern = ""
			if ok2 and type(f) == "table" then
				local ok3, pat = pcall(function() return f:pattern() end)
				pattern = (ok3 and pat) or f.pattern or f.search or ""
			end
			picker:close()
			vim.schedule(function()
				if item and item.pos then
					vim.api.nvim_win_set_cursor(0, item.pos)
					vim.cmd("normal! zz")
				end
				if pattern ~= "" then
					vim.fn.setreg("/", pattern)
					vim.opt.hlsearch = true
					pcall(function() require("hlslens").start() end)
				end
			end)
		end,
	})
end
vim.keymap.set({ "n", "i", "v" }, "<C-f>",    _lines_panel, { desc = "Search in file  [C-f]" })
vim.keymap.set("n",               "<leader>/", _lines_panel, { desc = "Search in file  [C-f]" })

-- ─── SEARCH IN PROJECT: Ctrl+Shift+F — panel flotante con preview de sintaxis ─
-- Layout horizontal: lista a la izquierda, preview del archivo a la derecha
-- Preview: treesitter syntax highlight, scroll con Ctrl+d/u
-- <C-h> dentro: transición a grug-far replace con el patrón ya escrito
-- <C-f> dentro: vuelve a buscar solo en el archivo actual
local _GREP_LAYOUT = {
	layout = {
		box = "horizontal",
		width = 0.90, min_width = 100, height = 0.75, row = 0.08,
		border = "rounded", title = "  Search in Project ", title_pos = "center",
		{
			box = "vertical",
			{ win = "input", height = 1, border = "bottom" },
			{ win = "list",  border = "none" },
		},
		{ win = "preview", width = 0.48, border = "left" },
	},
}

local function _grep_panel(opts)
	local ok, sn = pcall(require, "snacks")
	if not ok then return end
	sn.picker.grep(vim.tbl_extend("force", {
		layout = _GREP_LAYOUT,
		win = {
			input   = {
				wo = { winblend = 12 },
				keys = {
					-- <C-h>: abre grug-far replace con el patrón actual
					["<C-h>"] = {
						function(picker)
							local ok2, f = pcall(function() return picker:filter() end)
							local pattern = ok2 and type(f) == "table" and (pcall(function() return f:pattern() end) and f:pattern() or f.search or "") or ""
							picker:close()
							vim.schedule(function()
								require("grug-far").open({ prefills = { search = pattern } })
							end)
						end,
						mode = { "i", "n" }, desc = "→ Find & Replace (grug-far)  [C-h]",
					},
				},
			},
			list    = { wo = { winblend = 12 } },
			preview = { wo = { winblend = 12 } },
		},
	}, opts or {}))
end

vim.keymap.set({ "n", "i" }, "<C-S-f>", _grep_panel, { desc = "Search in project  [C-S-f]" })
vim.keymap.set("v", "<C-S-f>", function()
	-- grep la selección visual actual
	local ok, lines = pcall(vim.fn.getregion, vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.visualmode() })
	_grep_panel({ search = ok and table.concat(lines, " ") or "" })
end, { desc = "Search selection in project  [C-S-f]" })
-- Grep palabra bajo cursor → proyecto (reemplaza el grug-far anterior para solo búsqueda)
vim.keymap.set("n", "<leader>sw", function()
	_grep_panel({ search = vim.fn.expand("<cword>") })
end, { desc = "Search word under cursor in project  [sw]" })

-- ─── FIND & REPLACE: Ctrl+H — grug-far ───────────────────────────────────────
-- grug-far: dos campos (Search + Replace), preview en vivo, Replace / Replace All,
-- regex, multi-archivo, undo nativo. La rueda ya existe — no reinventarla.
-- Pre-carga la palabra bajo el cursor. Aplica al archivo actual por defecto.
vim.keymap.set({ "n", "i", "v" }, "<C-h>", function()
	require("grug-far").open({
		prefills = {
			search = vim.fn.expand("<cword>"),
			paths  = vim.fn.expand("%"),
		},
	})
end, { desc = "Find & Replace (grug-far)  [C-h]" })

----- UNDO / REDO: estilo VS Code (Ctrl+Z / Ctrl+Y) -----
-- Reemplaza el comportamiento default de nvim (u / C-r) con los atajos universales.
-- En insert mode usamos C-o para ejecutar un comando normal sin salir del modo.
vim.keymap.set({ "n", "v" }, "<C-z>", "u",           { desc = "Undo  [C-z]" })
vim.keymap.set({ "n", "v" }, "<C-y>", "<C-r>",       { desc = "Redo  [C-y]" })
vim.keymap.set("i",          "<C-z>", "<C-o>u",      { desc = "Undo (insert)  [C-z]" })
vim.keymap.set("i",          "<C-y>", "<C-o><C-r>",  { desc = "Redo (insert)  [C-y]" })

----- BUFFERS -----
vim.keymap.set("n", "<leader>bq", '<esc>:%bdelete|edit #|normal`"<cr>', { desc = "Close other buffers" })

-- ─── Ctrl+Tab: panel picker de buffers estilo VS Code ─────────────────────
-- Tabs "ocultas": no hay barra visual permanente
-- Ctrl+Tab abre panel central flotante con todos los buffers abiertos
-- Dentro del panel: Ctrl+Tab/Ctrl+Shift+Tab navegan; Enter selecciona
local _BUF_PICKER_LAYOUT = {
	layout = {
		box = "vertical", width = 0.50, min_width = 50, height = 0.45, row = 0.25,
		border = "rounded", title = "  Buffers ", title_pos = "center",
		{ win = "input", height = 1, border = "bottom" },
		{ win = "list",  border = "none" },
	},
}
local function _buf_picker()
	local ok, sn = pcall(require, "snacks")
	if not ok then return end
	sn.picker.buffers({
		layout = _BUF_PICKER_LAYOUT,
		win = {
			input = {
				wo = { winblend = 12 },
				keys = {
					["<C-Tab>"]   = { "list_down", mode = { "n", "i" } },
					["<C-S-Tab>"] = { "list_up",   mode = { "n", "i" } },
				},
			},
			list = { wo = { winblend = 12 } },
		},
	})
end
vim.keymap.set("n", "<C-Tab>",   _buf_picker, { desc = "Buffer picker panel  [C-Tab]" })
vim.keymap.set("n", "<C-S-Tab>", _buf_picker, { desc = "Buffer picker panel  [C-S-Tab]" })

-- Ctrl+Shift+W: cerrar TODOS los buffers (VS Code style)
-- Detecta modificados → ofrece: guardar todo y cerrar / cerrar sin guardar / cancelar
vim.keymap.set("n", "<C-S-w>", function()
	local modified = vim.tbl_filter(function(b)
		return vim.bo[b].modified and vim.bo[b].buflisted
	end, vim.api.nvim_list_bufs())
	local n = #modified
	local prompt = n > 0
		and (" " .. n .. " buffer" .. (n > 1 and "s" or "") .. " sin guardar")
		or " Cerrar todos los buffers"
	local opts = n > 0
		and { "Guardar todo y cerrar", "Cerrar sin guardar", "Cancelar" }
		or  { "Cerrar todos", "Cancelar" }
	vim.ui.select(opts, { prompt = prompt }, function(choice)
		if choice == "Guardar todo y cerrar" then
			vim.cmd("silent! wall")
			vim.cmd("silent! %bd!")
		elseif choice == "Cerrar sin guardar" or choice == "Cerrar todos" then
			vim.cmd("silent! %bd!")
		end
	end)
end, { desc = "Close all buffers (confirm)  [C-S-w]" })

----- UI -----
-- Theme toggle: Catppuccin ↔ Sonokai
vim.keymap.set("n", "<leader>uT", function()
	local current = vim.g.colors_name or ""
	if current:find("catppuccin") then
		vim.cmd("colorscheme sonokai")
		-- devicons + lualine los maneja el ColorScheme autocmd de sonokai
		vim.notify("  Sonokai Atlantis — Monokai Pro", vim.log.levels.INFO, { title = "Theme" })
	else
		-- Restaurar devicons a defaults (el handler sonokai los sobrescribió)
		local ok_dev, devicons = pcall(require, "nvim-web-devicons")
		if ok_dev then
			devicons.setup({ override_by_extension = {} })
		end
		-- Lualine: LazyVim theme="auto" detecta catppuccin automáticamente al restaurar
		vim.cmd("colorscheme catppuccin")
		vim.notify("  Catppuccin Mocha Premium", vim.log.levels.INFO, { title = "Theme" })
	end
end, { desc = "Toggle theme (Catppuccin ↔ Sonokai)" })

-- ─── EXPLORER TOGGLE: Ctrl+Up — equivalente a Ctrl+B en VS Code ─────────────
-- Slide-in/out: animación propia a 83fps con cubic easing (ease-out al abrir,
-- ease-in al cerrar). Desactiva mini.animate resize en el buffer neo-tree durante
-- el slide para evitar doble animación.
-- highlight_opened_files="all" (ya configurado en neo-tree) equivale al panel
-- "OPEN EDITORS" de VS Code: archivos abiertos aparecen resaltados en el árbol.
local _NT_W = 26  -- debe coincidir con neo-tree window.width

local function _nt_slide(win_id, target_w, duration_ms, easing, on_done)
	local start_w = vim.api.nvim_win_is_valid(win_id) and vim.api.nvim_win_get_width(win_id) or 1
	if start_w == target_w then
		if on_done then on_done() end
		return
	end
	-- Deshabilitar mini.animate resize en este buffer → evita doble animación
	local buf = vim.api.nvim_win_is_valid(win_id) and vim.api.nvim_win_get_buf(win_id) or nil
	if buf then
		pcall(vim.api.nvim_buf_set_var, buf, "minianimate_config", { resize = { enable = false } })
	end
	local interval_ms = 12  -- ~83fps
	local steps = math.max(2, math.ceil(duration_ms / interval_ms))
	local step = 0
	local timer = vim.uv.new_timer()
	timer:start(0, interval_ms, vim.schedule_wrap(function()
		if not vim.api.nvim_win_is_valid(win_id) then
			timer:stop()
			timer:close()
			return
		end
		step = step + 1
		local t = math.min(1.0, step / steps)
		local et = easing == "in"
			and (t * t * t)                          -- ease-in: lento → rápido (cerrar)
			or  (1 - (1 - t) * (1 - t) * (1 - t))  -- ease-out: rápido → lento (abrir)
		local new_w = math.max(1, math.floor(start_w + (target_w - start_w) * et))
		vim.api.nvim_win_set_width(win_id, new_w)
		if step >= steps then
			timer:stop()
			timer:close()
			if vim.api.nvim_win_is_valid(win_id) then
				vim.api.nvim_win_set_width(win_id, target_w)
			end
			if buf and vim.api.nvim_buf_is_valid(buf) then
				pcall(vim.api.nvim_buf_del_var, buf, "minianimate_config")
			end
			if on_done then on_done() end
		end
	end))
end

-- <leader>e: neo-tree slide toggle (sobreescribe el keys spec de neo-tree.lua)
-- VeryLazy carga keymaps.lua después de los plugins → tiene precedencia.
local function _nt_toggle()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
			_nt_slide(win, 1, 120, "in", function()
				pcall(require("neo-tree.command").execute, { action = "close" })
			end)
			return
		end
	end
	require("neo-tree.command").execute({ action = "show", dir = vim.uv.cwd(), source = "filesystem" })
	vim.schedule(function()
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
				vim.api.nvim_win_set_width(win, 1)
				_nt_slide(win, _NT_W, 190, "out", nil)
				break
			end
		end
	end)
end
vim.keymap.set("n", "<leader>e", _nt_toggle, { silent = true, desc = "Explorer: slide toggle  [<leader>e]" })
vim.keymap.set("n", "<leader>E", function()
	require("neo-tree.command").execute({ toggle = true, dir = vim.fn.expand("%:p:h") })
end, { silent = true, desc = "Explorer NeoTree (cwd)" })

-- ─── ARCHIVOS RECIENTES + PROYECTO: Ctrl+Up — equivalente a VS Code Ctrl+P ──
-- Panel flotante central: archivos recientes primero, luego todos los del proyecto.
-- mini.animate lo anima automáticamente con slide quartic al abrir/cerrar.
-- Toggle: re-presionar Ctrl+Up cierra el panel si ya está abierto.
local _SMART_LAYOUT = {
	layout = {
		box = "vertical",
		width = 0.58, min_width = 60, height = 0.52, row = 0.17,
		border = "rounded", title = "  Archivos Recientes + Proyecto ", title_pos = "center",
		{ win = "input", height = 1, border = "bottom" },
		{ win = "list",  border = "none" },
	},
}
vim.keymap.set({ "n", "i" }, "<C-Up>", function()
	local ok, sn = pcall(require, "snacks")
	if not ok then return end
	-- Toggle: si hay picker activo, cerrarlo
	if sn.picker.get then
		local active = sn.picker.get()
		if #active > 0 then
			for _, p in ipairs(active) do pcall(function() p:close() end) end
			return
		end
	end
	sn.picker.smart({
		layout = _SMART_LAYOUT,
		win = {
			input = {
				wo = { winblend = 12 },
				keys = { ["<C-Up>"] = { "close", mode = { "n", "i" } } },
			},
			list = { wo = { winblend = 12 } },
		},
	})
end, { silent = true, desc = "Recent + Project files  [C-Up]" })

-- ─── COMMAND CENTER: <leader>cc ──────────────────────────────────────────────
-- Ctrl+Shift+P de VS Code pero superior: fuzzy sobre TODAS las acciones del stack.
-- Escribe categoría ("git", "debug", "yazi") o acción ("grep", "diff", "breakpoint").
-- Enter → ejecuta. Esc → cierra. Categorías con color propio (Catppuccin lanes).
vim.keymap.set("n", "<leader>cc", function()
	local ok_s, snacks = pcall(require, "snacks")
	if not ok_s then
		return
	end

	-- ── Toggle: si hay un picker activo (command center abierto), cerrarlo ──────
	-- snacks.picker.get() devuelve todos los pickers activos del stack
	if snacks.picker.get then
		local active = snacks.picker.get()
		if #active > 0 then
			for _, picker in ipairs(active) do
				pcall(function()
					picker:close()
				end)
			end
			return
		end
	end

	local p = snacks.picker

	-- ── Título dinámico con rama git activa ────────────────────────────────────
	local _r = vim.fn.systemlist("git branch --show-current")
	local branch = (vim.v.shell_error == 0 and _r[1] or ""):gsub("\27%[[%d;]*m", ""):gsub("%s+$", "")
	local title = #branch > 0 and "󱓞  Command Center   " .. branch or "󱓞  Command Center"

	-- ── Colores por categoría — Catppuccin Mocha color lanes ──────────────────
	-- Files/Yazi=green  Git=peach  LSP/API=blue  Search=teal  Claude=yellow
	-- Debug=red  Notes=lavender  UI=mauve  Config=dim
	local cat_hl = {
		Files = "@string", -- green
		Yazi = "DiagnosticOk", -- green
		Search = "Identifier", -- teal
		Git = "DiagnosticWarn", -- peach
		LSP = "DiagnosticInfo", -- blue
		Debug = "DiagnosticError", -- red
		API = "@function", -- blue
		Notes = "Title", -- lavender/bold
		UI = "Special", -- mauve
		Claude = "WarningMsg", -- yellow
		Config = "Comment", -- dim
		Font = "@type", -- yellow/type color
	}

	-- Font switcher: escribe ~/.nvim_font → WezTerm recarga automático
	local function set_font(key, label)
		local path = vim.fn.expand("~") .. "\\.nvim_font"
		local f = io.open(path, "w")
		if f then
			f:write(key)
			f:close()
		end
		vim.notify(
			"Font → " .. label .. "\nWezTerm recargará automáticamente",
			vim.log.levels.INFO,
			{ title = "Font" }
		)
	end

	local function cmd(icon, cat, label, action)
		return { icon = icon, cat = cat, name = label, text = cat .. " " .. label, action = action }
	end

	local items = {
		-- ── Files ─────────────────────────────────────────────────────────────
		cmd(" ", "Files", "Abrir archivo (smart)", function()
			p.smart()
		end),
		cmd(" ", "Files", "Archivos recientes", function()
			p.recent()
		end),
		cmd(" ", "Files", "Buscar en proyecto (grep)", function()
			p.grep()
		end),
		cmd(" ", "Files", "Buffers abiertos", function()
			p.buffers()
		end),
		cmd(" ", "Files", "Mini.files (explorador flotante)", function()
			local buf = vim.api.nvim_buf_get_name(0)
			require("mini.files").open(buf ~= "" and buf or vim.uv.cwd())
		end),
		-- ── Yazi ──────────────────────────────────────────────────────────────
		cmd(" ", "Yazi", "Archivo actual (reveal)", function()
			vim.cmd("Yazi")
		end),
		cmd(" ", "Yazi", "CWD del proyecto", function()
			vim.cmd("Yazi cwd")
		end),
		cmd(" ", "Yazi", "Retomar sesión anterior", function()
			vim.cmd("Yazi toggle")
		end),
		-- ── Search & Replace ──────────────────────────────────────────────────
		cmd(" ", "Search", "Keymaps", function()
			p.keymaps()
		end),
		cmd(" ", "Search", "Comandos vim", function()
			p.commands()
		end),
		cmd(" ", "Search", "Ayuda (help tags)", function()
			p.help()
		end),
		cmd(" ", "Search", "Highlights activos", function()
			p.highlights()
		end),
		cmd(" ", "Search", "Undo history (árbol)", function()
			p.undo()
		end),
		cmd("󰛔 ", "Search", "Find & Replace global (grug-far)", function()
			local ok, grug = pcall(require, "grug-far")
			if ok then
				grug.open()
			else
				vim.notify("grug-far no instalado", vim.log.levels.WARN)
			end
		end),
		-- ── Git ───────────────────────────────────────────────────────────────
		cmd(" ", "Git", "Status", function()
			p.git_status()
		end),
		cmd(" ", "Git", "Log del proyecto", function()
			p.git_log()
		end),
		cmd(" ", "Git", "Archivos git-tracked", function()
			p.git_files()
		end),
		cmd(" ", "Git", "Ramas", function()
			p.git_branches()
		end),
		cmd("󰻂 ", "Git", "Diffview — diff actual", function()
			vim.cmd("DiffviewOpen")
		end),
		cmd("󰻂 ", "Git", "Diffview — historial archivo", function()
			vim.cmd("DiffviewFileHistory %")
		end),
		-- ── LSP ───────────────────────────────────────────────────────────────
		cmd(" ", "LSP", "Símbolos (buffer)", function()
			p.lsp_symbols()
		end),
		cmd(" ", "LSP", "Símbolos (workspace)", function()
			p.lsp_workspace_symbols()
		end),
		cmd(" ", "LSP", "Diagnósticos (buffer)", function()
			p.diagnostics({ buf = 0 })
		end),
		cmd(" ", "LSP", "Diagnósticos (workspace)", function()
			p.diagnostics()
		end),
		cmd(" ", "LSP", "Referencias bajo cursor", function()
			p.lsp_references()
		end),
		cmd(" ", "LSP", "Implementaciones", function()
			p.lsp_implementations()
		end),
		-- ── Debug (DAP) ───────────────────────────────────────────────────────
		cmd(" ", "Debug", "Continue / Start session", function()
			pcall(function()
				require("dap").continue()
			end)
		end),
		cmd(" ", "Debug", "Toggle breakpoint", function()
			pcall(function()
				require("dap").toggle_breakpoint()
			end)
		end),
		cmd(" ", "Debug", "Step over", function()
			pcall(function()
				require("dap").step_over()
			end)
		end),
		cmd(" ", "Debug", "Step into", function()
			pcall(function()
				require("dap").step_into()
			end)
		end),
		cmd(" ", "Debug", "DAP UI toggle", function()
			pcall(function()
				require("dapui").toggle()
			end)
		end),
		-- ── API HTTP (Kulala) ──────────────────────────────────────────────────
		cmd("󰛿 ", "API", "HTTP Scratchpad (nuevo)", function()
			pcall(function()
				require("kulala").scratchpad()
			end)
		end),
		cmd("󰛿 ", "API", "Enviar request actual", function()
			pcall(function()
				require("kulala").run()
			end)
		end),
		-- ── Notes (Obsidian) ──────────────────────────────────────────────────
		cmd("󱓧 ", "Notes", "Buscar nota", function()
			vim.cmd("ObsidianSearch")
		end),
		cmd("󱓧 ", "Notes", "Quick switch nota", function()
			vim.cmd("ObsidianQuickSwitch")
		end),
		cmd("󱓧 ", "Notes", "Nueva nota", function()
			vim.cmd("ObsidianNew")
		end),
		cmd("󱓧 ", "Notes", "Backlinks de nota actual", function()
			vim.cmd("ObsidianBacklinks")
		end),
		-- ── UI / Ventanas ─────────────────────────────────────────────────────
		cmd(" ", "UI", "Terminal flotante", function()
			pcall(function()
				require("toggleterm").toggle(1, nil, nil, "float")
			end)
		end),
		cmd(" ", "UI", "Explorador (neo-tree)", function()
			vim.cmd("Neotree toggle")
		end),
		cmd("󰹊 ", "UI", "Cambiar colorscheme", function()
			p.colorschemes()
		end),
		cmd(" ", "UI", "Zen mode", function()
			vim.cmd("ZenMode")
		end),
		cmd(" ", "UI", "Twilight (foco párrafo)", function()
			vim.cmd("Twilight")
		end),
		cmd(" ", "UI", "Screenkey toggle", function()
			vim.cmd("Screenkey")
		end),
		-- ── Claude AI ─────────────────────────────────────────────────────────
		cmd("󰚩 ", "Claude", "Toggle panel", function()
			vim.cmd("ClaudeCode")
		end),
		cmd("󰚩 ", "Claude", "Focus panel", function()
			vim.cmd("ClaudeCodeFocus")
		end),
		cmd("󰚩 ", "Claude", "Agregar buffer al contexto", function()
			vim.cmd("ClaudeCodeAdd %")
		end),
		cmd("󰚩 ", "Claude", "Resume sesión", function()
			vim.cmd("ClaudeCode --resume")
		end),
		cmd("󰚩 ", "Claude", "Seleccionar modelo", function()
			vim.cmd("ClaudeCodeSelectModel")
		end),
		cmd("󰚩 ", "Claude", "Aceptar diff (yes)", function()
			vim.cmd("ClaudeCodeDiffAccept")
		end),
		-- ── Font (WezTerm switcher via ~/.nvim_font) ──────────────────────────
		cmd(" ", "Font", "UbuntuSansMono — variable font, true Medium (ACTIVA)", function()
			set_font("ubuntu", "UbuntuSansMono Nerd Font")
		end),
		cmd(" ", "Font", "IosevkaTerm — condensada, 9 pesos reales, densidad +20%", function()
			set_font("iosevka", "IosevkaTerm Nerd Font")
		end),
		-- ── Config ────────────────────────────────────────────────────────────
		cmd("󰒲 ", "Config", "Lazy plugins", function()
			vim.cmd("Lazy")
		end),
		cmd(" ", "Config", "Mason (LSP servers)", function()
			vim.cmd("Mason")
		end),
		cmd(" ", "Config", "Abrir init.lua", function()
			vim.cmd("edit " .. vim.fn.stdpath("config") .. "/init.lua")
		end),
		cmd(" ", "Config", "Abrir keymaps.lua", function()
			vim.cmd("edit " .. vim.fn.stdpath("config") .. "/lua/config/keymaps.lua")
		end),
	}

	p.pick(nil, {
		title = title,
		items = items,
		format = function(item, _)
			local hl = cat_hl[item.cat] or "Comment"
			return {
				{ item.icon, hl = hl },
				{ " [" .. item.cat .. "]", hl = hl },
				{ " › " .. item.name, hl = "Normal" },
			}
		end,
		confirm = function(picker, item)
			picker:close()
			vim.schedule(item.action)
		end,
		-- preview=false: son acciones, no archivos — evita "item has no file/path" errors
		preview = false,
		-- CRÍTICO: keys deben ir en win.input.keys (top-level keys no se aplican al buffer)
		win = {
			input = {
				keys = {
					["<Esc>"] = { "close", mode = { "n", "i" } }, -- cierra en cualquier modo
					["<leader>cc"] = { "close", mode = { "n", "i" } }, -- toggle: <leader>cc de nuevo cierra
					["<C-c>"] = { "close", mode = { "n", "i" } },
					-- <C-/> = cambiar a buscador de líneas en archivo (VS Code Ctrl+F premium)
					["<C-/>"] = {
						function(picker)
							picker:close()
							vim.schedule(function()
								local ok, sn = pcall(require, "snacks")
								if ok then
									sn.picker.lines()
								end
							end)
						end,
						mode = { "n", "i" },
					},
				},
			},
		},
		layout = { preset = "dropdown", preview = false },
	})
end, { desc = "Command Center  [<leader>cc]" })

----- ENGRAM: memoria persistente + dashboard neural -----
-- <leader>eg → lanza serve.py (maneja duplicados, puerto y browser internamente)
vim.keymap.set("n", "<leader>eg", function()
	local python = "C:/Python313/python.exe"
	local script = vim.fn.expand("~/Documents/Obsidian/JaedenNotes/serve.py")
	vim.fn.jobstart({ python, script }, {
		detach = true,
		cwd = vim.fn.expand("~/Documents/Obsidian/JaedenNotes"),
	})
	vim.notify("Engram dashboard starting...", vim.log.levels.INFO)
end, { desc = "Engram: dashboard" })

-- <leader>es → búsqueda engram en terminal flotante
vim.keymap.set("n", "<leader>es", function()
	local ok, sn = pcall(require, "snacks")
	if not ok then return end
	vim.ui.input({ prompt = "Engram search: " }, function(query)
		if not query or query == "" then return end
		sn.terminal({ "engram", "search", query }, {
			win = { position = "float", height = 0.5, width = 0.7, title = " Engram Search " },
		})
	end)
end, { desc = "Engram: buscar en memoria  [es]" })

-- <leader>ec → contexto reciente de engram en terminal flotante
vim.keymap.set("n", "<leader>ec", function()
	local ok, sn = pcall(require, "snacks")
	if not ok then return end
	sn.terminal({ "engram", "context" }, {
		win = { position = "float", height = 0.5, width = 0.7, title = " Engram Context " },
	})
end, { desc = "Engram: ver contexto reciente  [ec]" })

----- SALIDA CONFIRMADA -----
-- <leader>qq: pide confirmacion antes de cerrar todo nvim
-- Si hay buffers sin guardar, vim.opt.confirm=true ya lo maneja antes
vim.keymap.set("n", "<leader>qq", function()
	local unsaved = vim.tbl_count(vim.tbl_filter(function(buf)
		return vim.bo[buf].modified and vim.bo[buf].buflisted
	end, vim.api.nvim_list_bufs()))
	if unsaved > 0 then
		-- confirm=true en options.lua ya pregunta por cada unsaved buffer
		vim.cmd("qa")
	else
		vim.ui.input({ prompt = "Salir de Neovim? [s/N] " }, function(input)
			if input and (input:lower() == "s" or input:lower() == "y") then
				vim.cmd("qa!")
			end
		end)
	end
end, { desc = "Quit all (confirm)" })

-- ZQ: cierre forzado sin guardar siempre pide confirmacion
vim.keymap.set("n", "ZQ", function()
	vim.ui.input({ prompt = "Cerrar sin guardar? [s/N] " }, function(input)
		if input and (input:lower() == "s" or input:lower() == "y") then
			vim.cmd("q!")
		end
	end)
end, { desc = "Quit without saving (confirm)" })

-- <C-w>: cierra buffer actual (VS Code style Ctrl+W)
-- mini.bufremove.delete: PRESERVA la ventana (cambia al buffer anterior)
--   sin mini.bufremove: fallback → bprevious + bdelete (mismo efecto, seguro)
-- Buffers especiales (neo-tree, terminal, qf): usa :q normal de Neovim
-- Si hay cambios sin guardar: ofrece guardar / descartar / cancelar.
local function _close_buf(buf, force)
	-- mini.bufremove es el estándar LazyVim: preserva splits/layout
	local ok = pcall(require("mini.bufremove").delete, buf, force)
	if not ok then
		-- Fallback: cambiar al buffer previo antes de borrar para no colapsar la ventana
		local alt = vim.fn.bufnr("#")
		if alt ~= -1 and alt ~= buf and vim.fn.buflisted(alt) == 1 then
			vim.api.nvim_win_set_buf(0, alt)
		else
			pcall(vim.cmd, "bprevious")
		end
		pcall(vim.cmd, (force and "bdelete! " or "bdelete ") .. buf)
	end
end

vim.keymap.set("n", "<C-w>", function()
	local buf = vim.api.nvim_get_current_buf()
	-- Buffers especiales: delegar a :q (cierra la ventana, comportamiento esperado)
	if vim.bo[buf].buftype ~= "" then
		pcall(vim.cmd, "q")
		return
	end
	if vim.bo[buf].modified then
		vim.ui.select(
			{ "Guardar y cerrar", "Cerrar sin guardar", "Cancelar" },
			{ prompt = " Cambios sin guardar — ¿qué hacemos?" },
			function(choice)
				if choice == "Guardar y cerrar" then
					vim.cmd("silent! write")
					_close_buf(buf, false)
				elseif choice == "Cerrar sin guardar" then
					_close_buf(buf, true)
				end
			end
		)
	else
		_close_buf(buf, false)
	end
end, { desc = "Close buffer (VS Code style)  [C-w]" })

----- MOVER LINEA: Alt+Arriba/Abajo -----
vim.keymap.set("n", "<A-Up>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })
vim.keymap.set("n", "<A-Down>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
vim.keymap.set("i", "<A-Up>", "<C-o>:m .-2<CR>", { silent = true, desc = "Move line up (insert)" })
vim.keymap.set("i", "<A-Down>", "<C-o>:m .+1<CR>", { silent = true, desc = "Move line down (insert)" })

----- DUPLICAR LINEA: Ctrl+= / Ctrl++ (VS Code style) -----
vim.keymap.set("n", "<C-=>", "yyp", { desc = "Duplicate line" })
vim.keymap.set("i", "<C-=>", "<C-o>yyp", { desc = "Duplicate line (insert)" })
vim.keymap.set("v", "<C-=>", function()
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	vim.cmd("'<,'>copy '>")
	-- cursor is on last pasted line; re-select the duplicated block
	local count = end_line - start_line
	local keys = "V" .. (count > 0 and (count .. "k") or "")
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end, { silent = true, desc = "Duplicate selection (VS Code style)" })

----- BORRAR LINEA SIN CLIPBOARD: Ctrl+- -----
vim.keymap.set("n", "<C-->", '"_dd', { desc = "Delete line (no clipboard)" })
vim.keymap.set("i", "<C-->", '<C-o>"_dd', { desc = "Delete line (no clipboard, insert)" })

----- COMENTAR/DESCOMENTAR: Ctrl+7 -----
vim.keymap.set("n", "<C-7>", "gcc", { remap = true, silent = true, desc = "Toggle comment" })
vim.keymap.set("v", "<C-7>", "gc", { remap = true, silent = true, desc = "Toggle comment (visual)" })
vim.keymap.set("i", "<C-7>", "<C-o>gcc", { remap = true, silent = true, desc = "Toggle comment (insert)" })

----- DISABLE: Alt+j/k line move (interfiere con workflow) -----
for _, mode in ipairs({ "i", "n", "x" }) do
	vim.keymap.set(mode, "<A-j>", "<nop>", { silent = true })
	vim.keymap.set(mode, "<A-k>", "<nop>", { silent = true })
end
vim.keymap.set("x", "J", "<nop>", { silent = true })
vim.keymap.set("x", "K", "<nop>", { silent = true })

----- PAGE UP/DOWN: media página (~15 líneas), llega a gg/G en los bordes -----
-- step = floor(height/2): más granular que página completa, consistente con <C-d>/<C-u>
-- En el borde (dentro de step líneas del inicio/fin) → gg / G directo.
vim.keymap.set({ "n", "v" }, "<PageUp>", function()
	local ns = require("neoscroll")
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local step = math.floor(vim.api.nvim_win_get_height(0) / 2)
	if line <= step then
		vim.cmd("normal! gg")
	else
		ns.scroll(-step, { move_cursor = true, duration = 180 })
	end
end, { silent = true, desc = "Page up (half-page, → gg at top)" })

vim.keymap.set({ "n", "v" }, "<PageDown>", function()
	local ns = require("neoscroll")
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local total = vim.api.nvim_buf_line_count(0)
	local step = math.floor(vim.api.nvim_win_get_height(0) / 2)
	if line + step >= total then
		vim.cmd("normal! G")
	else
		ns.scroll(step, { move_cursor = true, duration = 180 })
	end
end, { silent = true, desc = "Page down (half-page, → G at bottom)" })

----- REMOVE LazyVim resize defaults: Ctrl+Arrow -----
-- LazyVim mapea <C-Left>/<C-Right>/<C-Down> a resize — conflicta con navegación por palabras.
-- Resize ya está en <C-S-Arrow> (definido arriba). <C-Up> está sobreescrito por command center.
-- pcall: no falla si LazyVim no definió el keymap en este entorno.
for _, key in ipairs({ "<C-Left>", "<C-Right>", "<C-Down>" }) do
	pcall(vim.keymap.del, "n", key)
end
