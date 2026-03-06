# CLAUDE.md — Neovim Configuration Reference

> Guía canónica para Claude Code y cualquier colaborador IA.
> Plataforma: **Windows 11 + WezTerm + PowerShell Core (pwsh)**
> Base: **LazyVim** sobre Neovim 0.11+
> Fecha última revisión: 2026-03-03

---

## 1. ARQUITECTURA GENERAL

```
nvim/
├── init.lua                     ← 1 línea: carga lazy.lua
├── lua/
│   ├── config/
│   │   ├── lazy.lua             ← Bootstrap LazyVim + shell Windows + extras
│   │   ├── options.lua          ← vim.opt global (cargado pre-plugins)
│   │   ├── keymaps.lua          ← 80+ keymaps + Command Center
│   │   └── autocmds.lua         ← 9 grupos: markdown, theme-sync, URL, Windows
│   └── plugins/                 ← Un archivo por dominio funcional
│       ├── colorscheme.lua      ← 3 temas completos (≈950 líneas)
│       ├── disabled.lua         ← Plugins desactivados explícitamente
│       └── ...
```

### Principio de organización

- **`config/`**: configuración del editor (opciones, atajos, autocomandos).
- **`plugins/`**: cada archivo = un dominio (database, markdown, git, etc.).
- `disabled.lua` es el único lugar donde se deshabilitan plugins. No usar `enabled = false` en otros archivos.
- Archivos de plugin vacíos → siempre `return {}` (nunca vacíos o lazy falla).

---

## 2. SISTEMA DE TEMAS (3 temas sincronizados)

### Tema activo por defecto: **Catppuccin Mocha**

- `transparent_background = true` — Normal/NormalFloat = `NONE`
- Visual selection: `#394361` (blend blue+base 25%, H=222°)
- Semantic color lanes (mapeo LSP/Treesitter):
  - blue=funciones, yellow=tipos/clases, teal=propiedades/operadores
  - mauve=keywords/accent, peach=números/builtins, lavender=constantes/enums
  - green=strings, overlay0-2=puntuación/comentarios/UI dim

### Alternativas disponibles

| Tema                      | Accent        | Notas                                                  |
| ------------------------- | ------------- | ------------------------------------------------------ |
| `gentleman-kanagawa-blur` | oro `#E0C15A` | Transparencia blur, WezTerm waveBlue                   |
| `sonokai`                 | —             | Monokai Pro/ST3, >600 líneas overrides en autocmds.lua |

### Sincronización con WezTerm

- `autocmds.lua` → `VimEnter` + `ColorScheme` escriben `~/.nvim_theme`
- WezTerm observa ese archivo con `watch_config_file` y recarga automáticamente

---

## 3. WINDOWS: CONVENCIONES CRÍTICAS

```lua
-- Shell correcta (NUNCA cmd.exe)
vim.opt.shell = 'pwsh.exe'
vim.opt.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command'

-- Clipboard dual (sin clip.exe)
vim.opt.clipboard = 'unnamed,unnamedplus'

-- Encoding forzado en escritura (evita CRLF en Git)
-- autocmd BufWritePre → fileformat = unix
```

- **Python**: usar `/c/Python313/python.exe`, nunca `python3` (alias roto en Windows)
- **Node.js**: NVM detectado en `$APPDATA\Roaming\nvm\v22.11.0\node.exe`
- **TEMP dirs**: undo/swap/backup en `$TEMP` con `mkdir -p`

---

## 4. PATRONES OBLIGATORIOS

### Lazy loading

Todos los plugins deben tener al menos uno de:

```lua
event = "VeryLazy"      -- carga diferida genérica
event = "BufReadPre"    -- antes de leer buffer
cmd   = { "MyCmd" }     -- solo cuando se llama el comando
keys  = { ... }         -- solo cuando se presiona la tecla
```

**NUNCA** `lazy = false` salvo justificación explícita documentada.

### Plugin override sin duplicar

Si LazyVim ya incluye un plugin, sobreescribir SOLO lo necesario:

```lua
-- CORRECTO: merge con spec de LazyVim
{ "echasnovski/mini.animate", opts = { scroll = { enable = false } } }

-- INCORRECTO: duplicar toda la configuración
```

### requires opcionales

```lua
-- Siempre pcall en keymaps.lua top-level
local ok, plugin = pcall(require, "plugin")
if not ok then return end
```

### Mini plugins: repo correcto

