-- Keymaps - loaded on VeryLazy event
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

----- SCROLL + CENTER -----
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

----- ESCAPE universal -----
vim.keymap.set({ "i", "n" }, "<C-c>", [[<C-\><C-n>]])  -- solo insert/normal

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
    vim.notify("No file to save", vim.log.levels.WARN)
    return
  end
  local ok, err = pcall(vim.cmd, "silent! write")
  if ok then
    vim.notify(vim.fn.expand("%:t") .. " saved!")
  else
    vim.notify("Error: " .. err, vim.log.levels.ERROR)
  end
end, { desc = "Save file" })

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

----- SPLIT NAVIGATION: hjkl (tmux-compatible fallback) -----
local ok, nvim_tmux_nav = pcall(require, "nvim-tmux-navigation")
if ok then
  vim.keymap.set("n", "<C-h>", nvim_tmux_nav.NvimTmuxNavigateLeft)
  vim.keymap.set("n", "<C-j>", nvim_tmux_nav.NvimTmuxNavigateDown)
  vim.keymap.set("n", "<C-k>", nvim_tmux_nav.NvimTmuxNavigateUp)
  vim.keymap.set("n", "<C-l>", nvim_tmux_nav.NvimTmuxNavigateRight)
  vim.keymap.set("n", "<C-Space>", nvim_tmux_nav.NvimTmuxNavigateNext)
else
  vim.keymap.set("n", "<C-h>", "<C-w>h")
  vim.keymap.set("n", "<C-j>", "<C-w>j")
  vim.keymap.set("n", "<C-k>", "<C-w>k")
  vim.keymap.set("n", "<C-l>", "<C-w>l")
end

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

----- OBSIDIAN -----
vim.keymap.set("n", "<leader>oc", "<cmd>ObsidianCheck<cr>", { desc = "Check checkbox" })
vim.keymap.set("n", "<leader>ot", "<cmd>ObsidianTemplate<cr>", { desc = "Insert template" })
vim.keymap.set("n", "<leader>oo", "<cmd>Obsidian Open<cr>", { desc = "Open in Obsidian" })
vim.keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<cr>", { desc = "Backlinks" })
vim.keymap.set("n", "<leader>ol", "<cmd>ObsidianLinks<cr>", { desc = "Links" })
vim.keymap.set("n", "<leader>on", "<cmd>ObsidianNew<cr>", { desc = "New note" })
vim.keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<cr>", { desc = "Search" })
vim.keymap.set("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", { desc = "Quick switch" })

----- UI -----
vim.keymap.set("n", "<leader>uk", "<cmd>Screenkey<cr>", { desc = "Toggle Screenkey" })

-- Theme toggle: Catppuccin ↔ Sonokai
vim.keymap.set("n", "<leader>us", function()
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

-- Ctrl+Up: lanzador bajo demanda — no invade el inicio, aparece cuando se necesita
-- Snacks dashboard sin header (sin logo LazyVim): solo atajos + recientes
vim.keymap.set("n", "<C-Up>", function()
  require("snacks.dashboard").open({
    preset = {
      keys = {
        { icon = " ", key = "f", desc = "Buscar archivo",    action = ":lua Snacks.picker.smart()" },
        { icon = " ", key = "r", desc = "Recientes",         action = ":lua Snacks.picker.recent()" },
        { icon = " ", key = "g", desc = "Buscar texto",      action = ":lua Snacks.picker.grep()" },
        { icon = " ", key = "e", desc = "Explorador",        action = ":Neotree toggle" },
        { icon = "󰒲 ", key = "L", desc = "Lazy",             action = ":Lazy" },
        { icon = " ", key = "q", desc = "Salir",             action = ":qa" },
      },
    },
    sections = {
      -- Sin "header": elimina el logo LazyVim
      { section = "keys",         gap = 1, padding = 1 },
      { section = "recent_files", limit = 6, padding = 1 },
      { section = "startup" },
    },
  })
end, { desc = "Launcher (on demand)" })

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
