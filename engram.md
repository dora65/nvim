# Engram Dashboard + SDD Orchestrator

Memoria persistente entre sesiones. Grafo neural interactivo. Orquestacion multi-agente.

## Iniciar Dashboard

Desde Neovim: `<leader>eg` (inicia servidor, abre browser automaticamente)

Desde terminal:
```bash
python C:/Users/51912/Documents/Obsidian/JaedenNotes/serve.py
```

Requisitos: Python 3.x instalado, engram serve activo (Claude Code MCP lo inicia automaticamente).

El servidor escucha en el primer puerto libre del rango 9470-9490 (normalmente 9470). Si ya hay una instancia corriendo (lockfile valido), abre el browser y sale. El proxy rutea `/api/*` a engram (127.0.0.1:7437), resolviendo CORS.

## Keymaps Neovim

| Tecla | Accion |
|-------|--------|
| `<leader>eg` | Dashboard engram en browser |
| `<leader>es` | Buscar en engram (terminal flotante) |
| `<leader>ec` | Contexto reciente engram (terminal flotante) |

## Dashboard

- Grafo D3.js force-directed que se estabiliza (nodos seleccionables)
- Vista docs con Markdown renderizado
- Switch grafo/docs con filtros sincronizados
- Busqueda local (debounce) + FTS5 profunda (Enter)
- Chips de filtro por tipo y proyecto
- CRUD completo de memorias (panel lateral)
- UI en espanol, iconos Nerd Font, tema Sublime/Monokai

## Orquestador SDD

Opus (default) coordina y delega. Sub-agentes usan sonnet.

| Comando | Accion |
|---------|--------|
| `/sdd-new <name>` | Explorar + proponer cambio |
| `/sdd-ff <name>` | Fast-forward: propose, spec, design, tasks |
| `/sdd-apply <name>` | Implementar |
| `/sdd-verify <name>` | Verificar |

## Archivos

| Recurso | Ruta |
|---------|------|
| Dashboard | `~/Documents/Obsidian/JaedenNotes/graph.html` |
| Proxy | `~/Documents/Obsidian/JaedenNotes/serve.py` |
| Engram DB | `~/.engram/engram.db` |
| Orquestador | `~/.claude/CLAUDE.md` |
| Proyecto | `nvim/CLAUDE.md` |