```lua
-- CORRECTO
"echasnovski/mini.animate"
"echasnovski/mini.indentscope"

-- INCORRECTO (org inexistente)
"nvim-mini/mini.animate"
"nvim-mini/mini.indentscope"
```

---

## 5. INVENTARIO DE PLUGINS ACTIVOS

### UI / Visual (10)

| Plugin                         | Archivo         | Justificación                        |
| ------------------------------ | --------------- | ------------------------------------ |
| catppuccin/nvim                | colorscheme.lua | Tema principal, ecosystem más activo |
| gentleman-kanagawa-blur        | colorscheme.lua | Alternativa premium transparente     |
| sainnhe/sonokai                | colorscheme.lua | Alternativa Monokai clásica          |
| lualine.nvim                   | lualine.lua     | Statusline, custom Kanagawa support  |
| b0o/incline.nvim               | ui.lua          | Filename flotante por ventana        |
| folke/zen-mode.nvim            | ui.lua          | Modo distracción-libre               |
| folke/twilight.nvim            | twilight.lua    | Dim código inactivo                  |
| folke/snacks.nvim              | ui.lua          | Notifications + picker               |
| folke/todo-comments.nvim       | ui.lua          | TODO/FIXME/HACK coloreados           |
| echasnovski/rainbow-delimiters | rainbow.lua     | 7 niveles Catppuccin lanes           |

### Editor / Navegación (8)

| Plugin                       | Archivo        | Justificación                      |
| ---------------------------- | -------------- | ---------------------------------- |
| nvim-neo-tree/neo-tree.nvim  | neo-tree.lua   | Sidebar principal, UiEnter trigger |
| echasnovski/mini.files       | overrides.lua  | Explorador flotante (`-`)          |
| echasnovski/mini.animate     | animations.lua | open/close/resize suaves           |
| sphamba/smear-cursor.nvim    | animations.lua | Trail visual del cursor            |
| karb94/neoscroll.nvim        | animations.lua | Scroll easing quadratic            |
| echasnovski/mini.indentscope | animations.lua | Indent guides animados             |
| akinsho/toggleterm.nvim      | terminal.lua   | Terminal flotante/split            |
| rmagatti/goto-preview        | editor.lua     | LSP preview sin saltar de archivo  |

### Completado / LSP (3)

| Plugin                  | Archivo       | Justificación                          |
| ----------------------- | ------------- | -------------------------------------- |
| saghen/blink.cmp        | blink.lua     | Completion moderno, reemplaza nvim-cmp |
| neovim/nvim-lspconfig   | lsp-setup.lua | lua_ls overrides para config nvim      |
| williamboman/mason.nvim | lsp-setup.lua | LSP server manager                     |

### Búsqueda / Navegación rápida (5)

| Plugin                     | Archivo    | Justificación                  |
| -------------------------- | ---------- | ------------------------------ |
| MagicDuck/grug-far.nvim    | search.lua | Find&Replace multi-archivo     |
| VonHeikemen/searchbox.nvim | search.lua | `<C-f>` float VS Code style    |
| folke/flash.nvim           | search.lua | Jump labels sobre búsqueda `/` |
| kevinhwang91/nvim-hlslens  | search.lua | Contador `[N/M]` en búsqueda   |
| ibhagwan/fzf-lua           | fzflua.lua | Fuzzy finder con ripgrep+fd    |

### Git (3)

| Plugin                  | Archivo      | Justificación                    |
| ----------------------- | ------------ | -------------------------------- |
| sindrets/diffview.nvim  | diffview.lua | Visual diff + 3-way merge        |
| dinhhuy258/git.nvim     | editor.lua   | Blame inline + browse en browser |
| lewis6991/gitsigns.nvim | (LazyVim)    | Signos cambios en signcolumn     |

### Desarrollo avanzado (5)

| <LeftMouse>Plugin        | Archivo        | Justificación                    |
| ------------------------ | -------------- | -------------------------------- |
| coder/claudecode.nvim    | claudecode.lua | IA pair programmer, <C-q> toggle |
| mfussenegger/nvim-dap    | nvim-dap.lua   | Debugger DAP universal           |
| epwalsh/obsidian.nvim    | obsidian.lua   | Notas Markdown con backlinks     |
| mistweaverco/kulala.nvim | kulala.lua     | HTTP client (REST/gRPC)          |
| kndndrj/nvim-dbee        | database.lua   | DB explorer Oracle/PostgreSQL    |

