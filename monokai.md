# monokai.md — Estado del tema Sublime + Fuentes UbuntuSansMono NF

> Documento de referencia generado 2026-03-13.
> Describe el estado actual tras las mejoras realizadas en esta sesión.

---

## 1. TEMA SUBLIME — ARQUITECTURA

El tema `sublime` es un **layered theme**: hereda 100% de catppuccin-mocha como base
(sintaxis, LSP semántico, UI) y sobreescribe únicamente las superficies y colores de acento
con la paleta auténtica de Monokai Sublime Text 3.

```
colors/sublime.lua
  └─ vim.cmd.colorscheme("catppuccin")      → base completa catppuccin-mocha
  └─ vim.g.colors_name = "sublime"
  └─ nvim_exec_autocmds("ColorScheme", {pattern="sublime"})
        └─ autocmds.lua: SublimeOverrides    → sobreescribe superficies + sintaxis
```

**Beneficio**: sintaxis completamente definida (>200 grupos Treesitter + LSP semantic)
sin duplicar trabajo, más overrides quirúrgicos de identidad Monokai.

---

## 2. PALETA MONOKAI ST3 — REFERENCIA CANÓNICA

Fuentes: `monokai.jsonc` (VS Code theme completo) + `syntax.json` (TextMate rules Monokai Night)

### Superficies (monokai.jsonc)

| Token                        | Color     | Uso                                       |
|------------------------------|-----------|-------------------------------------------|
| `editor.background`          | `#1e1f1c` | bg principal editor, sidebar, floats      |
| `panel.background` (sidebar) | `#1b1c19` | bg deep — paneles laterales               |
| `editor.lineHighlightBg`     | `#2d2d2d` → `#232321` | cursor line (solido)         |
| `list.hoverBackground`       | `#3e3d32` | hover, treesitter-context                 |
| `editor.selectionBackground` | `#49483e` | selección activa                          |
| `editorWidget.border`        | `#3e3d32` | bordes flotantes (`brd_w`)               |
| `panel.border`               | `#2c2d2a` | separadores panel (`sep`)                |
| `scrollbarSlider.background` | `#3e3d32` | scrollbar thumb                           |
| `editorCursor.foreground`    | `#66d9ef` | cursor color (cyan)                       |
| `activityBar.activeBorder`   | `#66d9ef` | accent activo (`accent`)                 |
| `editorWhitespace.fg`        | `#3e3d32` | whitespace chars (Whitespace/SpecialKey)  |

### Sintaxis ST3 (syntax colors)

| Color     | Hex       | Grupos Neovim                                      |
|-----------|-----------|----------------------------------------------------|
| Red       | `#f92672` | keywords control, operators, tags, rainbow L1      |
| Cyan      | `#66d9ef` | storage type/modifier, builtins, fn calls, accent  |
| Green     | `#a6e22e` | entity names (fn defs, types, classes), rainbow L4 |
| Yellow    | `#e6db74` | strings, DiagnosticWarn, rainbow L3                |
| Orange    | `#fd971f` | variable.parameter, rainbow L2                     |
| Purple    | `#ae81ff` | constants, booleans, numbers, DiagnosticHint       |
| Olive     | `#75715e` | comments (italic), deprecated, dim UI              |
| Warm white| `#c2c2bf` | variables, punctuation, default text               |

### Diagnósticos (monokai.jsonc editorError/Warning/Info)

| Nivel | fg        | VirtualText bg | Undercurl sp  |
|-------|-----------|----------------|---------------|
| Error | `#f92672` | `#2a1018`      | `#f92672`     |
| Warn  | `#e6db74` | `#2a2510`      | `#e6db74`     |
| Info  | `#66d9ef` | `#0e2030`      | `#66d9ef`     |
| Hint  | `#ae81ff` | `#1e1528`      | `#ae81ff`     |

### Git decorations (monokai.jsonc gitDecoration.*)

| Estado     | Color     | Hex       |
|------------|-----------|-----------|
| Added      | muted green | `#81b88b` |
| Modified   | warm amber  | `#e2c08d` |
| Deleted    | muted red   | `#c74e39` |
| Untracked  | light green | `#73c991` |
| Ignored    | medium gray | `#8c8c8c` |
| Conflict   | vibrant red | `#e4676b` |
| Staged     | bright green | `#a6e22e` |

---

## 3. RAINBOW DELIMITERS — JERARQUÍA ESPECTRAL

Orden calor→frío para guía visual de profundidad de nesting:

| Nivel | Grupo                    | Color     | Semántica Monokai     |
|-------|--------------------------|-----------|-----------------------|
| L1    | `RainbowDelimiterRed`    | `#f92672` | keyword red           |
| L2    | `RainbowDelimiterOrange` | `#fd971f` | param orange          |
| L3    | `RainbowDelimiterYellow` | `#e6db74` | string yellow         |
| L4    | `RainbowDelimiterGreen`  | `#a6e22e` | function green        |
| L5    | `RainbowDelimiterCyan`   | `#66d9ef` | storage/accent cyan   |
| L6    | `RainbowDelimiterViolet` | `#ae81ff` | constant purple       |
| L7    | `RainbowDelimiterBlue`   | `#75715e` | comment olive (dim)   |

