-- Keymaps - loaded on VeryLazy event
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

----- SCROLL + CENTER -----
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

----- ESCAPE universal -----
vim.keymap.set({ "i", "n" }, "<C-c>", [[<C-\><C-n>]])

-- <Esc> COMMAND MODE: Esc nativo cancela el comando, vim.schedule limpia Noice después.
-- Fix para Noice cmdline/búsqueda que quedan visibles ("pegadas") con cmdheight=0.
-- expr=true → devuelve la tecla real a Vim (no interrumpe el flujo nativo de cancelación).
vim.keymap.set("c", "<Esc>", function()
  vim.schedule(function()
    pcall(function() require("noice").cmd("dismiss") end)
  end)
  return "<Esc>"
end, { expr = true, desc = "Cancel cmd + cleanup Noice popup" })

-- <LeftMouse> COMMAND MODE: click en cualquier lugar cancela el cmdline (mismo efecto que Esc).
-- Fix crítico: con cmdheight=0 + Noice, el cmdline float queda "pegado" al hacer click fuera.
-- Aplica también a búsqueda (/), continue prompt (>), y cualquier modo c.
vim.keymap.set("c", "<LeftMouse>", "<Esc>", { desc = "Click to cancel cmdline" })

-- <Esc> TERMINAL MODE:
--   Claude buffer  → passthrough al proceso (Claude usa Esc para su navegación interna)
--   Otro float     → cierra la ventana directamente (1 sola tecla, sin doble-Esc)
--   Split terminal → <C-\><C-n> para volver a modo normal
vim.keymap.set("t", "<Esc>", function()
  if vim.api.nvim_buf_get_name(0):find("claude", 1, true) then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, true, true), "t", false)
  elseif vim.api.nvim_win_get_config(0).relative ~= "" then
    pcall(vim.api.nvim_win_close, 0, false)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[<C-\><C-n>]], true, true, true), "n", false)
  end
end, { desc = "Esc: Claude passthrough / float close / split normal" })

-- <Esc> NORMAL MODE:
--   Dentro de float (mini.files) → cierra sesión completa del explorador
--   Dentro de otro float        → cierra la ventana (toggleterm normal, Lazy, Mason, etc.)
--   Ventana normal              → nohlsearch + descarta mensajes/notificaciones de Noice
-- Snacks picker y Command Center manejan su propio Esc via win.input.keys (ui.lua / keymaps.lua).
vim.keymap.set("n", "<Esc>", function()
  if vim.api.nvim_win_get_config(0).relative ~= "" then
    local buf_name = vim.api.nvim_buf_get_name(0)
    if not buf_name:find("claude", 1, true) then
      if vim.bo.filetype == "minifiles" then
        pcall(require("mini.files").close)
      else
        pcall(vim.api.nvim_win_close, 0, false)
      end
      return
    end
  end
  vim.cmd("nohlsearch")
  pcall(function() require("noice").cmd("dismiss") end)
end, { desc = "Esc: close float / clear search / dismiss noice" })

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
    if vim.api.nvim_buf_get_name(buf):find("claude", 1, true)
      and vim.bo[buf].buftype == "terminal"
      and cfg.relative ~= "" then
      vim.api.nvim_win_hide(win)
      return
    end
  end
  vim.cmd("ClaudeCode")
end, { desc = "Claude: toggle panel (insert mode)" })

----- CLIPBOARD: Ctrl+C/X/V/A — estilo VS Code -----
vim.keymap.set("v", "<C-c>", '"+y<Esc>', { desc = "Copy to clipboard" })
vim.keymap.set("v", "<C-x>", '"+d',      { desc = "Cut to clipboard" })
vim.keymap.set("n", "<C-v>", '"+p',      { desc = "Paste from clipboard" })
vim.keymap.set("i", "<C-v>", "<C-r>+",   { desc = "Paste from clipboard (insert)" })
vim.keymap.set("v", "<C-v>", '"+p',      { desc = "Paste over selection" })
vim.keymap.set("n", "<C-a>", "ggVG",     { desc = "Select all" })