### Lenguajes (3)

| Plugin               | Archivo      | Justificación                 |
| -------------------- | ------------ | ----------------------------- |
| render-markdown.nvim | markdown.lua | Render visual 3 modos         |
| img-clip.nvim        | markdown.lua | Pegar screenshots en Markdown |
| treesitter c_sharp   | csharp.lua   | Soporte C#/.NET               |

### Utilidades (5)

| Plugin                    | Archivo         | Justificación                      |
| ------------------------- | --------------- | ---------------------------------- |
| folke/which-key.nvim      | which-key.lua   | Keymap discovery, preset helix     |
| mikavilpas/yazi.nvim      | yazi.lua        | File manager terminal con tabs     |
| mg979/vim-visual-multi    | multi-line.lua  | Multi-cursor moderno (mantenido)   |
| NStefan002/screenkey.nvim | screenkey.lua   | Display teclas (demos/grabaciones) |
| ThePrimeagen/vim-be-good  | vim-be-good.lua | Entrenamiento Vim (opcional)       |

### Desactivados explícitamente (disabled.lua)

```lua
akinsho/bufferline.nvim     -- reemplazado por snacks bufferline
zbirenbaum/copilot.lua      -- reemplazado por claudecode
CopilotC-Nvim/CopilotChat.nvim
yetone/avante.nvim          -- probado, descartado
olimorris/codecompanion.nvim
nvim-tree/nvim-tree.lua     -- reemplazado por neo-tree
stevearc/oil.nvim           -- reemplazado por mini.files
```

---

## 6. KEYMAPS: ESTRUCTURA

### Líderes

- `<Space>` = `<leader>` (LazyVim default)
- `<leader>a` = Claude AI (claudecode)
- `<leader>D` = Database explorer
- `<leader>m` = Markdown operations
- `<leader>R` = REST/HTTP (kulala)
- `<leader>g` = Git operations
- `<leader>f` = Files / Yazi
- `<C-Up>` = Command Center (snacks.picker custom)

### Command Center

`keymaps.lua` líneas ~290-443: picker con 40+ acciones en 12 categorías.

- Título dinámico con rama git (`git branch --show-current`)
- Formato: `{ icon, hl } { " [cat]", hl } { " › action", Normal }`
- Categorías con color lanes de Catppuccin

### URL handling

- `gx` = abrir URL/link Markdown en browser
- `<C-LeftMouse>` = Ctrl+click URL
- `<C-S-LeftMouse>` = go back (`<C-o>`)

---

## 7. AUTOCMDS: GRUPOS DOCUMENTADOS

| Grupo                   | Trigger              | Propósito                            |
| ----------------------- | -------------------- | ------------------------------------ |
| `SpellCheckDisabled`    | BufEnter/FileType    | Desactiva spell global               |
| `MarkdownUX`            | FileType markdown    | conceallevel, cycle render modes     |
| `WindowHierarchy`       | WinEnter/WinLeave    | cursorline + line numbers por foco   |
| `TerminalCursorRestore` | VimLeave             | DECSCUSR bar blink al salir          |
| `CwdPersistence`        | VimLeave             | Guarda CWD en `~/.nvim_last_cwd`     |
| `WindowsSpecific`       | BufWritePre/ReadPre  | Fuerza unix+utf-8                    |
| `UrlUnderline`          | VimEnter/WinEnter    | matchadd() para URLs                 |
| `ThemeSync`             | VimEnter/ColorScheme | Escribe `~/.nvim_theme` para WezTerm |
| `KanagawaBlurOverrides` | ColorScheme          | devicons palette + NormalNC=NONE     |
| `SonokaiOverrides`      | ColorScheme          | >600 líneas highlight manual         |

---

## 8. OPCIONES NOTABLES

```lua
vim.o.winborder = "rounded"   -- nvim 0.11+: border redondeado nativo en TODOS los floats
vim.opt.cmdheight = 0          -- Noice gestiona cmdline en float
vim.opt.laststatus = 3         -- Statusline global única
vim.opt.splitkeep = "cursor"   -- nvim 0.9+: cursor estable al dividir
vim.opt.foldmethod = "expr"    -- Treesitter folds
vim.opt.inccommand = "split"   -- Preview :s en split en tiempo real
```

---

## 9. BUENAS PRÁCTICAS CONFIRMADAS