---

## 4. WEZTERM — SCHEME "Sublime"

El scheme WezTerm `"Sublime"` sincroniza con el tema nvim:

```
background    = #1e1f1c   (monokai.jsonc editor.background)
foreground    = #cdd6f4   (catppuccin text — sintaxis idéntica)
cursor_bg     = #66d9ef   (monokai cyan — editorCursor.foreground)
selection_bg  = #49483e   (monokai editor.selectionBackground solid)
scrollbar_thumb = #3e3d32 (monokai scrollbarSlider.background solid)
split         = #2c2d2a   (monokai panel.border solid)
ANSI palette  = catppuccin mocha (preserva identidad de sintaxis en terminal)
```

ThemeSync: `autocmds.lua VimEnter/ColorScheme` → escribe `~/.nvim_theme = "sublime"` →
WezTerm `watch_config_file` recarga automáticamente.

---

## 5. FUENTES — UBUNTUSANSMONO NERD FONT

### Familia completa instalada (8 TTFs reales)

Confirmado con `wezterm ls-fonts --list-system`:

| Variante        | Weight | TTF File                                    | Uso                          |
|-----------------|--------|---------------------------------------------|------------------------------|
| Regular         | 400    | `UbuntuSansMonoNerdFont-Regular.ttf`        | texto principal (Normal)     |
| Italic          | 400i   | `UbuntuSansMonoNerdFont-Italic.ttf`         | Normal italic                |
| Medium          | 500    | `UbuntuSansMonoNerdFont-Medium.ttf`         | Half/dim (inlay hints)       |
| MediumItalic    | 500i   | `UbuntuSansMonoNerdFont-MediumItalic.ttf`   | Half+italic (ghost text)     |
| SemiBold        | 600    | `UbuntuSansMonoNerdFont-SemiBold.ttf`       | titlebar/tab bar (WezTerm)   |
| SemiBoldItalic  | 600i   | `UbuntuSansMonoNerdFont-SemiBoldItalic.ttf` | (disponible)                 |
| Bold            | 700    | `UbuntuSansMonoNerdFont-Bold.ttf`           | Bold real (terminal bold)    |
| BoldItalic      | 700i   | `UbuntuSansMonoNerdFont-BoldItalic.ttf`     | Bold+italic real             |

### Jerarquía tipográfica de 4 niveles — CERO síntesis

```
Half   → Medium (500)   — inlay hints, ghost text, UI secundario dim
Normal → Regular (400)  — código principal
Title  → SemiBold (600) — titlebar WezTerm, tab titles
Bold   → Bold (700)     — énfasis, terminal bold, headings markdown
```

### Configuración WezTerm (`.wezterm.lua`)

```lua
local FONTS = {
    ubuntu = {
        family      = "UbuntuSansMono Nerd Font",
        size        = 9.5,         -- +densidad vs 10.0 anterior (+~5% líneas/pantalla)
        line_height = 0.95,        -- leading compacto sin fatiga visual
        cell_width  = 1.0,         -- proporción canónica Ubuntu
        w_regular   = "Regular",   -- 400 — texto principal
        w_medium    = "Medium",    -- 500 — Half/dim
        w_semibold  = "DemiBold",  -- 600 — titlebar (WezTerm enum = DemiBold)
        w_bold      = "Bold",      -- 700 — bold real
    },
}
```

### font_rules: 5 reglas únicas, cobertura 100%

| # | intensity | italic | TTF usado             | Antes (bug)            |
|---|-----------|--------|-----------------------|------------------------|
| 1 | Bold      | true   | BoldItalic.ttf (700i) | ✓ correcto             |
| 2 | Bold      | false  | Bold.ttf (700)        | ✗ FALTABA (duplicaba regla 1) |
| 3 | Normal    | true   | Italic.ttf (400i)     | ✓ correcto             |
| 4 | Half      | true   | MediumItalic.ttf (500i) | ✗ usaba `AF.w_half` (key inexistente) |
| 5 | Half      | false  | Medium.ttf (500)      | ✗ FALTABA (duplicaba regla 4) |

**Mejora clave**: Bold non-italic y Half non-italic ahora usan TTFs reales (700 y 500) en
lugar de síntesis algorítmica del motor de fuentes. Resultado: bold más limpio y nítido,
dim más sutil sin artefactos de síntesis.

### Parámetros de renderizado

```lua
config.freetype_load_target    = "Normal"          -- garantiza variantes reales en Windows
config.freetype_render_target  = "HorizontalLcd"   -- ClearType subpixel rendering
config.freetype_interpreter_version = 40
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1", "zero=1", "kern=1", "cv31=1" }
```

- `freetype_load_target = "Normal"`: `Light` puede causar fallos en la selección de variantes
  bold/italic en Windows con DirectWrite. `Normal` garantiza el match exacto con los TTFs.
- `freetype_render_target = "HorizontalLcd"`: subpixel horizontal (ClearType) — óptimo para
  pantallas LCD de escritorio, mayor nitidez percibida en tamaños pequeños (9.75pt).