----- SELECCIÓN: Shift+flechas estilo VS Code -----
vim.keymap.set("n", "<S-Right>", "v<Right>", { desc = "Select char right" })
vim.keymap.set("n", "<S-Left>",  "v<Left>",  { desc = "Select char left"  })
vim.keymap.set("n", "<S-Up>",    "v<Up>",    { desc = "Select line up"    })
vim.keymap.set("n", "<S-Down>",  "v<Down>",  { desc = "Select line down"  })
vim.keymap.set("v", "<S-Right>", "<Right>",  { desc = "Extend right" })
vim.keymap.set("v", "<S-Left>",  "<Left>",   { desc = "Extend left"  })
vim.keymap.set("v", "<S-Up>",    "<Up>",     { desc = "Extend up"    })
vim.keymap.set("v", "<S-Down>",  "<Down>",   { desc = "Extend down"  })

----- HOME / END + SHIFT -----
vim.keymap.set({"n","v"}, "<Home>", "^",       { desc = "First non-blank char" })
vim.keymap.set({"n","v"}, "<End>",  "$",       { desc = "End of line"          })
vim.keymap.set("i",       "<Home>", "<C-o>^",  { desc = "First non-blank (insert)" })
vim.keymap.set("i",       "<End>",  "<C-o>$",  { desc = "End of line (insert)"     })
vim.keymap.set("n", "<S-Home>", "v^",  { desc = "Select to line start" })
vim.keymap.set("n", "<S-End>",  "v$h", { desc = "Select to line end"   })
vim.keymap.set("v", "<S-Home>", "^",   { desc = "Extend to line start" })
vim.keymap.set("v", "<S-End>",  "$h",  { desc = "Extend to line end"   })

----- SAVE -----
vim.keymap.set({ "n", "i" }, "<C-s>", function()
  if vim.fn.empty(vim.fn.expand("%:t")) == 1 then
    -- Buffer sin nombre → Save As (igual que VS Code)
    vim.ui.input({ prompt = "Save as: ", completion = "file" }, function(name)
      if not name or name == "" then return end
      local ok, err = pcall(vim.cmd, "saveas " .. vim.fn.fnameescape(name))
      if ok then
        vim.notify(vim.fn.expand("%:t") .. " saved!", vim.log.levels.INFO)
      else
        vim.notify("Error: " .. err, vim.log.levels.ERROR)
      end
    end)
    return
  end
  local ok, err = pcall(vim.cmd, "silent! write")
  if ok then
    vim.notify(vim.fn.expand("%:t") .. " saved!")
  else
    vim.notify("Error: " .. err, vim.log.levels.ERROR)
  end
end, { desc = "Save file / Save As (unnamed)" })

----- SPLIT NAVIGATION: Ctrl+Alt+Arrows -----
vim.keymap.set("n", "<C-A-Left>", "<C-w>h", { desc = "Go to left split" })
vim.keymap.set("n", "<C-A-Down>", "<C-w>j", { desc = "Go to lower split" })
vim.keymap.set("n", "<C-A-Up>", "<C-w>k", { desc = "Go to upper split" })
vim.keymap.set("n", "<C-A-Right>", "<C-w>l", { desc = "Go to right split" })

----- SPLIT RESIZE: Ctrl+Shift+Arrows -----
vim.keymap.set("n", "<C-S-Left>", "<cmd>vertical resize -3<cr>", { desc = "Shrink split left" })
vim.keymap.set("n", "<C-S-Right>", "<cmd>vertical resize +3<cr>", { desc = "Grow split right" })
vim.keymap.set("n", "<C-S-Up>", "<cmd>resize +3<cr>", { desc = "Grow split up" })
vim.keymap.set("n", "<C-S-Down>", "<cmd>resize -3<cr>", { desc = "Shrink split down" })

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
  local col  = vim.api.nvim_win_get_cursor(0)[2] + 1

  -- Paso 1: buscar markdown link [texto](target) bajo el cursor
  local md_target = nil
  local s = 1
  while s <= #line do
    local ms, me, link = line:find("%[.-%]%((.-)%)", s)
    if not ms then break end
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
      for w in slug:gmatch("[^-]+") do table.insert(words, w) end
      if #words == 0 then return end
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
      if anchor then goto_heading(anchor) end
      return true
    end
    -- Path con archivo → resolver relativo al dir actual
    local dir = vim.fn.expand("%:p:h")
    local resolved = vim.fs.normalize(dir .. "/" .. path)
    if vim.fn.filereadable(resolved) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(resolved))
      if anchor then goto_heading(anchor) end
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
    if url then target = url end
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
vim.keymap.set("n", "<C-LeftMouse>",   _open_url_mouse, { desc = "Ctrl+Click: Open URL/Markdown Link" })
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

