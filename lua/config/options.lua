-- Options son cargadas antes de plugins (LazyVim las respeta)
-- https://lazyvim.github.io/configuration/general

-- Autoformat: DESACTIVADO por defecto
-- LazyVim activa autoformat al guardar (conform.nvim). En proyectos en equipo esto
-- destruye consistencia git si no hay un formatter acordado (.editorconfig / config compartida).
-- Para formatear manualmente: <leader>cf (Format file) o <leader>cF (Format injected).
-- Para reactivar por sesión: :lua vim.g.autoformat = true
vim.g.autoformat = false

-- ─── Safety stack moderna (expertos 2025) ────────────────────────────────────
-- Swapfiles (.swp) son de 1991: crean el molesto dialog de "recuperar" al abrir.
-- Reemplazados por: undofile (crash recovery) + git (version control).
-- Resultado: CERO dialogs de recuperación, cero archivos .swp en disco.
vim.opt.swapfile   = false  -- sin .swp: no más dialogs de recuperación al abrir archivos
vim.opt.backup     = false  -- sin archivos de backup ~
vim.opt.writebackup = true  -- solo durante escritura activa (protección mínima, sin residuos)
vim.opt.undofile   = true   -- undo persistente: sobrevive crashes Y cerrar nvim
vim.opt.undolevels = 10000  -- 10k pasos (vs 1000 por defecto) — historia larga

-- Auto-reload: recarga silenciosa cuando el disco cambia y el buffer NO tiene cambios
-- Sin esto nvim muestra el prompt "[O]K, (L)oad..." cada vez que Claude Code edita un archivo
-- Con esto: si el buffer está limpio → recarga solo. Si tienes cambios sin guardar → pregunta (correcto)
vim.opt.autoread = true

-- ─── Colores y rendering ─────────────────────────────────────────────────────
-- termguicolors: habilita 24-bit RGB + envío correcto de \e[3m (italic) al terminal
-- LazyVim lo setea, pero en Windows con WezTerm el timing puede fallar → explicit aquí
vim.opt.termguicolors = true

-- italic en TUI: garantiza que Neovim use las secuencias de escape correctas
-- \e[3m = italic ON / \e[23m = italic OFF — requerido por WezTerm font_rules
if not vim.g.neovide then
	vim.cmd([[let &t_ZH="\e[3m"]])
	vim.cmd([[let &t_ZR="\e[23m"]])
end

-- Asegurar que neovim vea xterm-256color (tiene sitm/ritm italic en su terminfo)
-- "wezterm" como TERM en Windows hace que nvim pierda cursor shapes y más
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
  if vim.env.TERM ~= "xterm-256color" then
    vim.env.TERM = "xterm-256color"
  end
end

-- Timing
vim.opt.timeoutlen = 300   -- which-key timeout: 300ms = LazyVim default, balance entre velocidad y accidentales
vim.opt.ttimeoutlen = 0    -- sin delay al salir de insert mode con Escape

-- Scroll con contexto visual
-- scrolloff=8: contexto amplio = menos saltos bruscos de camara = descanso visual
vim.opt.scrolloff = 8      -- Kanagawa/Primeagen: contexto amplio = menos fatiga visual
vim.opt.sidescrolloff = 6  -- horizontal: 6 chars de contexto

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
-- guicursor: filosofía profesional de cursor
--   Normal/Visual/Command: BLOCK con parpadeo lento (900-600-450ms) — presencia calmada
--     blinkwait900: 0.9s antes de iniciar, menos agresivo. blinkon/off asimétrico (600/450)
--   Insert/Replace: BAR 25% con parpadeo rítmico (identidad del modo de edición activo)
--     blinkwait=0: parpadeo comienza INMEDIATAMENTE al entrar al modo (sin delay de 400ms)
--     blinkon/off=350ms: más rápido que 400ms → perceptualmente más vivo, menos letárgico
--   Terminal: bar + parpadeo (igual que insert — contexto de escritura activa)
vim.opt.guicursor = {
  "n-v-c:block-blinkwait900-blinkon600-blinkoff450-Cursor",           -- Normal/Visual: block, parpadeo lento (descanso visual)
  "i-ci-ve:ver25-blinkwait0-blinkon350-blinkoff350-Cursor/lCursor",  -- Insert: bar, blink inmediato 350ms
  "r-cr:hor20-blinkwait0-blinkon350-blinkoff350-Cursor/lCursor",     -- Replace: underline, blink 350ms
  "o:hor50-Cursor",                                                   -- Operator-pending: underline 50%
  "t:ver25-blinkwait0-blinkon350-blinkoff350-Cursor",                 -- Terminal: bar, blink 350ms
}

-- Fold: treesitter-based, abiertos por defecto (colapsar con zc, abrir con zo)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldcolumn = "0"  -- sin columna numérica lateral; ufo virt-text (▸ N)-- Folds (ufo): íconos limpios (VSCode style)
vim.opt.fillchars:append({ fold = " ", foldopen = "⌄", foldclose = "›", foldsep = " " })
-- foldtext: nvim 0.10+ — muestra primera línea real + conteo de líneas colapsadas
-- Sin esto el fold muestra "N lines: ..." genérico y pierde el syntax highlight
vim.opt.foldtext = ""  -- cadena vacía = nvim usa el foldtext virtual nativo (0.10+)

-- Smooth scroll: delegado a neoscroll.nvim (easing quadratic configurable)
-- vim.opt.smoothscroll = true  -- desactivado: neoscroll ya lo maneja, ambos juntos = doble easing

-- Sign column fija 1-char: carril diagnóstico + carril git fusionados (statuscol.nvim)
-- "yes:1" = siempre visible, 1 col: densidad máxima, usa mix fb/bg para mostrar ambos
vim.opt.signcolumn = "yes:1"

-- Preview de :s en split (ves cambios en tiempo real)
vim.opt.inccommand = "split"

-- Pump up de contraste: línea de números ligeramente visible
vim.opt.numberwidth = 3

-- Win separator más limpio (minimalista)
vim.opt.winblend = 10  -- floats nativos: cristal ahumado transparente
vim.opt.pumblend = 0   -- PUM blend 0 guiado por PmenuSel
vim.o.winborder = "rounded"  -- Neovim 0.11+: border redondeado en TODOS los floats nativos (K, gl, input)

-- ─── Oro puro ────────────────────────────────────────────────────────────────
-- Popup de completion: máximo 10 items visibles (más limpio que infinito)
vim.opt.pumheight = 10
-- Word-wrap inteligente: corta en palabra, no en carácter (cuando wrap está activo)
vim.opt.linebreak = true
-- Líneas envueltas mantienen la indentación del bloque
vim.opt.breakindent = true
-- Caracteres invisibles: tabs, spaces, trailing visibles de forma sutil
-- space="·" equivalente a VS Code renderWhitespace:"all" — puntos entre tokens
-- Color controlado por Whitespace/SpecialKey HL (muy sutil en temas premium)
vim.opt.list = true
vim.opt.listchars = {
  space    = "·",    -- TODOS los espacios como punto (VS Code renderWhitespace:all)
  tab      = "→ ",   -- tab como flecha
  trail    = "•",    -- trailing spaces: punto lleno (mas visible que espacio normal)
  nbsp     = "␣",    -- non-breaking space visible
  extends  = "›",    -- línea truncada a la derecha
  precedes = "‹",    -- línea truncada a la izquierda
}
