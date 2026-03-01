# Links en Neovim + WezTerm en Windows 11

## El problema raíz

Son dos capas independientes que hay que resolver por separado:

1. **WezTerm** captura o no el click antes de que llegue a Neovim
2. **Neovim** necesita saber qué hacer con la URL/link una vez detectado

---

## Capa 1: WezTerm — URLs en output de terminal

### Por qué Ctrl+Click no funciona por defecto dentro de Neovim

La documentación oficial de WezTerm lo dice explícitamente: cuando Neovim tiene `mouse=a` activo (mouse reporting habilitado), **el evento del mouse lo captura Neovim primero**, no WezTerm. La única forma de forzar que WezTerm lo intercepte es usar el campo `mouse_reporting=true` en el binding para que aplique _incluso cuando_ la app tiene mouse reporting activo.

Fuente: https://wezterm.org/config/mouse.html (sección "Configuring Mouse Assignments")

### Lo que ya tenemos: ALT+U QuickSelect

Nuestra `.wezterm.lua` resuelve URLs en output de terminal mediante **ALT+U QuickSelect**:

```lua
-- .wezterm.lua (ya configurado)
{
  key = "u",
  mods = "ALT",
  action = act.QuickSelectArgs({
    label = "open url",
    patterns = { "https?://[^\\s\"'<>()\\[\\]{}]+" },
    action = wezterm.action_callback(function(window, pane)
      local url = window:get_selection_text_for_pane(pane)
      wezterm.open_with(url)
    end),
  }),
},
```

**ALT+U**: resalta todas las URLs visibles en el terminal → escribe la letra del hint → URL se abre en el navegador. 100% teclado, cero ratón. Funciona en cualquier contexto: output de comandos, logs, kulala, APIs REST.

### Decisión: mouse_bindings vacío

`mouse_bindings` vacío → **todo el mouse pasa a Neovim** → nuestro handler personalizado `_open_url_at_cursor()` maneja tanto URLs externas como links internos de Markdown. Es la opción más simple y efectiva.

Si se activara `mouse_reporting=true` en WezTerm para Ctrl+Click, WezTerm interceptaría ANTES que Neovim → los links internos de Markdown `[texto](./file.md)` no funcionarían con mouse.

---

## Capa 2: Neovim — handler personalizado en keymaps.lua

### Que cambió desde Neovim 0.10 (nuestra versión: 0.11.6)

Desde Neovim 0.10, `gx` ya **no depende de netrw**. Ahora usa `vim.ui.open()` que llama al sistema operativo directamente. En Windows usa `explorer.exe` para abrir URLs vía el handler por defecto del sistema.

### Handler personalizado: LSP Aware (URLs externas + links Markdown + Go to Definition)

En `keymaps.lua` tenemos un handler propio que ahora es "LSP Aware":

```lua
-- Ctrl+Click: Go to Definition (LSP) o abrir URL/link (Markdown)
-- Equivalente exacto a Ctrl+Click de VSCode:
--   En .cs → salta a la definicion de la interfaz, modelo, repositorio, etc.
--   En .md → sigue el link interno o abre URL en browser
--   Sin LSP → abre URL bajo el cursor
local function _smart_click()
  local pos = vim.fn.getmousepos()
  if pos.winid ~= 0 then
    vim.api.nvim_set_current_win(pos.winid)
    vim.api.nvim_win_set_cursor(pos.winid, { pos.line, pos.column - 1 })
  end
  -- Si hay LSP activo en el buffer → Go to Definition
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients > 0 then
    vim.lsp.buf.definition()
    return
  end
  -- Sin LSP → URL/markdown link handler
  _open_url_at_cursor()
end

vim.keymap.set("n", "<C-LeftMouse>",   _smart_click, { desc = "Ctrl+Click: Go to Definition / URL" })
vim.keymap.set("n", "<C-S-LeftMouse>", _smart_click, { desc = "Ctrl+Shift+Click: Go to Definition / URL" })
```

**Bindings activos:**

| Keymap            | Contexto                        | Qué hace                                                |
| ----------------- | ------------------------------- | ------------------------------------------------------- |
| `gx`              | Normal mode                     | Abre URL externa en browser, o link interno con `:edit` |
| `<C-LeftMouse>`   | Normal mode                     | Si hay LSP → **Go to Definition**. Si no → ejecuta `gx` |
| `<C-S-LeftMouse>` | Normal mode                     | Igual que Ctrl+Click (fallback)                         |
| `ALT+U`           | WezTerm (cualquier app)         | QuickSelect de URLs visibles en terminal                |
| `Enter`           | Markdown (follow-md-links.nvim) | Sigue link bajo cursor                                  |
| `<BS>`            | Markdown (follow-md-links.nvim) | Vuelve al archivo anterior                              |

---

## Capa 3: Navegación de código (.NET / C#)

Para lograr el Ctrl+Click equivalente a VSCode en C# (saltar a interfaces, modelos, clases base), configuramos `csharp_ls` (un LSP liguero basado en Roslyn) a través de `mason.nvim` junto con Treesitter para la sintaxis. Configurado en `lua/plugins/csharp.lua`.

**Navegación nativa de Neovim con C#:**

- `Ctrl+Click` o `gd` → Ir a Definición (salta a la interfaz/clase real)
- `gi` → Ir a Implementación (salta de la interfaz `IObraRepository` a `ObraRepository`)
- `gr` → Buscar Referencias
- `K` → Hover (muestra la firma del método y documentación)
- `gpd`, `gpi`, `gpr` → Preview de las anteriores en una ventana flotante (gracias a `goto-preview.nvim`)

---

## Capa 4: follow-md-links.nvim — Enter para seguir links

Complemento en `markdown.lua` para navegación rápida con Enter:

```lua
{
  "jghauser/follow-md-links.nvim",
  ft = "markdown",
},
```

Soporta: paths absolutos, relativos, `~/path`, `file.md#heading`, `[ref][label]`, `<url>`, web links.
Enter sigue el link, `<BS>` (`edit #`) vuelve al archivo anterior.

---

## Resumen: cobertura completa

| Caso de uso                               | Estado | Solución                                       |
| ----------------------------------------- | ------ | ---------------------------------------------- |
| Navegar código C# (Interfaces/Modelos)    | ✅     | LSP `csharp_ls` + `Ctrl+Click` / `gd`          |
| Ver Referencias/Implementaciones de BD    | ✅     | LSP `gr` / `gi`                                |
| URLs externas con teclado (`gx`)          | ✅     | `_open_url_at_cursor()` → `vim.ui.open()`      |
| URLs externas con mouse                   | ✅     | `<C-LeftMouse>` → `_smart_click()`             |
| URLs en output de terminal                | ✅     | `ALT+U` (WezTerm QuickSelect)                  |
| Links internos `[text](./file.md)` con gx | ✅     | `_open_url_at_cursor()` → `:edit` relativo     |
| Links internos con Enter                  | ✅     | `follow-md-links.nvim`                         |
| Links con ancla `#heading`                | ✅     | Handler busca heading, follow-md-links soporta |
| Renderizado visual de links               | ✅     | `render-markdown.nvim`                         |

---

## Lo que se logró: El equivalente a VSCode

Con la integración de `csharp_ls` y el handler inteligente `_smart_click`, Neovim **ahora iguala la capacidad type-aware de VSCode**.

Si haces `Ctrl+Click` en un modelo de la base de datos o una interfaz en C#, el _Language Server_ parsea el proyecto `.csproj`, resuelve las referencias cruzadas y te lleva directamente a la implementación física del archivo, logrando exactamente el flujo de trabajo demandado para proyectos .NET Web API y MVC.

