# Neovim + WezTerm: Atajos de Teclado (Nivel Experto)

Esta guía condensa el flujo de trabajo dinámico definitivo, eliminando la dependencia del ratón y maximizando la velocidad de desarrollo en C# (.NET Core).

## 1. Comandos que Valen Oro (Navegación Dinámica C#)

| Atajo Neovim | Acción (Equivalente VSCode / Antigravity) |
|---|---|
| `gd` | **Go to Definition:** Ir a la interfaz o declaración de la variable. |
| `gI` | **Go to Implementation:** Ir al código real (ej. del IRepository al Repository). |
| `gO` | **Symbols Outline:** Ver/Filtrar todas las funciones del archivo actual (Ctrl+Shift+O). |
| `gr` | **Find All References:** Ver en qué otros archivos se usa este método/clase (Shift+F12). |
| `K` | **Hover Docs:** Ver los tipos de parámetros y documentación en un popup flotante. |
| `gpd` | **Preview Definition:** Ver la definición en una ventana flotante sin salir de tu archivo actual. |
| `Ctrl + Shift + -` | **Viajar Atrás:** Regresar exactamente a donde estabas antes del salto. |
| `Ctrl + Shift + +` | **Viajar Adelante:** Rehacer el salto. |

## 2. Buscadores Veloces (Telescope / Snacks)

| Atajo Neovim | Acción |
|---|---|
| `<Space> <Space>` | **Quick Open:** Buscador global de archivos ultra-rápido (Ctrl+P). |
| `<Space> /` | **Live Grep:** Buscar texto/código en todos los archivos del proyecto (Ctrl+Shift+F). |
| `Ctrl + f` | Buscar texto dentro del archivo actual (Ctrl+F). |
| `<leader>sr` | **Grug FAR:** Buscar y Reemplazar avanzado en todo el proyecto. |
| `<leader>e` | Abrir/Cerrar Explorador de Archivos Lateral (Neo-tree). |
| `-` | Abrir Explorador de Archivos Flotante (Mini.files - Navegación con teclado). |

## 3. Manejo de Buffers (Pestañas) y Splits

| Atajo Neovim | Acción |
|---|---|
| `Ctrl + Tab` | Cambiar entre archivos abiertos (Picker visual por uso reciente). |
| `Alt + Right` / `Left` | Cambiar al archivo abierto Siguiente / Anterior. |
| `<leader>bq` | Cerrar todos los archivos excepto el que estás viendo. |
| `Ctrl + Shift + \` | Dividir la pantalla a la derecha (Split Vertical). |
| `Ctrl + Alt + Flechas`| Navegar ágilmente entre las pantallas divididas. |

## 4. Edición Ágil y Refactorización

| Atajo Neovim | Acción |
|---|---|
| `Ctrl + s` | Guardar archivo. |
| `Ctrl + c` / `x` / `v` | Copiar, Cortar, Pegar directamente al portapapeles de Windows. |
| `Ctrl + a` | Seleccionar todo el texto del archivo. |
| `Shift + Flechas` | Seleccionar texto libremente como en cualquier editor moderno. |
| `Ctrl + d` / `Ctrl + u`| Moverse rápido: Scroll de media página hacia abajo/arriba centrando la vista. |
| `<leader>cr` | **Rename Symbol:** Cambiar el nombre de una variable/método en todo el proyecto (F2). |
| `<leader>ca` | **Code Action:** Aplicar sugerencias o arreglos automáticos del LSP (Ctrl+.). |

## 5. WezTerm y Ambiente de Terminal

| Atajo WezTerm | Acción |
|---|---|
| `Alt + Enter` | Pantalla Completa absoluta (Oculta la barra de tareas de Windows). |
| `Alt + U` | **QuickSelect URL:** Resalta todas las URLs de la terminal y permite abrirlas presionando una letra, cero clicks. |
| `Alt + t` / `Alt + w` | Abrir nueva pestaña de terminal pura / Cerrar pestaña de terminal. |

## 6. Siguientes Pasos (Gaps de VSCode por integrar)
*(Podemos mapear estos atajos personalizados más adelante si lo deseas para reemplazar por completo tu memoria muscular)*:
*   `Ctrl + W` (Cerrar archivo actual).
*   `Ctrl + Shift + S` (Guardar todo).
*   `Ctrl + 7` (Comentar/Descomentar línea).
*   `Alt + F` (Modo Zen inmersivo de Neovim).
