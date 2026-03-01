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
      width = 28,
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
        with_expanders = true,
        expander_collapsed = "",
        expander_expanded = "",
        expander_highlight = "NeoTreeExpander",
        indent_size = 2,
        padding = 1,
      },
      name = {
        trailing_slash = false,
        use_git_status_colors = true,
        highlight_opened_files = "all",
      },
      icon = {
        folder_closed = "󰉋",
        folder_open = "󰝰",
        folder_empty = "󰉖",
        default = "󰈚",
      },
      git_status = {
        symbols = {
          added = "✚",
          modified = "",
          deleted = "✖",
          renamed = "󰁕",
          untracked = "",
          ignored = "",
          unstaged = "󰄱",
          staged = "",
          conflict = "",
        },
      },
    },
    source_selector = {
      winbar = false,
      statusline = false,
    },
    -- Iconos de carpeta por nombre — diseño profesional: dos niveles de color
    -- Filosofía VSCode Catppuccin Icons: icono único por tipo, color consistente.
    -- Solo dos highlight groups: NeoTreeGitModified (git/VCS) y NeoTreeDirectoryIcon (resto)
    components = {
      icon = function(config, node, _state)
        if node.type == "directory" then
          local pad = config.padding or " "
          -- Iconos especiales por nombre — UN solo color por categoría
          local named = {
            -- VCS / repositorios: icono VCS, misma paleta que git status
            [".git"]         = {"󰊢", "NeoTreeGitModified"},
            [".github"]      = {"󰊢", "NeoTreeGitModified"},
            [".claude"]      = {"󱙺", "NeoTreeGitModified"},
            -- Carpetas de output/deps: atenuadas
            ["node_modules"] = {"󰎙", "NeoTreeDimText"},
            ["dist"]         = {"󰦪", "NeoTreeDimText"},
            ["build"]        = {"󰚻", "NeoTreeDimText"},
            [".next"]        = {"󰦪", "NeoTreeDimText"},
            -- Todo lo demás: icono personalizado, color estándar del tema
            ["config"]    = {"󱁻", "NeoTreeDirectoryIcon"},
            ["lua"]       = {"󰢱", "NeoTreeDirectoryIcon"},
            ["plugins"]   = {"󰏓", "NeoTreeDirectoryIcon"},
            ["src"]       = {"󰴭", "NeoTreeDirectoryIcon"},
            ["lib"]       = {"󰏗", "NeoTreeDirectoryIcon"},
            ["api"]       = {"󰃤", "NeoTreeDirectoryIcon"},
            ["test"]      = {"󰙨", "NeoTreeDirectoryIcon"},
            ["tests"]     = {"󰙨", "NeoTreeDirectoryIcon"},
            ["spec"]      = {"󰙨", "NeoTreeDirectoryIcon"},
            ["docs"]      = {"󰈙", "NeoTreeDirectoryIcon"},
            ["assets"]    = {"󰥶", "NeoTreeDirectoryIcon"},
            ["public"]    = {"󰉀", "NeoTreeDirectoryIcon"},
            ["spell"]     = {"󰓆", "NeoTreeDirectoryIcon"},
            ["components"]= {"󱒊", "NeoTreeDirectoryIcon"},
            ["utils"]     = {"󱆀", "NeoTreeDirectoryIcon"},
            ["types"]     = {"󰿘", "NeoTreeDirectoryIcon"},
            ["models"]    = {"󰆼", "NeoTreeDirectoryIcon"},
            ["services"]  = {"󰃤", "NeoTreeDirectoryIcon"},
            ["scripts"]   = {"󱆀", "NeoTreeDirectoryIcon"},
            ["gentleman"] = {"󱌯", "NeoTreeDirectoryIcon"},
          }
          local custom = named[node.name] or named[node.name:lower()]
          if custom then
            return { text = custom[1] .. pad, highlight = custom[2] }
          end
          -- Carpeta genérica: abierta / cerrada / vacía
          local icon = node:is_expanded() and (config.folder_open or "󰝰")
                    or node:has_children()  and (config.folder_closed or "󰉋")
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
    },
  },
}