- **Transparent stack**: `transparent_background = true` + `NormalFloat = NONE` + WezTerm `window_background_opacity`
- **Panel dimming**: `NormalNC = { bg = colors.mantle }` + `dim_inactive = { enabled=true, percentage=0.30 }`
- **smear-cursor en terminal**: `TermEnter` deshabilita, `TermLeave` rehabilita (evita glitches)
- **mini.indentscope**: `vim.b.miniindentscope_disable = true` en FileType para terminales/panels
- **mini.animate vs neoscroll**: `scroll = { enable = false }` en mini.animate, neoscroll lo cubre (sin doble-easing)
- **mini.animate vs noice**: `open.enable` seguro; `scroll.enable` causa issue #761 (cursor flickering con noice)
- **ClaudeCode toggle**: `nvim_win_hide()` no `:bdelete` → proceso sigue vivo, re-attach en <C-q>
- **neo-tree**: trigger en `UiEnter` no `VimEnter` (más estable, LazyVim Discussion #3139)
- **neo-tree action**: usar `"show"` no `"focus"` para abrir sin mover el cursor

---

## 10. ANTIPATRONES A EVITAR

| Antipatrón                                    | Problema                                      | Corrección                            |
| --------------------------------------------- | --------------------------------------------- | ------------------------------------- |
| `lazy = false` sin justificar                 | Carga en startup, degrada tiempo de arranque  | Usar `event`, `cmd` o `keys`          |
| `nvim-mini/mini.X` como repo                  | Org inexistente en GitHub                     | `echasnovski/mini.X`                  |
| `terryma/vim-multiple-cursors`                | Deprecado por el autor en 2019 explícitamente | `mg979/vim-visual-multi`              |
| Plugin en `oil.lua` + `disabled.lua`          | Specs duplicadas/contradictorias              | Solo en `disabled.lua`                |
| `styles = { "italic" }` en gentleman-kanagawa | nvim_set_hl falla: `invalid key: 1`           | Omitir `styles` o `{ italic = true }` |
| `splitkeepalt`                                | No existe                                     | `vim.opt.splitkeep = "cursor"`        |
| `VimEnter` para layout (neo-tree)             | Intermitente                                  | `UiEnter` (nvim 0.9+)                 |
| Archivo plugin vacío                          | lazy.nvim falla: "Expected a table"           | Siempre `return {}`                   |
| `defaults.lazy = false` en lazy.setup         | Anula todo el lazy loading                    | No usar                               |
| `lang.markdown` extra + markdown.lua custom   | Conflicto render                              | No usar ambos                         |

---

## 11. DEPENDENCIAS EXTERNAS

| Herramienta       | Versión       | Uso                                                          |
| ----------------- | ------------- | ------------------------------------------------------------ |
| Neovim            | 0.11+         | `vim.o.winborder` (0.11), `splitkeep` (0.9), `UiEnter` (0.9) |
| PowerShell        | 7+ (pwsh)     | Shell principal, scripts de PDF                              |
| Node.js           | 22.11.0 (NVM) | LSP servers (typescript-language-server, etc.)               |
| Python            | 3.13          | Scripts de utilidad (`/c/Python313/python.exe`)              |
| ripgrep (rg)      | latest        | fzf-lua, grug-far                                            |
| fd                | latest        | fzf-lua find files                                           |
| yazi              | latest        | File manager en yazi.nvim                                    |
| Go                | latest        | nvim-dbee build (binario nativo)                             |
| UbuntuSansMono NF | —             | Fuente principal WezTerm                                     |

---

## 12. NOTAS PARA CLAUDE CODE

- **Editar `colorscheme.lua`**: usa TABS reales (no espacios). Catppuccin `highlight_overrides` tiene 6 tabs de indent. Verificar con `:set list` o `cat -A`.
- **Scripts Python grandes**: crear en `/tmp/script.py`, ejecutar con `PYTHONIOENCODING=utf-8 /c/Python313/python.exe /tmp/script.py`
- **str.replace() en Python**: NO falla silenciosamente si no encuentra patrón. Verificar con `if old in content`.
- **Inserciones de código con caracteres Unicode**: siempre `PYTHONIOENCODING=utf-8` en la invocación
- **`legendary.nvim`**: ARCHIVADO abril 2025. No agregar. Alternativa activa: `snacks.picker`.
- **Probar cambios de theme**: `:colorscheme catppuccin` | `:colorscheme gentleman-kanagawa-blur` | `:colorscheme sonokai`
- **Lazy reload**: `:Lazy sync` después de cambios en plugin specs
