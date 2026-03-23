return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  -- init: abrir neo-tree como sidebar al iniciar sin argumentos
  -- UiEnter es mas confiable que VimEnter: VimEnter dispara antes de que la UI
  -- este lista (fallos intermitentes). Fuente: LazyVim Discussion #3139.
  -- action="show" abre el panel sin mover el foco (cursor queda en main window).
  -- hijack_netrw="disabled": evita triple panel con snacks.explorer del extra snacks_picker.
  init = function()
    -- Fix: signcolumn="yes:2" global bleeding into neo-tree panel (muestra "2" en cada fila)
    -- NeoTree no usa diagnostics/gitsigns en su panel → signcolumn debe ser "no"
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "neo-tree",
      callback = function()
        vim.opt_local.signcolumn   = "no"
        vim.opt_local.foldcolumn   = "0"
        vim.opt_local.number       = false
        vim.opt_local.relativenumber = false
      end,
    })
    vim.api.nvim_create_autocmd("UiEnter", {
      group = vim.api.nvim_create_augroup("NeotreeStartup", { clear = true }),
      once = true,
      callback = function()
        if vim.fn.argc() == 0 then
          require("neo-tree.command").execute({
            action = "show",
            dir = vim.uv.cwd(),
            source = "filesystem",
          })
        end
      end,
    })
  end,
  keys = {
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
      end,
      desc = "Explorer NeoTree (root dir)",
    },
    {
      "<leader>E",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = vim.fn.expand("%:p:h") })
      end,
      desc = "Explorer NeoTree (cwd)",
    },
    { "<leader>fe", "<cmd>Neotree toggle reveal<cr>", desc = "Explorer NeoTree (toggle)" },
  },
  opts = {
    close_if_last_window = true,
    popup_border_style = "single",
    enable_opened_markers = true,
    open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline", "toggleterm" },
    -- Refrescar git status cuando cambia (timing fix: árbol abre antes que git termine)
    event_handlers = {
      {
        event = "neo_tree_git_status_changed",
        handler = function()
          -- Re-renderizar para que el custom component tome los datos actualizados
          local ok, manager = pcall(require, "neo-tree.sources.manager")
          if ok then manager.refresh("filesystem") end
        end,
      },
    },
    filesystem = {
      follow_current_file = { enabled = true, leave_dirs_open = false },
      hijack_netrw_behavior = "open_default",
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_hidden = false,
      },
    },
    window = {
      width = 26,
      position = "left",
      popup_border_style = "single",
      mappings = {
        ["<space>"] = "none",
        ["h"] = function(state)
          local node = state.tree:get_node()
          if node.type == "directory" and node:is_expanded() then
            require("neo-tree.sources.filesystem").toggle_directory(state, node)
          else
            require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
          end
        end,
        ["l"] = function(state)
          local node = state.tree:get_node()
          if node.type == "directory" then
            if not node:is_expanded() then
              require("neo-tree.sources.filesystem").toggle_directory(state, node)
            elseif node:has_children() then
              require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
            end
          else
            state.commands["open"](state)
          end
        end,
        ["H"] = "toggle_hidden",
        ["Y"] = function(state)
          local node = state.tree:get_node()
          local path = node:get_id()
          vim.fn.setreg("+", path)
          vim.notify(path, vim.log.levels.INFO, { title = "Path copied" })
        end,
        ["A"] = function(state)
          local node = state.tree:get_node()
          if node.type == "file" then
            vim.cmd("ClaudeCodeTreeAdd")
            vim.notify("  Added to Claude: " .. node.name, vim.log.levels.INFO)
          end
        end,
      },
    },
    default_component_configs = {
      indent = {
        indent_size = 1,
        padding = 0,
        with_markers = true,      -- guías verticales de indentación
        indent_marker = "│",      -- guía continua — mismo estilo que mini.indentscope
        last_indent_marker = "╰", -- último hijo del bloque (más premium que └)
        highlight = "NeoTreeIndentMarker",
        with_expanders = true,
        expander_collapsed = "",
        expander_expanded = "",
        expander_highlight = "NeoTreeExpander",
      },
      name = {
        trailing_slash = false,
        use_git_status_colors = true,
        highlight_opened_files = "all",
      },
      icon = {
        folder_closed = "󰉖", -- md-folder_outline (outline style)
        folder_open = "󰷏",   -- md-folder_open_outline
        folder_empty = "󰉖",
        default = "󰈚",
      },
      git_status = {
        symbols = {
          added     = "A",
          modified  = "M",
          deleted   = "D",
          renamed   = "R",
          untracked = "U",
          ignored   = "●",
          unstaged  = "",
          staged    = "✓",
          conflict  = "!",
        },
      },
    },
    source_selector = { winbar = false, statusline = false },
    components = {
      icon = function(config, node, _state)
        if node.type == "directory" then
          local pad = config.padding or " "
          local named = {
            [".git"]         = {"󰊢", "NeoTreeGitModified"},
            [".github"]      = {"󰊢", "NeoTreeGitModified"},
            ["node_modules"] = {"󰎙", "NeoTreeDimText"},
            ["dist"]         = {"󰦪", "NeoTreeDimText"},
            ["build"]        = {"󰚻", "NeoTreeDimText"},
            [".next"]        = {"󰦪", "NeoTreeDimText"},
            ["assets"]       = {"󰉏", "MiniIconsOrange"}, -- Folder image outline orange
          }
          local custom = named[node.name] or named[node.name:lower()]
          if custom then return { text = custom[1] .. pad, highlight = custom[2] } end

          local icon = node:is_expanded() and (config.folder_open or "󰷏")
                    or node:has_children()  and (config.folder_closed or "󰉖")
                    or (config.folder_empty or "󰉖")
          return { text = icon .. pad, highlight = "NeoTreeDirectoryIcon" }
        end
        -- Archivos: mini.icons (LazyVim default) con fallback a nvim-web-devicons
        local ok_mi, mini_icons = pcall(require, "mini.icons")
        if ok_mi then
          local icon, hl, _is_default = mini_icons.get("file", node.name)
          if icon then
            return { text = icon .. (config.padding or " "), highlight = hl }
          end
        end
        local ok_dev, devicons = pcall(require, "nvim-web-devicons")
        if ok_dev then
          local ext = node.ext or vim.fn.fnamemodify(node.name, ":e")
          local icon, hl = devicons.get_icon(node.name, ext, { default = true })
          if icon then
            return { text = icon .. (config.padding or " "), highlight = hl }
          end
        end
        return { text = (config.default or "󰈚") .. (config.padding or " "), highlight = "NeoTreeFileIcon" }
      end,

      -- git_status custom: dirs=dot ●, files=letters (M/U/A/D/R/!/✓) — VS Code style
      -- Ref: VS Code Catppuccin Icons: modified=M, untracked=U, added=A, conflict=!
      -- Ref: monokai.jsonc gitDecoration.* colors (aplicados en sublime_overrides)
      -- FIX Windows: state.git_status_lookup usa forward-slash pero node:get_id() usa backslash
      -- → normalizar ambos a forward-slash para garantizar match en Windows
      git_status = function(config, node, state)
        local lookup = state.git_status_lookup
        if not lookup then return {} end

        -- Windows path normalization: backslash → forward-slash, sin trailing sep
        local function normalize(p)
          return p:gsub("\\", "/"):gsub("/$", "")
        end

        local id = node:get_id()
        local status = lookup[id]
        -- Fallback: intentar con path normalizado (fix Windows backslash mismatch)
        if not status then
          status = lookup[normalize(id)]
        end
        if not status or status == "" then return {} end

        local pad = config.padding or " "
        local sym, hl

        -- DIRECTORIOS: punto de color ● (propagado desde hijos con git changes)
        -- Ref imagen #2: círculos de color según tipo de cambio (U=verde, M=amber)
        if node.type == "directory" then
          if status:match("[UA][UA]") or status:match("^U") then
            hl = "NeoTreeGitConflict"
          elseif status:match("%?") then
            hl = "NeoTreeGitUntracked"   -- verde: contiene archivos nuevos sin rastrear
          elseif status:match("A") then
            hl = "NeoTreeGitAdded"        -- verde claro: nuevo contenido staged
          elseif status:match("M") or status:match("R") or status:match("D") then
            hl = "NeoTreeGitModified"     -- amber: modificado
          else
            hl = "NeoTreeGitModified"
          end
          return { text = pad .. "●", highlight = hl }
        end

        -- ARCHIVOS: letras VS Code (ignorados = sin indicador, ya están dim)
        if status == "!!" then return {} end
        if status:match("%?%?") then
          sym, hl = "U", "NeoTreeGitUntracked"   -- nuevo/no rastreado = U (VS Code)
        elseif status:match("[UA][UA]") then
          sym, hl = "!", "NeoTreeGitConflict"
        elseif status == "A " or status == "AM" then
          sym, hl = "A", "NeoTreeGitAdded"
        elseif status:match("^R") then
          sym, hl = "R", "NeoTreeGitRenamed"
        elseif status:match("^D") or status:match("%sD$") then
          sym, hl = "D", "NeoTreeGitDeleted"
        elseif status:match("M") then
          sym, hl = "M", "NeoTreeGitModified"
        else
          sym, hl = "✓", "NeoTreeGitStaged"
        end

        return { text = pad .. sym, highlight = hl }
      end,
    },
  },
}