----- BUFFERS -----
vim.keymap.set("n", "<leader>bq", '<esc>:%bdelete|edit #|normal`"<cr>', { desc = "Close other buffers" })

----- UI -----
-- Theme toggle: Catppuccin ↔ Sonokai
vim.keymap.set("n", "<leader>uT", function()
  local current = vim.g.colors_name or ""
  if current:find("catppuccin") then
    vim.cmd("colorscheme sonokai")
    -- devicons + lualine los maneja el ColorScheme autocmd de sonokai
    vim.notify("  Sonokai Atlantis — Monokai Pro", vim.log.levels.INFO, {title="Theme"})
  else
    -- Restaurar devicons a defaults (el handler sonokai los sobrescribió)
    local ok_dev, devicons = pcall(require, "nvim-web-devicons")
    if ok_dev then devicons.setup({ override_by_extension = {} }) end
    -- Lualine: LazyVim theme="auto" detecta catppuccin automáticamente al restaurar
    vim.cmd("colorscheme catppuccin")
    vim.notify("  Catppuccin Mocha Premium", vim.log.levels.INFO, {title="Theme"})
  end
end, {desc="Toggle theme (Catppuccin ↔ Sonokai)"})

-- ─── COMMAND CENTER: Ctrl+Up ────────────────────────────────────────────────
-- Ctrl+Shift+P de VS Code pero superior: fuzzy sobre TODAS las acciones del stack.
-- Escribe categoría ("git", "debug", "yazi") o acción ("grep", "diff", "breakpoint").
-- Enter → ejecuta. Esc → cierra. Categorías con color propio (Catppuccin lanes).
vim.keymap.set("n", "<C-Up>", function()
  local ok_s, snacks = pcall(require, "snacks")
  if not ok_s then return end

  -- ── Toggle: si hay un picker activo (command center abierto), cerrarlo ──────
  -- snacks.picker.get() devuelve todos los pickers activos del stack
  if snacks.picker.get then
    local active = snacks.picker.get()
    if #active > 0 then
      for _, picker in ipairs(active) do pcall(function() picker:close() end) end
      return
    end
  end

  local p = snacks.picker

  -- ── Título dinámico con rama git activa ────────────────────────────────────
  local _r = vim.fn.systemlist("git branch --show-current")
  local branch = (vim.v.shell_error == 0 and _r[1] or ""):gsub("\27%[[%d;]*m", ""):gsub("%s+$", "")
  local title = #branch > 0
    and "󱓞  Command Center   " .. branch
    or  "󱓞  Command Center"

  -- ── Colores por categoría — Catppuccin Mocha color lanes ──────────────────
  -- Files/Yazi=green  Git=peach  LSP/API=blue  Search=teal  Claude=yellow
  -- Debug=red  Notes=lavender  UI=mauve  Config=dim
  local cat_hl = {
    Files  = "@string",         -- green
    Yazi   = "DiagnosticOk",    -- green
    Search = "Identifier",      -- teal
    Git    = "DiagnosticWarn",  -- peach
    LSP    = "DiagnosticInfo",  -- blue
    Debug  = "DiagnosticError", -- red
    API    = "@function",       -- blue
    Notes  = "Title",           -- lavender/bold
    UI     = "Special",         -- mauve
    Claude = "WarningMsg",      -- yellow
    Config = "Comment",         -- dim
    Font   = "@type",           -- yellow/type color
  }

  -- Font switcher: escribe ~/.nvim_font → WezTerm recarga automático
  local function set_font(key, label)
    local path = vim.fn.expand("~") .. "\\.nvim_font"
    local f = io.open(path, "w")
    if f then f:write(key); f:close() end
    vim.notify("Font → " .. label .. "\nWezTerm recargará automáticamente", vim.log.levels.INFO, { title = "Font" })
  end

  local function cmd(icon, cat, label, action)
    return { icon = icon, cat = cat, name = label, text = cat .. " " .. label, action = action }
  end

  local items = {
    -- ── Files ─────────────────────────────────────────────────────────────
    cmd(" ", "Files",  "Abrir archivo (smart)",          function() p.smart() end),
    cmd(" ", "Files",  "Archivos recientes",              function() p.recent() end),
    cmd(" ", "Files",  "Buscar en proyecto (grep)",       function() p.grep() end),
    cmd(" ", "Files",  "Buffers abiertos",                function() p.buffers() end),
    cmd(" ", "Files",  "Mini.files (explorador flotante)", function()
      local buf = vim.api.nvim_buf_get_name(0)
      require("mini.files").open(buf ~= "" and buf or vim.uv.cwd())
    end),
    -- ── Yazi ──────────────────────────────────────────────────────────────
    cmd(" ", "Yazi",   "Archivo actual (reveal)",        function() vim.cmd("Yazi") end),
    cmd(" ", "Yazi",   "CWD del proyecto",               function() vim.cmd("Yazi cwd") end),
    cmd(" ", "Yazi",   "Retomar sesión anterior",        function() vim.cmd("Yazi toggle") end),
    -- ── Search & Replace ──────────────────────────────────────────────────
    cmd(" ", "Search", "Keymaps",                        function() p.keymaps() end),
    cmd(" ", "Search", "Comandos vim",                   function() p.commands() end),
    cmd(" ", "Search", "Ayuda (help tags)",              function() p.help() end),
    cmd(" ", "Search", "Highlights activos",             function() p.highlights() end),
    cmd(" ", "Search", "Undo history (árbol)",           function() p.undo() end),
    cmd("󰛔 ", "Search", "Find & Replace global (grug-far)", function()
      local ok, grug = pcall(require, "grug-far")
      if ok then grug.open() else vim.notify("grug-far no instalado", vim.log.levels.WARN) end
    end),
    -- ── Git ───────────────────────────────────────────────────────────────
    cmd(" ", "Git",   "Status",                         function() p.git_status() end),
    cmd(" ", "Git",   "Log del proyecto",               function() p.git_log() end),
    cmd(" ", "Git",   "Archivos git-tracked",           function() p.git_files() end),
    cmd(" ", "Git",   "Ramas",                          function() p.git_branches() end),
    cmd("󰻂 ", "Git",  "Diffview — diff actual",         function() vim.cmd("DiffviewOpen") end),
    cmd("󰻂 ", "Git",  "Diffview — historial archivo",   function() vim.cmd("DiffviewFileHistory %") end),
    -- ── LSP ───────────────────────────────────────────────────────────────
    cmd(" ", "LSP",   "Símbolos (buffer)",              function() p.lsp_symbols() end),
    cmd(" ", "LSP",   "Símbolos (workspace)",           function() p.lsp_workspace_symbols() end),
    cmd(" ", "LSP",   "Diagnósticos (buffer)",          function() p.diagnostics({ buf = 0 }) end),
    cmd(" ", "LSP",   "Diagnósticos (workspace)",       function() p.diagnostics() end),
    cmd(" ", "LSP",   "Referencias bajo cursor",        function() p.lsp_references() end),
    cmd(" ", "LSP",   "Implementaciones",               function() p.lsp_implementations() end),
    -- ── Debug (DAP) ───────────────────────────────────────────────────────
    cmd(" ", "Debug", "Continue / Start session",       function() pcall(function() require("dap").continue() end) end),
    cmd(" ", "Debug", "Toggle breakpoint",              function() pcall(function() require("dap").toggle_breakpoint() end) end),
    cmd(" ", "Debug", "Step over",                      function() pcall(function() require("dap").step_over() end) end),
    cmd(" ", "Debug", "Step into",                      function() pcall(function() require("dap").step_into() end) end),
    cmd(" ", "Debug", "DAP UI toggle",                  function() pcall(function() require("dapui").toggle() end) end),
    -- ── API HTTP (Kulala) ──────────────────────────────────────────────────
    cmd("󰛿 ", "API",  "HTTP Scratchpad (nuevo)",        function() pcall(function() require("kulala").scratchpad() end) end),
    cmd("󰛿 ", "API",  "Enviar request actual",          function() pcall(function() require("kulala").run() end) end),
    -- ── Notes (Obsidian) ──────────────────────────────────────────────────
    cmd("󱓧 ", "Notes", "Buscar nota",                   function() vim.cmd("ObsidianSearch") end),
    cmd("󱓧 ", "Notes", "Quick switch nota",             function() vim.cmd("ObsidianQuickSwitch") end),
    cmd("󱓧 ", "Notes", "Nueva nota",                    function() vim.cmd("ObsidianNew") end),
    cmd("󱓧 ", "Notes", "Backlinks de nota actual",      function() vim.cmd("ObsidianBacklinks") end),
    -- ── UI / Ventanas ─────────────────────────────────────────────────────
    cmd(" ", "UI",    "Terminal flotante",               function() pcall(function() require("toggleterm").toggle(1, nil, nil, "float") end) end),
    cmd(" ", "UI",    "Explorador (neo-tree)",           function() vim.cmd("Neotree toggle") end),
    cmd("󰹊 ", "UI",  "Cambiar colorscheme",             function() p.colorschemes() end),
    cmd(" ", "UI",    "Zen mode",                        function() vim.cmd("ZenMode") end),
    cmd(" ", "UI",    "Twilight (foco párrafo)",         function() vim.cmd("Twilight") end),
    cmd(" ", "UI",    "Screenkey toggle",                function() vim.cmd("Screenkey") end),
    -- ── Claude AI ─────────────────────────────────────────────────────────
    cmd("󰚩 ", "Claude", "Toggle panel",                 function() vim.cmd("ClaudeCode") end),
    cmd("󰚩 ", "Claude", "Focus panel",                  function() vim.cmd("ClaudeCodeFocus") end),
    cmd("󰚩 ", "Claude", "Agregar buffer al contexto",   function() vim.cmd("ClaudeCodeAdd %") end),
    cmd("󰚩 ", "Claude", "Resume sesión",                function() vim.cmd("ClaudeCode --resume") end),
    cmd("󰚩 ", "Claude", "Seleccionar modelo",           function() vim.cmd("ClaudeCodeSelectModel") end),
    cmd("󰚩 ", "Claude", "Aceptar diff (yes)",           function() vim.cmd("ClaudeCodeDiffAccept") end),
    -- ── Font (WezTerm switcher via ~/.nvim_font) ──────────────────────────
    cmd(" ", "Font", "UbuntuSansMono — variable font, true Medium (ACTIVA)", function()
      set_font("ubuntu", "UbuntuSansMono Nerd Font")
    end),
    cmd(" ", "Font", "IosevkaTerm — condensada, 9 pesos reales, densidad +20%", function()
      set_font("iosevka", "IosevkaTerm Nerd Font")
    end),
    -- ── Config ────────────────────────────────────────────────────────────
    cmd("󰒲 ", "Config", "Lazy plugins",                 function() vim.cmd("Lazy") end),
    cmd(" ", "Config",  "Mason (LSP servers)",           function() vim.cmd("Mason") end),
    cmd(" ", "Config",  "Abrir init.lua",                function() vim.cmd("edit " .. vim.fn.stdpath("config") .. "/init.lua") end),
    cmd(" ", "Config",  "Abrir keymaps.lua",             function() vim.cmd("edit " .. vim.fn.stdpath("config") .. "/lua/config/keymaps.lua") end),
  }

  p.pick(nil, {
    title = title,
    items = items,
    format = function(item, _ctx)
      local hl = cat_hl[item.cat] or "Comment"
      return {
        { item.icon,               hl = hl       },
        { " [" .. item.cat .. "]", hl = hl       },
        { " › " .. item.name,      hl = "Normal" },
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
          ["<Esc>"]  = { "close", mode = { "n", "i" } }, -- cierra en cualquier modo
          ["<C-Up>"] = { "close", mode = { "n", "i" } }, -- toggle: Ctrl+Up de nuevo cierra
          ["<C-c>"]  = { "close", mode = { "n", "i" } },
        },
      },
    },
    layout = { preset = "dropdown", preview = false },
  })
end, { desc = "Command Center (toggle)" })

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

----- DISABLE: Alt+j/k line move (interfiere con workflow) -----
for _, mode in ipairs({ "i", "n", "x" }) do
  vim.keymap.set(mode, "<A-j>", "<nop>", { silent = true })
  vim.keymap.set(mode, "<A-k>", "<nop>", { silent = true })
end
vim.keymap.set("x", "J", "<nop>", { silent = true })
vim.keymap.set("x", "K", "<nop>", { silent = true })

----- REMOVE LazyVim resize defaults: Ctrl+Arrow -----
-- LazyVim mapea <C-Left>/<C-Right>/<C-Down> a resize — conflicta con navegación por palabras.
-- Resize ya está en <C-S-Arrow> (definido arriba). <C-Up> está sobreescrito por command center.
-- pcall: no falla si LazyVim no definió el keymap en este entorno.
for _, key in ipairs({ "<C-Left>", "<C-Right>", "<C-Down>" }) do
  pcall(vim.keymap.del, "n", key)
end
