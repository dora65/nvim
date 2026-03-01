# Oracle DB + Neovim + Claude Code — Plan Definitivo

> Documento de referencia para retomar en cualquier momento.
> Ultima actualizacion: 2026-02-15

---

## Arquitectura

```
+------------------+     MCP (stdio)     +------------------+
|   Claude Code    | <------------------> |   SQLcl -mcp     |
|  (AI asistente)  |                      | (Oracle oficial) |
+------------------+                      +--------+---------+
       SOLO LECTURA                                |
                                                   |  READ-ONLY user
+------------------+                      +--------+---------+
|     Neovim       |                      |   Oracle DB      |
|  + nvim-dbee     | ------ Go driver --> |  (19c / 21c /    |
|  (visual/manual) |                      |   23ai / 26ai)   |
+------------------+                      +------------------+
       SOLO LECTURA
```

**Principio: TODA conexion usa un usuario Oracle con SOLO privilegios SELECT.**
Ni Claude Code ni nvim-dbee pueden modificar datos.

---

## SEGURIDAD — Usuario Read-Only en Oracle

### Crear usuario dedicado (ejecutar como DBA)

```sql
-- 1. Crear usuario read-only
CREATE USER readonly_dev IDENTIFIED BY "TuPasswordSeguro123!";

-- 2. Permisos minimos de conexion
GRANT CREATE SESSION TO readonly_dev;

-- 3. Lectura sobre schemas especificos (repetir por cada schema)
GRANT SELECT ANY TABLE TO readonly_dev;
-- O mas restrictivo, schema por schema:
-- GRANT SELECT ON hr.employees TO readonly_dev;
-- GRANT SELECT ON hr.departments TO readonly_dev;

-- 4. Poder ver metadata (opcional pero util)
GRANT SELECT_CATALOG_ROLE TO readonly_dev;

-- 5. VERIFICAR: NO debe tener estos privilegios
-- NUNCA: INSERT, UPDATE, DELETE, DROP, ALTER, CREATE TABLE, EXECUTE
```

### Verificar que es read-only

```sql
-- Conectar como readonly_dev y probar:
SELECT * FROM hr.employees WHERE ROWNUM <= 5;  -- OK
DELETE FROM hr.employees WHERE 1=0;            -- ORA-01031: insufficient privileges
```

---

## Estado de Implementacion

### YA CONFIGURADO (en este Neovim)

- [x] `lua/plugins/database.lua` — nvim-dbee con `<leader>D`
  - Archivo de conexiones persistente en `~/.local/share/nvim/dbee/connections.json`
  - Template auto-generado con conexion Oracle read-only
  - Lazy-loaded (no afecta startup)
- [x] `lua/plugins/colorscheme.lua` — highlights DbeeNormal/Border/Title
- [x] `lua/plugins/which-key.lua` — grupo `<leader>D` con icono BD
- [x] Java 17.0.6 detectado y funcionando

### PENDIENTE (2 pasos manuales)

- [ ] **Paso 1:** Instalar SQLcl
- [ ] **Paso 2:** Registrar MCP en Claude Code
- [ ] **Paso 3:** Crear usuario read-only en Oracle (SQL de arriba)

---

## Paso 1: Instalar SQLcl

1. Descargar: https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/
2. Extraer en `C:\app\sqlcl\`
3. PATH (PowerShell como Admin):

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\app\sqlcl\bin", "User")
```

4. JAVA_HOME (si no esta):

```powershell
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-17", "User")
```

5. Verificar (terminal nueva):

```bash
sql -V
```

---

## Paso 2: Registrar MCP en Claude Code (SOLO LECTURA)

Ejecutar en terminal **FUERA** de Claude Code:

```bash
claude mcp add --transport stdio --scope user oracle-db -- cmd /c sql -mcp
```

### Forzar read-only en el MCP

SQLcl MCP conecta con las credenciales que le des. Usar SIEMPRE el usuario `readonly_dev`:

```
readonly_dev/TuPasswordSeguro123!@host:1521/service_name
```

### Restriccion adicional con Claude Code permissions

Agregar en `.claude/settings.json` (seccion `permissions.deny`) para bloquear
operaciones destructivas incluso si Claude lo intenta:

```json
{
  "permissions": {
    "deny": [
      "mcp__oracle-db__execute(DELETE *)",
      "mcp__oracle-db__execute(DROP *)",
      "mcp__oracle-db__execute(TRUNCATE *)",
      "mcp__oracle-db__execute(ALTER *)",
      "mcp__oracle-db__execute(INSERT *)",
      "mcp__oracle-db__execute(UPDATE *)",
      "mcp__oracle-db__execute(CREATE *)",
      "mcp__oracle-db__execute(GRANT *)",
      "mcp__oracle-db__execute(REVOKE *)"
    ]
  }
}
```

> **Doble proteccion**: el usuario Oracle no tiene permisos + Claude Code tiene deny rules.

---

## Paso 3: Configurar conexion en nvim-dbee

Editar `~/.local/share/nvim/dbee/connections.json`:

```json
[
  {
    "id": "oracle-produccion",
    "name": "Oracle PROD (READ-ONLY)",
    "type": "oracle",
    "url": "oracle://readonly_dev:TuPasswordSeguro123!@192.168.1.100:1521/ORCL"
  },
  {
    "id": "oracle-desarrollo",
    "name": "Oracle DEV (READ-ONLY)",
    "type": "oracle",
    "url": "oracle://readonly_dev:TuPasswordSeguro123!@localhost:1521/XEPDB1"
  }
]
```

Luego en Neovim: `<leader>D` → seleccionar conexion → explorar.

---

## Uso Diario

### En Neovim (`<leader>D`)

- Explorar schemas, tablas, vistas, procedures
- Ejecutar SELECT manualmente
- Ver estructura de tablas
- Exportar resultados

### En Claude Code (lenguaje natural)

- "Muestra las tablas del schema HR"
- "Describe la estructura de EMPLOYEES"
- "SELECT los 10 empleados con mayor salario"
- "Explica este query: SELECT ..."
- "Genera un reporte de departamentos con conteo de empleados"
- "Compara la estructura de estas dos tablas"

---

## Capas de Seguridad (resumen)

```
Capa 1: Usuario Oracle → SOLO CREATE SESSION + SELECT
Capa 2: Claude Code deny rules → bloquea DELETE/DROP/INSERT/UPDATE/ALTER
Capa 3: nvim-dbee → conexion al mismo usuario read-only
Capa 4: SQLcl MCP → hereda permisos del usuario Oracle
```

**Resultado: imposible modificar datos desde ninguna via.**

---

## Troubleshooting

| Problema                      | Solucion                                          |
| ----------------------------- | ------------------------------------------------- |
| `sql` no encontrado           | Verificar PATH y reiniciar terminal               |
| "Connection closed" en MCP    | Usar `cmd /c sql -mcp` (wrapper Windows)          |
| Java no encontrado            | Verificar JAVA_HOME apunta a JDK 17+              |
| nvim-dbee no conecta          | Verificar URL en connections.json                 |
| ORA-01017 invalid credentials | Verificar user/password del readonly_dev          |
| ORA-12541 no listener         | Verificar host:puerto y que Oracle este corriendo |
| Password con `@`              | Encodear como `%40` en la URL                     |

---

## Archivos de este Setup

| Archivo                                     | Proposito                                |
| ------------------------------------------- | ---------------------------------------- |
| `lua/plugins/database.lua`                  | nvim-dbee config (read-only)             |
| `lua/plugins/colorscheme.lua`               | Highlights DB integrados a Catppuccin    |
| `lua/plugins/which-key.lua`                 | Grupo `<leader>D` con icono BD           |
| `~/.local/share/nvim/dbee/connections.json` | Conexiones Oracle (editar con tus datos) |
| `oracle.md`                                 | Este documento de referencia             |

---

## Links de Referencia

- [Oracle SQLcl MCP Server](https://blogs.oracle.com/database/introducing-mcp-server-for-oracle-database)
- [Documentacion SQLcl MCP](https://docs.oracle.com/en/database/oracle/sql-developer-command-line/25.2/sqcug/starting-and-managing-sqlcl-mcp-server.html)
- [oracle/mcp GitHub](https://github.com/oracle/mcp)
- [nvim-dbee](https://github.com/kndndrj/nvim-dbee)
- [Guia: Oracle MCP + Claude Code](https://llamazookeeper.medium.com/vibe-coding-003-use-oracle-mcp-server-sqlcl-with-claude-code-in-vs-code-710cb414a7c0)

![image](assets/20260219_223529.png)
