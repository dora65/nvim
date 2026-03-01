[https://kick.com/elmichij](https://kick.com/elmichij)

# Manual de transicion VSCode → Neovim

## Windows 11 + WezTerm + LazyVim — Solo informacion de expertos

---

## INDICE

1. [El sistema de archivos de nvim: buffers, swap y por que aparecen vacios](#1-el-sistema-de-archivos-buffers-swap-y-archivos-vacios)
2. [Modelo mental: Buffer vs Ventana vs Tab](#2-modelo-mental-buffer-vs-ventana-vs-tab)
3. [Tabla de keymaps: tu VSCode vs tu nvim actual](#3-tabla-de-keymaps)
4. [Gaps criticos: lo que falta mapear](#4-gaps-criticos)
5. [Conceptos de nvim sin equivalente en VSCode](#5-conceptos-sin-equivalente-en-vscde)
6. [Plugins criticos que no tienes y son infaltables](#6-plugins-criticos-faltantes)
7. [Opciones de experto que pocos configuran](#7-opciones-de-experto)
8. [WezTerm + Windows 11: configuracion de nivel avanzado](#8-wezterm--windows-11)
9. [El argumento hjkl: cuando importa y cuando no](#9-el-argumento-hjkl)
10. [Plugins instalados: referencia rapida](#10-plugins-instalados-referencia-rapida)

---

## 1. El sistema de archivos: buffers, swap y archivos vacios

### Por que un archivo se ve en blanco cuando tiene contenido

Hay tres causas distintas. Necesitas identificar cual es la tuya.

**Causa A — Swap file recovery (la mas comun)**

Cuando nvim abre un archivo, crea inmediatamente un archivo oculto `.nombre.ext.swp` en el mismo directorio (o en tu `undodir` configurado). Este archivo es el diario de escritura en tiempo real, equivalente a un autosave de emergencia.

Si nvim se cierra de forma anormal (cerrar WezTerm con la X, `Ctrl+C` en el proceso, crash), el swap queda en disco. La proxima vez que abres ese archivo:

```
E325: ATTENTION
Found a swap file by the name ".archivo.lua.swp"
          owned by: TU_USUARIO   dated: ...
         file name: ~\ruta\archivo.lua
          modified: YES
         user name: TU_USUARIO
        host name: TU_PC
       process ID: 12345 (still running?)

(1) Another program may be editing the same file.  If this is the case,
    be careful not to end up with two different instances of the same
    file when making changes.  Quit, or continue with caution.
(2) An edit session for this file crashed.

[O]pen Read-Only, (E)dit anyway, (R)ecover, (D)elete it, (Q)uit, (A)bort:
```

- `E` (Edit anyway): abre el archivo desde disco IGNORANDO el swap. Si el swap tenia cambios no guardados, esos cambios desaparecen. El archivo del disco puede estar en blanco si nunca se guardo.
- `R` (Recover): reconstruye el archivo desde el swap. Usa esto si cerraste nvim sin guardar trabajo real.
- `D` (Delete it): borra el swap y abre el disco. Correcto cuando el swap es residuo de una sesion anterior ya terminada.

**La raiz del problema:** nvim NO guarda automaticamente como VSCode. Si no ejecutaste `:w` o `Ctrl+S`, el contenido solo existe en el swap, no en disco. Si el archivo en disco estaba vacio antes de tu sesion, sigue vacio.

**Causa B — El buffer temporal del neo-tree al inicio**

Tu config en `neo-tree.lua` abre neo-tree al iniciar nvim sin argumentos (`argc == 0`). Esto crea dos ventanas: neo-tree a la izquierda y un buffer sin nombre a la derecha. Ese buffer de la derecha es un "Untitled" — exactamente como un archivo nuevo en VSCode. No tiene contenido porque no le asignaste archivo.

Si luego abres un archivo desde neo-tree con Enter, ese archivo reemplaza ese buffer temporal. Si no lo haces, ves "nada" en blanco. No es un error.

**Causa C — El modelo de servidor/cliente de nvim (la menos obvia)**

Nvim no tiene un proceso unico compartido como VSCode. Cada vez que ejecutas `nvim` en una terminal, es una instancia completamente nueva e independiente. Si tienes nvim corriendo en WezTerm y abres un archivo haciendo doble clic en el Explorador de Windows (si configuraste nvim como programa predeterminado), Windows abre una NUEVA instancia de nvim, no agrega el archivo a la existente.

Esa nueva instancia puede abrir el archivo correctamente, pero si la terminal subyacente tiene problemas de renderizado al inicio (WezTerm inicializando), puedes ver un destello en blanco antes de que cargue.

La solucion real es usar el modo servidor:

```powershell
# En tu primer nvim (o en tu config de WezTerm):
nvim --listen \\.\pipe\nvim-server

# Para abrir archivos en esa instancia desde otra terminal:
nvim --server \\.\pipe\nvim-server --remote-send "<cmd>e C:\ruta\archivo.lua<CR>"
```

Esto es equivalente a `code archivo.lua` abriendo en la ventana de VSCode ya abierta.

### Nvim crea versiones del mismo archivo?

No en el sentido de version control. Lo que crea es:

| Archivo               | Proposito                     | Donde                  | Cuando se borra            |
| --------------------- | ----------------------------- | ---------------------- | -------------------------- |
| `.archivo.swp`        | Recuperacion de crash         | Mismo dir o `swapdir`  | Al cerrar nvim limpiamente |
| `undodir/archivo.lua` | Historial de undo persistente | Tu `%TEMP%\nvim-undo\` | Nunca (manual)             |
| Backup `archivo~`     | Backup antes de sobreescribir | `backupdir`            | Al siguiente guardado      |

Tu config ya tiene `undodir` configurado en `%TEMP%\nvim-undo`. Esto significa que puedes deshacer cambios de sesiones anteriores incluso despues de reiniciar nvim. En VSCode esto no existe — cuando cierras, el historial de undo se pierde.

**Ventaja critica que VSCode no tiene:** con `undofile = true` (activalo si no esta) puedes abrir un archivo que editaste hace 3 dias y seguir deshaciendo hasta el estado original. Esto tambien significa que el archivo `undodir` puede crecer. Limpialo manualmente si el disco escasea.

Para activar undo persistente si no esta activo en tu config:

```lua
-- En options.lua
vim.opt.undofile = true  -- persiste historial de undo entre sesiones
vim.opt.undolevels = 10000  -- 10k niveles de undo (default: 1000)
```

---

## 2. Modelo mental: Buffer vs Ventana vs Tab

Este es el cambio conceptual mas importante. En VSCode estos conceptos son implicitos y opacos. En nvim son explicitos y controlables.

```
VSCode:                          Nvim:
┌─────────────────────────┐      ┌─────────────────────────┐
│  Tab 1  │  Tab 2        │      │ Tab (Page) = layout de  │
│  archivo.ts             │      │ ventanas                │
│─────────────────────────│      │─────────────────────────│
│  [Editor visible]       │      │ Ventana = viewport      │
│                         │      │ (muestra un buffer)     │
│                         │      │─────────────────────────│
│                         │      │ Buffer = archivo en     │
└─────────────────────────┘      │ memoria (puede estar    │
                                 │ oculto, sin ventana)    │
                                 └─────────────────────────┘
```

**Buffer**: la representacion en memoria de un archivo. Puede existir sin estar visible en ninguna ventana. Puedes tener 50 buffers cargados y solo ver 2.

**Ventana (window)**: un viewport que muestra un buffer. Puedes abrir el mismo buffer en dos ventanas y editar en ambas simultaneamente — los cambios se sincronizan en tiempo real porque es el mismo buffer.

**Tab**: en nvim, una tab NO es un archivo — es un layout de ventanas. Una tab puede contener 3 ventanas, cada una mostrando un buffer diferente. La mayoria de usuarios avanzados nunca usa tabs de nvim, usan buffers + harpoon.

**La implicacion practica:**

```
VSCode: cerrar tab = cerrar archivo
Nvim:   cerrar ventana != cerrar buffer
        :bd   → borra el buffer (equivalente a cerrar tab en VSCode)
        :q    → cierra la ventana (el buffer sigue en memoria)
        :wq   → guarda y cierra ventana
        :bw   → borra completamente el buffer de memoria (wipeout)
```

---

## 3. Tabla de keymaps

### Leyenda de estado

- **ACTIVO**: ya funciona en tu nvim tal como en VSCode
- **DIFERENTE**: existe pero con otra tecla
- **FALTA**: no hay equivalente configurado aun
- **CONFLICTO**: la misma tecla hace cosas distintas segun contexto

### Tabla principal

| Accion              | VSCode tuyo          | Nvim actual            | Estado    | Notas                                        |
| ------------------- | -------------------- | ---------------------- | --------- | -------------------------------------------- |
| Guardar             | `Ctrl+S`             | `Ctrl+S`               | ACTIVO    | Identico, con notificacion                   |
| Guardar todos       | `Ctrl+Shift+S`       | no mapeado             | FALTA     | `:wa` en command line                        |
| Copiar              | `Ctrl+C` (visual)    | `Ctrl+C` (visual)      | ACTIVO    |                                              |
| Cortar              | `Ctrl+X` (visual)    | `Ctrl+X` (visual)      | ACTIVO    |                                              |
| Pegar               | `Ctrl+V`             | `Ctrl+V`               | ACTIVO    |                                              |
| Seleccionar todo    | `Ctrl+A`             | `Ctrl+A`               | ACTIVO    |                                              |
| Deshacer            | `Ctrl+Z`             | `Ctrl+Z` (LazyVim)     | ACTIVO    | LazyVim lo mapea                             |
| Rehacer             | `Ctrl+Backspace`     | no mapeado             | FALTA     | Raro en VSCode, usa `Ctrl+R` en normal mode  |
| Buscar archivo      | `Ctrl+Up`            | `<leader><space>`      | DIFERENTE | Snacks picker                                |
| Command palette     | `Ctrl+.`             | `<leader>sc`           | DIFERENTE | Snacks commands                              |
| Buscar en archivos  | `Ctrl+Right`         | `<leader>/`            | DIFERENTE | Live grep                                    |
| Toggle sidebar      | `Ctrl+Left`          | `<leader>e`            | DIFERENTE | Neo-tree toggle                              |
| Toggle terminal     | `Ctrl+Down`          | `<leader>tf`           | DIFERENTE | Terminal flotante                            |
| Ir al explorador    | `Ctrl+E`             | `<leader>e`            | DIFERENTE |                                              |
| Cerrar editor       | `Ctrl+W`             | `:bd` manual           | FALTA     | Necesita mapeo                               |
| Nueva tab/archivo   | `Ctrl+T`             | no mapeado             | FALTA     | `:enew`                                      |
| Ir a editor 1-9     | `Ctrl+1..9`          | no mapeado             | FALTA     | Concepto distinto en nvim                    |
| Comentar linea      | `Ctrl+7`             | `gc` (LazyVim)         | DIFERENTE | `gcc` en linea, `gc` en seleccion            |
| Buscar y reemplazar | `Ctrl+R`             | no mapeado en nvim     | FALTA     | `:s/viejo/nuevo/g` o `<leader>sf` (grug-far) |
| Formatear           | `Ctrl+K Ctrl+D`      | `<leader>cf` (LazyVim) | DIFERENTE | Conform.nvim                                 |
| Ir a definicion     | `F12`                | `gd` (LazyVim)         | DIFERENTE | LSP nativo                                   |
| Peek definicion     | `Alt+F12`            | `gpd` (goto-preview)   | DIFERENTE | Activo en tu config                          |
| Ver referencias     | `Shift+F12`          | `gr` (LazyVim)         | DIFERENTE | LSP nativo                                   |
| Renombrar simbolo   | `F2`                 | `<leader>cr` (LazyVim) | DIFERENTE | LSP nativo                                   |
| Code actions        | `Ctrl+.` (editor)    | `<leader>ca` (LazyVim) | DIFERENTE | LSP nativo                                   |
| Toggle sidebar izq  | `Ctrl+Alt+Left`      | `Ctrl+Alt+Left`        | ACTIVO    | Split nav                                    |
| Redimensionar split | `Ctrl+Shift+flechas` | `Ctrl+Shift+flechas`   | ACTIVO    |                                              |
| Cambiar buffer      | `Ctrl+Tab`           | `Ctrl+Tab`             | ACTIVO    | Snacks picker                                |
| Siguiente buffer    | `Alt+Right`          | `Alt+Right`            | ACTIVO    |                                              |
| Buffer anterior     | `Alt+Left`           | `Alt+Left`             | ACTIVO    |                                              |
| Zoom full screen    | `Alt+F`              | no mapeado             | FALTA     | `:ZenMode` disponible                        |
| Preview markdown    | `Ctrl+Shift+N`       | no mapeado             | FALTA     | Render.nvim activo pero sin atajo            |
| Bookmarks           | `Ctrl+Numpad5`       | no mapeado             | FALTA     | Harpoon es equivalente superior              |
| Ir a linea          | `Ctrl+G`             | `<leader>sg` / `:123`  | DIFERENTE | `:123<Enter>` va directo a linea             |
| Scroll centrado     | —                    | `Ctrl+D` / `Ctrl+U`    | EXTRA     | Scroll + centrado automatico                 |
| Oil file manager    | —                    | `-`                    | EXTRA     | Edicion de archivos como texto               |
| Copiar ruta         | —                    | `<leader>yp`           | EXTRA     | Copia ruta absoluta al clipboard             |

### Ventajas y desventajas comparadas

| Categoria                  | VSCode                    | Nvim                         | Ventaja                                                    |
| -------------------------- | ------------------------- | ---------------------------- | ---------------------------------------------------------- |
| Busqueda fuzzy             | Rapida, GUI               | Snacks/fzf-lua, terminal     | Empate: snacks es equivalente en velocidad                 |
| Command palette            | `Ctrl+Shift+P` completo   | `<leader>sc` + `:`           | VSCode mas descubrible, nvim mas rapido con muscle memory  |
| Buscar en proyecto         | `Ctrl+Right` → panel      | `<leader>/` con ripgrep      | Nvim: resultado en buffer editable, VSCode: panel separado |
| Ir a definicion            | Click o F12               | `gd`, peek con `gpd`         | Nvim: peek en floating window sin perder contexto actual   |
| Multiple cursors           | `Ctrl+D`, `Ctrl+Shift+Up` | Limitado: `vim-visual-multi` | VSCode gana en UX de multicursor                           |
| Refactor                   | Copilot + Language server | LSP + AI (Avante/Copilot)    | Equivalentes                                               |
| Terminal integrado         | Panel inferior            | Toggleterm flotante          | Nvim: terminal flotante no roba espacio de codigo          |
| Undo history               | Se pierde al cerrar       | Persistente entre sesiones   | Nvim gana significativamente                               |
| Git integration            | GitLens (extension)       | Gitsigns + git.nvim          | Equivalentes, nvim mas ligero                              |
| Find/replace en archivo    | GUI panel                 | `:s/a/b/gc` o grug-far       | VSCode mas accesible, nvim mas potente con regex           |
| Find/replace multi-archivo | Search panel              | grug-far en buffer editable  | Nvim gana: editas el resultado directamente                |
| Extensiones/plugins        | Marketplace GUI           | lazy.nvim + lua              | VSCode mas accesible, nvim mas controlable                 |
| Startup                    | 2-4 segundos              | 50-150ms con lazy loading    | Nvim gana                                                  |
| Uso de RAM                 | 300-800MB tipico          | 30-80MB                      | Nvim gana                                                  |

---

## 4. Gaps criticos

Estos son los keymaps de VSCode que usas y que NO estan en tu nvim. Son los que necesitas agregar para no perder productividad.

Agrega esto en `lua/config/keymaps.lua`:

```lua
-- ─── GAPS: Mapeos faltantes respecto a VSCode ──────────────────────────────

-- Cerrar buffer actual (equivalente Ctrl+W en VSCode)
vim.keymap.set("n", "<C-w>", function()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  if #bufs <= 1 then
    vim.notify("Ultimo buffer — usa :q para salir", vim.log.levels.WARN)
    return
  end
  vim.cmd("bdelete")
end, { desc = "Close buffer" })

-- Guardar todos (equivalente Ctrl+Shift+S)
vim.keymap.set({ "n", "i" }, "<C-S-s>", "<cmd>wall<cr>", { desc = "Save all buffers" })

-- Nuevo archivo sin nombre (equivalente Ctrl+T)
vim.keymap.set("n", "<C-t>", "<cmd>enew<cr>", { desc = "New empty buffer" })

-- Command palette equivalente (equivalente Ctrl+. de VSCode)
vim.keymap.set("n", "<C-S-p>", function()
  require("snacks").picker.commands()
end, { desc = "Command palette" })

-- Buscar archivo (equivalente Ctrl+Up de VSCode)
vim.keymap.set("n", "<C-Up>", function()
  require("snacks").picker.smart()
end, { desc = "Find files (smart)" })

-- Buscar en proyecto (equivalente Ctrl+Right de VSCode)
-- NOTA: Ctrl+Right tiene conflicto en tu VSCode (3 comandos distintos)
-- En nvim lo separamos limpiamente:
vim.keymap.set("n", "<C-Right>", function()
  require("snacks").picker.grep()
end, { desc = "Live grep in project" })

-- Comentar linea (equivalente Ctrl+7 de VSCode)
-- LazyVim ya tiene 'gcc' en normal y 'gc' en visual
-- Este mapeo adiciona Ctrl+7 identico a VSCode:
vim.keymap.set("n", "<C-7>", "gcc", { remap = true, desc = "Toggle comment line" })
vim.keymap.set("v", "<C-7>", "gc",  { remap = true, desc = "Toggle comment selection" })

-- Ir a linea (equivalente Ctrl+G de VSCode)
vim.keymap.set("n", "<C-g>", function()
  local line = vim.fn.input("Go to line: ")
  if line ~= "" then
    vim.cmd(line)
  end
end, { desc = "Go to line" })
```

**Nota sobre `Ctrl+1..9` (abrir editor por indice):**
En nvim el concepto no existe directamente porque los buffers no tienen posicion fija como las tabs de VSCode. El equivalente de expertos es **Harpoon**, que ya tienes instalado. Harpoon asigna hasta 4-5 buffers "pinned" a teclas fijas. Es superior porque sobrevive entre sesiones y es intencionado.

```lua
-- Harpoon: marca rapida (ya instalado, agrega si no tienes mappings)
vim.keymap.set("n", "<C-1>", function() require("harpoon"):list():select(1) end)
vim.keymap.set("n", "<C-2>", function() require("harpoon"):list():select(2) end)
vim.keymap.set("n", "<C-3>", function() require("harpoon"):list():select(3) end)
vim.keymap.set("n", "<C-4>", function() require("harpoon"):list():select(4) end)
vim.keymap.set("n", "<leader>ha", function() require("harpoon"):list():add() end, { desc = "Harpoon add" })
vim.keymap.set("n", "<leader>hh", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, { desc = "Harpoon menu" })
```

---

## 5. Conceptos sin equivalente en VSCode

### 5.1 El Jumplist — back/forward de verdad

VSCode tiene "Go Back" (`Alt+Left`) y "Go Forward" (`Alt+Right`). Nvim tiene el jumplist, que es mas potente: registra cada salto significativo (busqueda, ir a definicion, salto de linea grande, cambio de archivo).

| Accion                     | Nvim     |
| -------------------------- | -------- |
| Ir atras en el jumplist    | `Ctrl+O` |
| Ir adelante en el jumplist | `Ctrl+I` |
| Ver el jumplist completo   | `:jumps` |

En tu config ya tienes `Ctrl+O` libre (no esta mapeado a otra cosa). Usalo. Es el equivalente directo de `Alt+Left` de VSCode pero funciona entre archivos, busquedas, y saltos de LSP.

### 5.2 Registers — multiples clipboards

VSCode tiene un solo clipboard. Nvim tiene 26 registros nombrados (`"a` a `"z`) mas registros especiales:

| Registro | Contenido                                                |
| -------- | -------------------------------------------------------- |
| `"`      | Registro por defecto (ultimo yank/delete)                |
| `+`      | Clipboard del sistema (el que usa tu Ctrl+C/V)           |
| `*`      | Clipboard de seleccion primaria (X11/Wayland)            |
| `0`      | Ultimo yank (no delete)                                  |
| `1`-`9`  | Historial de los ultimos 9 deletes grandes               |
| `_`      | Registro negro (descarta el contenido, no contamina `"`) |
| `/`      | Ultimo patron de busqueda                                |
| `:`      | Ultimo comando ejecutado                                 |
| `%`      | Nombre del archivo actual                                |

**Uso practico:**

```
"ayy   → copia la linea al registro 'a'
"ap    → pega el contenido del registro 'a'
"+y    → copia al clipboard del sistema (lo que hace tu Ctrl+C)
"_d    → borra sin contaminar el registro por defecto
```

Por que importa: cuando haces `dd` (borrar linea) y luego `p` (pegar), pegas la linea borrada porque `dd` escribe en el registro `"`. Si quieres pegar algo que copiaste antes, el delete lo sobreescribio. Solucion: copia con `"ay` antes del delete, pega con `"ap`.

### 5.3 Text Objects — donde esta el poder real

Esto no existe en VSCode de forma nativa. Es la razon por la que los usuarios avanzados de nvim son genuinamente mas eficientes en edicion de texto.

Un text object es una unidad semantica del texto. La sintaxis es: `[operador][text object]`

| Text object | Significado                                |
| ----------- | ------------------------------------------ |
| `iw`        | inner word (palabra sin espacios)          |
| `aw`        | a word (palabra con espacios circundantes) |
| `is`        | inner sentence                             |
| `ip`        | inner paragraph                            |
| `i"`        | inner quotes (contenido entre comillas)    |
| `a"`        | a quotes (incluye las comillas)            |
| `i(` o `ib` | inner block/parenthesis                    |
| `i{` o `iB` | inner curly block                          |
| `it`        | inner tag (HTML/XML)                       |
| `i]`        | inner bracket                              |

Operadores: `d` (delete/cut), `c` (change = delete + insert), `y` (yank/copy), `v` (select visual), `=` (format)

**Ejemplos practicos:**

```
ci"   → borra el contenido entre comillas y entra en insert mode  (Change Inner "")
di(   → borra el contenido entre parentesis
yip   → copia el parrafo completo
dap   → borra el parrafo completo incluyendo linea en blanco
ci{   → borra el contenido de un bloque {} y entra a editar — extremadamente util en code
vit   → selecciona el contenido de un tag HTML
=ip   → formatea el parrafo segun las reglas de indentacion
```

Esto es lo que los usuarios avanzados quieren decir cuando dicen que nvim es mas eficiente. No es hjkl. Es que `ci"` borra y entra a editar entre comillas con 3 teclas. En VSCode necesitas: doble click para seleccionar, verificar que no incluyas las comillas, luego escribir.

### 5.4 Macros — automatizacion instantanea

VSCode tiene multi-cursor. Nvim tiene macros: secuencias de teclas grabadas y reproducibles.

```
qq     → inicia grabacion en registro 'q'
[haz lo que quieras]
q      → para la grabacion
@q     → reproduce la macro una vez
100@q  → reproduce la macro 100 veces
@@     → repite la ultima macro
```

Caso de uso real: tienes 50 lineas con el formato `const foo = "bar"` y necesitas cambiarlas a `const foo: string = "bar"`. Con multi-cursor en VSCode es posible pero enganoso si las lineas no son identicas. Con una macro en nvim: grabar la accion en una linea, reproducir 50 veces.

### 5.5 Marks — bookmarks superiores

VSCode tiene bookmarks (extension). Nvim tiene marks incorporados al editor:

```
ma     → marca la posicion actual como 'a' (local al archivo)
'a     → salta al inicio de la linea marcada 'a'
`a     → salta exactamente a la posicion marcada 'a'
mA     → marca global (mayuscula = persiste entre archivos)
'A     → salta al archivo y linea de la marca global 'A'
''     → salta a la posicion antes del ultimo salto
'.     → salta a la ultima posicion donde se hizo un cambio
```

### 5.6 El modo Visual Block — sin equivalente en VSCode

`Ctrl+V` en modo normal activa Visual Block. Permite seleccionar columnas rectangulares de texto:

```
Ctrl+V → entra a visual block
[selecciona columnas con flechas o hjkl]
I      → inserta texto al inicio de todas las lineas seleccionadas
A      → inserta texto al final de todas las lineas seleccionadas
d      → borra las columnas seleccionadas
~      → alterna mayusculas/minusculas en la seleccion
```

Caso de uso: tienes 10 lineas y quieres agregar un comentario `//` al inicio de cada una. En VSCode: `Ctrl+Shift+Up/Down` para multicursor + escribir. En nvim: `Ctrl+V`, selecciona las 10 lineas, `I`, escribe `// `, `Esc`.

---

## 6. Plugins criticos faltantes

Estos son los plugins que los usuarios expertos de nvim consideran esenciales y que tu config no tiene.

### 6.1 Persistencia de sesion — CRITICO

**Problema:** cuando cierras nvim y lo vuelves a abrir, pierdes todos los buffers abiertos, los splits, y el directorio de trabajo. VSCode recuerda todo automaticamente.

**Solucion:** `folke/persistence.nvim` (del mismo autor que LazyVim)

```lua
-- En lazy.lua spec o en un nuevo archivo plugins/session.lua
{ import = "lazyvim.plugins.extras.util.persistence" }
```

O directamente:

```lua
{
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = { dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/") },
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't save session" },
  },
}
```

### 6.2 mini.ai — Text objects extendidos

Tu nvim tiene `mini.surround` pero no `mini.ai`. Este plugin extiende los text objects con inteligencia de treesitter.

```lua
{ import = "lazyvim.plugins.extras.coding.mini-ai" }
```

Con mini.ai obtienes text objects adicionales:

- `af` / `if` → a function / inner function (por treesitter, cualquier lenguaje)
- `ac` / `ic` → a class / inner class
- `aa` / `ia` → a argument / inner argument (el parametro de una funcion)
- Busqueda hacia adelante: si no estas dentro de un text object, busca el siguiente

### 6.3 flash.nvim — Navegacion de salto

**Problema:** hjkl y flechas son lentos para saltar a cualquier parte de la pantalla visible.

**flash.nvim** te permite saltar a cualquier posicion visible en 2-3 teclas:

```lua
{ import = "lazyvim.plugins.extras.editor.flash" }
```

Uso: en modo normal presiona `s`, escribe 2 caracteres del destino, aparecen etiquetas de 1-2 letras en cada match, presiona la etiqueta. Llegas en 3-4 teclas a cualquier parte de la pantalla.

### 6.4 undotree — Visualizacion del historial de undo

Nvim tiene undo no lineal. Puedes ramificar el historial de cambios y volver a cualquier estado anterior, incluso si ya deshiciste y rehice. `undotree` lo visualiza:

```lua
{
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  keys = { { "<leader>uu", "<cmd>UndotreeToggle<cr>", desc = "Undo tree" } },
}
```

### 6.5 diffview.nvim — Git diff de nivel profesional

Tu tienes `gitsigns` y `mini.diff` para ver cambios inline. `diffview.nvim` agrega:

- Vista de diff entre cualquier commit/rama
- Vista de historial de un archivo
- Resolucion de conflictos de merge en 3-paneles

```lua
{
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff view" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
  },
}
```

### 6.6 grug-far.nvim — Find and replace en proyecto (ya lo tienes via LazyVim?)

Verifica si esta activo. Es el equivalente de Search & Replace de VSCode pero el resultado es un buffer editable. Cambias el texto directamente en el resultado del replace.

---

## 7. Opciones de experto que pocos configuran

Estas opciones no estan documentadas prominentemente pero los expertos las tienen.

### 7.1 `updatetime` — Velocidad de CursorHold

```lua
vim.opt.updatetime = 200  -- default: 4000ms
```

Esta opcion controla cada cuanto nvim dispara el evento `CursorHold`. Muchos plugins lo usan para mostrar documentacion de LSP, diagnosticos, git blame inline. Con 4000ms (el default) tienes 4 segundos de espera. Con 200ms es casi instantaneo.

### 7.2 `inccommand = "split"` — Ya lo tienes, pero entiendelo

Con esta opcion activa, cuando escribes `:s/viejo/nuevo/g`, nvim abre un split temporal mostrando en tiempo real todos los cambios que se aplicarian. Cierra el split cuando confirmas o cancelas. Es una de las features de nvim que VSCode no tiene equivalente.

### 7.3 `formatoptions` — Control preciso del autoformat

```lua
vim.opt.formatoptions = "jcroqlnt"
```

Cada letra es un comportamiento:

- `j`: elimina comentarios al hacer join de lineas
- `c`: wrap de comentarios automatico
- `r`: inserta el caracter de comentario al presionar Enter en una linea comentada
- `o`: inserta el caracter de comentario al abrir linea nueva con `o/O`
- `q`: permite formatear comentarios con `gq`
- `l`: lineas largas no se parten en insert mode si ya son largas
- `n`: reconoce listas numeradas al formatear

### 7.4 `shada` — Control del historial compartido entre sesiones

```lua
vim.opt.shada = "!,'100,<50,s10,h"
```

`shada` (shared data) es el archivo donde nvim persiste entre sesiones: historial de comandos, marcas globales, historial de busqueda, registros.

- `'100`: recuerda marcas de los ultimos 100 archivos
- `<50`: guarda hasta 50 lineas por registro
- `s10`: omite registros mas grandes de 10KB
- `h`: desactiva el highlight de busqueda al cargar shada

Ubicacion en Windows: `%LOCALAPPDATA%\nvim-data\shada\main.shada`

### 7.5 `virtualedit = "block"` — Ya lo tienes

En visual block puedes moverte mas alla del final de la linea. Util para seleccionar columnas en texto desalineado.

### 7.6 Navegacion entre diagnostics sin plugin

LazyVim ya tiene `]d` y `[d` para ir al siguiente/anterior diagnostico (equivalente a F8 en VSCode). Pocos saben que `]e` y `[e` van solo a errores (ignorando warnings).

### 7.7 `gf` y `gF` — Abrir archivo bajo el cursor

`gf` (go to file): si el cursor esta sobre un path como `./components/Button.tsx`, abre ese archivo. `gF` abre y va a la linea si el path tiene formato `archivo:123`.

En un codebase con muchos imports esto es invaluable. En VSCode necesitas `Ctrl+Click`. En nvim es `gf` sin mover el raton.

### 7.8 Busqueda y reemplazo avanzado

El comando `:s` de nvim tiene capacidades que el Search & Replace de VSCode no tiene:

```
:s/foo/bar/g          → reemplaza en linea actual
:%s/foo/bar/g         → reemplaza en todo el archivo
:%s/foo/bar/gc        → reemplaza con confirmacion por cada ocurrencia
:'<,'>s/foo/bar/g     → reemplaza en la seleccion visual actual
:s/\v(foo)(bar)/\2\1/ → regex avanzado con grupos (muy vim)
```

El flag `\v` activa "very magic" mode donde no necesitas escapar `()[]{}+?`. Es la forma de escribir regex normales.

### 7.9 `inccommand` en accion con `:norm`

```
:%norm A;
```

Agrega `;` al final de cada linea del archivo. Combinado con visual block y `:norm` puedes hacer operaciones en masa que en VSCode requieren scripts.

---

## 8. WezTerm + Windows 11

### 8.1 Configuracion critica que falta en la mayoria

El archivo de config de WezTerm esta en `%USERPROFILE%\.config\wezterm\wezterm.lua` o `%USERPROFILE%\\.wezterm.lua`.

```lua
-- wezterm.lua — configuracion de experto para nvim en Windows 11

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- CRITICO: sin esto, nvim no recibe las teclas modificadas correctamente
config.enable_csi_u_key_encoding = true

-- Permite que nvim distinga Ctrl+i de Tab, Ctrl+m de Enter, etc.
-- Sin esto, muchos keymaps de nvim en terminal son imposibles.
config.keys = {
  -- Evitar que WezTerm intercepte Ctrl+Shift+C (usado por nvim)
  { key = "C", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
}

-- GPU rendering: DirectX en Windows es mas estable que OpenGL
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

-- Sin esto, el cursor de nvim puede parpadear con artefactos en Windows 11
config.animation_fps = 60
config.cursor_blink_rate = 400

-- Fuente con ligatures y Nerd Fonts (critico para iconos de neo-tree/devicons)
config.font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Regular" })
config.font_size = 12.0

-- Evitar que WezTerm consuma Ctrl+Tab antes de que llegue a nvim
config.use_dead_keys = false

-- Transparency: si usas winblend en nvim, esto debe coincidir
config.window_background_opacity = 1.0
```

### 8.2 El problema de las teclas que no llegan a nvim

Windows tiene una capa de interception de teclas antes de WezTerm antes de nvim. En orden de prioridad:

```
Windows (AutoHotkey, IME, etc.)
  → WezTerm (puede interceptar teclas)
    → Shell (PowerShell/bash)
      → Nvim
```

Si un keymap de nvim no responde, el problema esta en alguna de estas capas. Para debuggear en nvim:

```
:verbose map <C-algo>   → muestra si el keymap existe y desde que archivo
:checkhealth            → diagnostico general
```

Para ver exactamente que tecla recibe nvim:

```
:sed → sale de insert mode
i    → entra a insert mode
Ctrl+V luego la tecla → muestra el codigo exacto que recibe nvim
```

### 8.3 PowerShell Core vs PowerShell Legacy

Tu config ya usa `pwsh.exe` (PowerShell Core 7+). Esto es correcto. La diferencia critica: algunos LSP servers instalados con Mason usan comandos que solo funcionan correctamente en PowerShell Core porque el legacy `powershell.exe` tiene encoding diferente.

Si algun LSP server falla silenciosamente, verifica que `pwsh.exe` esta en el PATH antes que `powershell.exe`.

### 8.4 Nerd Fonts — instalacion correcta en Windows

Los iconos de neo-tree, lualine, y todos los devicons requieren una Nerd Font instalada Y configurada en WezTerm. Descarga desde `nerdfonts.com` e instala para "all users" (no solo el usuario actual) para evitar problemas de permisos con WezTerm.

Fuentes recomendadas para Windows 11 (renderizado en pantalla):

- JetBrainsMono Nerd Font — mejor legibilidad en pantallas 1080p
- CaskaydiaCove Nerd Font — basada en Cascadia Code de Microsoft, mejor integracion con Windows

---

## 9. El argumento hjkl

Tu observacion es correcta: no hay ventaja real en reemplazar las teclas de flecha con hjkl si ya tienes las flechas mapeadas y son accesibles.

**La verdad que los evangelistas de vim no dicen explicitamente:**

La ventaja de hjkl no es hjkl en si mismo. La ventaja es que mantienen los dedos en la fila home, lo que SOLO importa cuando los combinas con operadores y contadores:

- `d3j` → borra 3 lineas hacia abajo (si usas flechas: `ddd` tres veces o sin shortcut)
- `y5k` → copia 5 lineas hacia arriba
- `c2w` → cambia las siguientes 2 palabras

Si usas flechas, estos combos no funcionan o son incomodos. Pero si usas text objects (`ci"`, `dap`, `cif`) en lugar de contadores de movimiento, las flechas son suficientes.

**Recomendacion pragmatica:**

No fuerces hjkl para movimiento basico. Aprende text objects. La ganancia de eficiencia viene de `ci"`, `dap`, `cif`, no de `h/j/k/l`.

Lo que si vale aprender para complementar las flechas:

- `w` / `b` → saltar entre palabras (mas rapido que mantener flecha presionada)
- `f{char}` → saltar al siguiente caracter en la linea (`f(` va al siguiente parentesis)
- `%` → saltar entre pares de brackets/parentesis
- `gg` / `G` → inicio/fin del archivo
- `{` / `}` → saltar entre parrafos vacios (bloques de codigo)

Estos complementan las flechas sin reemplazarlas y tienen una curva de adopcion baja.

---

## Estado de tu configuracion actual: diagnostico

**Lo que ya tienes correcto (nivel avanzado):**

- `scrolloff = 8` — oro puro, pocas configs lo tienen
- `inccommand = "split"` — feature premium de nvim, bien configurado
- `splitkeep = "cursor"` — evita jumps visuales al crear splits
- `virtualedit = "block"` — necesario para visual block profesional
- `guicursor` personalizado por modo — coordinado con WezTerm
- `foldmethod = "expr"` con treesitter — el metodo correcto para 2025
- `foldlevel = 99` — archivos abiertos por defecto, correcto
- `listchars` configurado — visibilidad de caracteres especiales, profesional
- `laststatus = 3` — statusline global, el estandar moderno
- `pumheight = 10` — completion limpia, sin overflow
- Swap y backup en `%TEMP%` — evita contaminar repos con archivos .swp
- `snacks_picker` como picker principal — la eleccion correcta para LazyVim 2025
- `neo-tree` con `follow_current_file` — el archivo activo siempre visible en el arbol

**Lo que falta o tiene problemas:**

- `undofile = true` no esta confirmado en options.lua — agrega si no esta
- No hay persistencia de sesion (`persistence.nvim`)
- `mini.ai` no esta — text objects extendidos criticos
- `flash.nvim` no esta — navegacion de pantalla eficiente
- `diffview.nvim` no esta — git diff profesional
- Keymaps de VSCode criticos sin mapear: `Ctrl+W`, `Ctrl+Shift+S`, `Ctrl+7`, `Ctrl+.`
- `fzf-lua` y `snacks_picker` coexisten — redundante, considera eliminar `fzf-lua`

---

---

## 10. Plugins instalados: referencia rapida

Esta seccion documenta los plugins activos con sus atajos principales. Solo lo que esta funcionando en la config actual.

### 10.1 kulala.nvim — HTTP Client

**Archivo:** `lua/plugins/kulala.lua`
**Carga:** lazy, solo al abrir `.http` o `.rest`
**Dependencia:** `curl` (incluido en Windows 10+)

Reemplaza la extension REST Client de VSCode con compatibilidad 1:1 de formato `.http`.

**Atajos en archivos .http:**

| Atajo        | Accion                                          |
| ------------ | ----------------------------------------------- |
| `<CR>`       | Enviar request bajo el cursor                   |
| `<leader>Rs` | Enviar request (idem)                           |
| `<leader>Ra` | Enviar todos los requests del archivo           |
| `<leader>Ro` | Abrir/enfocar panel de respuesta                |
| `<leader>Rb` | Scratch .http temporal (desde cualquier buffer) |
| `<leader>Re` | Cambiar entorno activo (dev/prod/…)             |
| `<leader>Ru` | Gestion de autenticacion (tokens, basic auth)   |
| `<leader>Rf` | Buscar request en el archivo                    |
| `<leader>Rp` | Copiar request como curl                        |
| `]]` / `[[`  | Saltar al siguiente / anterior bloque `###`     |

**En el panel de respuesta:**

| Tecla     | Vista                          |
| --------- | ------------------------------ |
| `B`       | Body (vista por defecto)       |
| `H`       | Headers                        |
| `A`       | Todo (body + headers + info)   |
| `V`       | Verbose (curl completo)        |
| `S`       | Estadisticas de timing         |
| `[` / `]` | Respuesta anterior / siguiente |
| `<CR>`    | Saltar al request de origen    |
| `?`       | Ayuda de atajos                |

**Variables en .http:**

```http
@base = https://api.ejemplo.com
@token = mi-token-secreto

### Listar usuarios
GET {{base}}/users
Authorization: Bearer {{token}}

### Crear usuario
POST {{base}}/users
Content-Type: application/json

{
  "nombre": "Juan"
}
```

Las variables `@var = valor` se definen al inicio del archivo. Las dobles llaves `{{var}}` las referencian. Compatible con archivos `.env` de VSCode REST Client si `vscode_rest_client_environmentvars = true`.

**Separador de requests:** `###` (con o sin nombre). El nombre aparece en el picker (`<leader>Rf`).

**WezTerm + kulala:**

- `Ctrl+Click` sobre URLs en el panel de respuesta las abre en el navegador (deteccion automatica de WezTerm)
- `ALT+U` desde WezTerm: QuickSelect de todas las URLs visibles en pantalla, escribe la letra del hint y se abre en el navegador. Util cuando hay multiples URLs en una respuesta JSON.

---

### 10.2 Snacks Dashboard — pantalla de inicio

**Activacion:** automatica al abrir nvim sin argumentos
**Configuracion:** `lua/plugins/ui.lua` (seccion `dashboard`)

Reemplaza el buffer en blanco que aparecia al inicio junto a neo-tree. El flujo experto:

1. Nvim abre → dashboard full screen
2. El usuario elige: `f` (buscar), `r` (recientes), `e` (explorador), o escribe directamente
3. Una vez abierto un archivo, `<leader>e` abre neo-tree y `follow_current_file` lo ubica automaticamente

**Por que este enfoque es mejor que neo-tree auto-open:**

- Sin buffer en blanco residual
- Acceso inmediato a archivos recientes (los mas usados estan a una tecla)
- Neo-tree se abre cuando se necesita, no siempre
- `follow_current_file = true` hace que neo-tree siempre muestre el archivo actual

**Atajos del dashboard:**

| Tecla | Accion                         |
| ----- | ------------------------------ |
| `f`   | Buscar archivo (fuzzy)         |
| `r`   | Archivos recientes             |
| `g`   | Buscar texto en proyecto       |
| `e`   | Abrir explorador neo-tree      |
| `L`   | Abrir Lazy (gestor de plugins) |
| `q`   | Salir de nvim                  |

---

### 10.3 Salida con confirmacion

**Configuracion:** `lua/config/keymaps.lua`

| Keymap       | Comportamiento                                                                                                                             |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `<leader>qq` | Si hay cambios sin guardar: `:qa` (confirm=true pregunta por cada uno). Si todo esta guardado: pide confirmacion explicita antes de salir. |
| `ZQ`         | Siempre pide confirmacion antes de cerrar sin guardar.                                                                                     |
| `ZZ`         | Guarda y cierra (sin cambio, comportamiento vim estandar).                                                                                 |

`vim.opt.confirm = true` ya esta activo en `options.lua`: nvim nunca pierde trabajo sin avisar.

---

_Actualizado 2026-02-21_