- `anti_alias_custom_block_glyphs = true`: antialiasing en glyphs de bloque nativos (bordes suaves).
- `animation_fps = 120`: animations internas WezTerm a 120fps (tab bar, cursor, visual_bell).
- `stretch="Normal"` eliminado de font specs: causa "miss" en DirectWrite Windows.


### window_frame

```lua
config.window_frame = {
    font = wezterm.font({ family = AF.family, weight = AF.w_semibold }),  -- SemiBold(600) real
    font_size = AF.size + 0.8,  -- 10.3pt para titlebar/tabs
    ...
}
```

---

## 6. MEJORAS REALIZADAS

### WezTerm — Sesión 1 (font_rules + scheme)

| Cambio | Antes | Después | Impacto |
|--------|-------|---------|---------|
| Iosevka eliminado | 2 familias en FONTS | Solo ubuntu | Simplificación, sin código muerto |
| `font_size` | 10.0pt | 9.5pt | +~5% líneas visibles/pantalla |
| `line_height` | 1.0 | 0.95 | +~5% densidad de información |
| font_rules Rule 2 | duplicado de Rule 1 (Bold+italic) | Bold non-italic → Bold.ttf real | Cero síntesis para bold |
| font_rules Rule 4 | `AF.w_half` (key inexistente) → crash | Half+italic → MediumItalic.ttf real | Fix crítico |
| font_rules Rule 5 | duplicado de Rule 4 (Half+italic) | Half non-italic → Medium.ttf real | Cero síntesis para dim |
| `window_frame` | `AF.w_title` (key inexistente) → crash | `AF.w_semibold` → SemiBold.ttf real | Fix crítico |
| FONTS struct keys | `w_half`, `w_title` (inconsistentes) | `w_medium`, `w_semibold` (semánticos) | Claridad + correctitud |

### WezTerm — Sesión 2 (refinamiento premium)

| Cambio | Antes | Después | Impacto |
|--------|-------|---------|---------|
| `font_size` | 9.5pt | **9.75pt** | Mínimo aumento: +legibilidad, mantiene densidad |
| `line_height` | 0.95 | **0.96** | Calibrado para 9.75pt |
| `selection_fg` (todos los schemes) | `"#cdd6f4"` / `M.fg` / etc. | **omitido** | Sintaxis PRESERVADA en selección — token colors visibles |
| `cursor_blink_ease_in/out` | "Constant" (on/off brusco) | **"EaseInOut"** | Parpadeo suave y elegante |
| `animation_fps` | 60 | **120** | Animations WezTerm 2x más fluidas |
| `anti_alias_custom_block_glyphs` | no configurado | **true** | Block glyphs con bordes suaves |

### Neovim — Sesión 2 (refinamiento premium)

| Cambio | Antes | Después | Impacto |
|--------|-------|---------|---------|
| `Visual` fg | `fg = "#f8f8f2"` (blanco explícito) | **omitido** | Sintaxis visible en visual mode |
| mini.animate open/close | deshabilitado | **habilitado con filtro** | Floats/snacks/fzf animados; neo-tree excluido |
| mouse scroll | 5 líneas / 80ms | **4 líneas / 70ms** | Más control, menos overshooting |

### Neovim — Sesión 1 (autocmds.lua — SublimeOverrides)

| Cambio | Antes | Después |
|--------|-------|---------|
| `DiagnosticError/Warn/Info/Hint` | Solo DiagnosticUnnecessary (catppuccin) | 16 grupos completos (base/VirtualText/Underline/Floating/Sign) en colores Monokai ST3 |
| `DiagnosticDeprecated` | No definido | `#75715e` + strikethrough |
| `SatelliteDiagnostic*` | Catppuccin `C.red/C.yellow/C.sky/C.teal` | Monokai `#f92672/#e6db74/#66d9ef/#ae81ff` |
| `SatelliteGitsigns*` | Catppuccin colors | Monokai muted `#81b88b/#e2c08d/#c74e39` |
| `RainbowDelimiter*` | No definido (catppuccin defaults) | 7 niveles Monokai espectral (sync sonokai overrides) |

---

## 7. ARCHIVOS CLAVE

| Archivo | Descripción |
|---------|-------------|
| `colors/sublime.lua` | Entry point: carga catppuccin, dispara `ColorScheme sublime` |
| `lua/config/autocmds.lua` | `SublimeOverrides` group (~600 líneas): sobreescritura quirúrgica |
| `lua/plugins/colorscheme.lua` | Configuración catppuccin (base), kanagawa, sonokai |
| `~/.wezterm.lua` | WezTerm: fonts + theme sync + tab bar + keymaps |
| `syntax.json` | TextMate rules Monokai Night (referencia token colors) |
| `monokai.jsonc` | VS Code theme completo (referencia surfaces + git + UI) |
| `~/.nvim_theme` | Bridge nvim→WezTerm: escribe nombre del tema activo |
| `~/.nvim_font` | Bridge nvim→WezTerm: escribe preset de fuente activo |
