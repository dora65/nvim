-- Options son cargadas antes de plugins (LazyVim las respeta)
-- https://lazyvim.github.io/configuration/general

-- Timing
vim.opt.timeoutlen = 300   -- which-key timeout: 300ms = LazyVim default, balance entre velocidad y accidentales
vim.opt.ttimeoutlen = 0    -- sin delay al salir de insert mode con Escape

-- Scroll con contexto visual
-- scrolloff=6: contexto suficiente + 2 líneas más de código visible en cada extremo
vim.opt.scrolloff = 6
vim.opt.sidescrolloff = 4  -- horizontal: 4 chars de contexto es suficiente

-- Búsqueda más inteligente
vim.opt.ignorecase = true  -- case-insensitive por defecto
vim.opt.smartcase = true   -- case-sensitive si usas mayúsculas

-- Experiencia de edición
vim.opt.virtualedit = "block"  -- en visual block, mover más allá del fin de línea
vim.opt.confirm = true         -- pregunta antes de cerrar buffer sin guardar

-- Mejorar splits
vim.opt.splitbelow = true   -- nuevo split horizontal va abajo
vim.opt.splitright = true   -- nuevo split vertical va a la derecha
vim.opt.splitkeep = "cursor" -- mantiene el cursor estable al crear splits (nvim 0.9+)

-- UI minimalista: bordes finos, sin fillchars ruidosos
vim.opt.fillchars = {
  horiz = "─",
  horizup = "┴",
  horizdown = "┬",
  vert = "│",
  vertleft = "┤",
  vertright = "├",
  verthoriz = "┼",
  eob = " ",  -- Eliminar ~ al final del buffer
}
vim.opt.laststatus = 3  -- Statusline global (una sola, no por ventana)
vim.opt.cmdheight = 0   -- Noice maneja el cmdline en float → 0 = sin línea muerta en fondo

-- Cursorline: siempre activo, el highlight real lo controla catppuccin
vim.opt.cursorline = true

-- Cursor profesional por modo: DECSCUSR controla shape, Cursor HL controla color (mauve)
-- WezTerm cursor_bg/cursor_fg = mauve → coordinado con Neovim sin duplication
vim.opt.guicursor = {
  "n-v-c:block-Cursor",                                              -- Normal/Visual: block mauve
  "i-ci-ve:ver25-blinkwait400-blinkon400-blinkoff400-Cursor/lCursor", -- Insert: bar + blink
  "r-cr:hor20-blinkwait400-blinkon400-blinkoff400-Cursor/lCursor",    -- Replace: underline + blink
  "o:hor50-Cursor",                                                   -- Operator-pending
  "t:ver25-blinkon500-Cursor",                                        -- Terminal: bar + blink
}

-- Fold: treesitter-based, abiertos por defecto (colapsar con zc, abrir con zo)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.fillchars:append({ fold = " ", foldopen = "▾", foldclose = "▸", foldsep = " " })
-- foldtext: nvim 0.10+ — muestra primera línea real + conteo de líneas colapsadas
-- Sin esto el fold muestra "N lines: ..." genérico y pierde el syntax highlight
vim.opt.foldtext = ""  -- cadena vacía = nvim usa el foldtext virtual nativo (0.10+)

-- Smooth scroll: delegado a neoscroll.nvim (easing quadratic configurable)
-- vim.opt.smoothscroll = true  -- desactivado: neoscroll ya lo maneja, ambos juntos = doble easing

-- Sign column fija 1-char: evita saltos al mostrar diagnostics/git
-- "yes:1" = siempre visible, exactamente 1 col (no se expande a 2 con múltiples signos)
vim.opt.signcolumn = "yes:1"

-- Preview de :s en split (ves cambios en tiempo real)
vim.opt.inccommand = "split"

-- Pump up de contraste: línea de números ligeramente visible
vim.opt.numberwidth = 3

-- Win separator más limpio (minimalista)
vim.opt.winblend = 0
vim.opt.pumblend = 0
vim.o.winborder = "rounded"  -- Neovim 0.11+: border redondeado en TODOS los floats nativos (K, gl, input)

-- ─── Oro puro ────────────────────────────────────────────────────────────────
-- Popup de completion: máximo 10 items visibles (más limpio que infinito)
vim.opt.pumheight = 10
-- Word-wrap inteligente: corta en palabra, no en carácter (cuando wrap está activo)
vim.opt.linebreak = true
-- Líneas envueltas mantienen la indentación del bloque
vim.opt.breakindent = true
-- Caracteres invisibles: tabs y trailing spaces visibles de forma sutil
vim.opt.list = true
vim.opt.listchars = {
  tab      = "→ ",   -- tab como flecha
  trail    = "·",    -- trailing spaces como punto medio
  nbsp     = "␣",    -- non-breaking space visible
  extends  = "›",    -- línea truncada a la derecha
  precedes = "‹",    -- línea truncada a la izquierda
}
