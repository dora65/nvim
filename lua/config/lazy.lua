-- LazyVim configuration optimized for Windows 11 (2025 standards)

-- Spell-checking
vim.opt.spell = false -- Desactivado para evitar molestias con subrayados
vim.opt.spelllang = { "en" }

-- Define the path to the lazy.nvim plugin
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Check if the lazy.nvim plugin is not already installed
if not vim.loop.fs_stat(lazypath) then
  -- Bootstrap lazy.nvim by cloning the repository
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end

-- Prepend the lazy.nvim path to the runtime path
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

-- Priority: Windows configuration first (most likely platform)
if vim.fn.has("win32") == 1 then
  -- Clipboard configuration for Windows + WezTerm
  vim.opt.clipboard = 'unnamed,unnamedplus'
  
  -- Use PowerShell Core for better performance and UTF-8 support
  if vim.fn.executable('pwsh.exe') == 1 then
    vim.opt.shell = 'pwsh.exe'
    vim.opt.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
    vim.opt.shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
    vim.opt.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
    vim.opt.shellquote = ""
    vim.opt.shellxquote = ""
    vim.opt.shelltemp = true
  end

  -- Path configuration for Windows
  vim.opt.shellslash = true  -- Use forward slashes in file paths
  
  -- Temp directory optimization (prevents temp file issues on Windows)
  local temp_dir = os.getenv("TEMP")
  if temp_dir then
    -- Set undo directory to Windows temp
    local undodir = temp_dir .. '/nvim-undo'
    vim.opt.undodir = undodir
    
    -- Create undo directory if it doesn't exist
    if vim.fn.isdirectory(undodir) == 0 then
      vim.fn.mkdir(undodir, 'p')
    end
    
    -- Optimize swap and backup locations
    vim.opt.directory = temp_dir .. '/nvim-swap//'
    vim.opt.backupdir = temp_dir .. '/nvim-backup//'
    
    -- Create directories if they don't exist
    for _, dir in pairs({temp_dir .. '/nvim-swap/', temp_dir .. '/nvim-backup/'}) do
      if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, 'p')
      end
    end
  end
  
  -- Windows explorer integration
  vim.g.netrw_browsex_viewer = 'explorer'
  
  -- Node.js configuration for Mason and LSP (crucial for auto-language detection)
  local function find_node_executable()
    local possible_paths = {
      vim.fn.expand("$APPDATA\\Roaming\\nvm\\v22.11.0\\node.exe"),
      vim.fn.expand("$APPDATA\\Roaming\\nvm\\current\\node.exe"),
      "C:\\Program Files\\nodejs\\node.exe",
      "C:\\nodejs\\node.exe"
    }
    
    for _, path in ipairs(possible_paths) do
      if vim.fn.filereadable(path) == 1 then
        return path
      end
    end
    return nil
  end
  
  local node_exec = find_node_executable()
  if node_exec then
    -- Tell Mason where to find Node.js
    vim.g.mason_nodejs_executable = node_exec
    
    -- For plugins requiring node path
    local node_path = vim.fn.fnamemodify(node_exec, ":h")
    vim.env.PATH = node_path .. ";" .. vim.env.PATH
  end
  
  -- Windows GUI specific settings
  if vim.fn.has('gui_running') == 1 then
    vim.opt.renderoptions = "type:directx"
    vim.opt.linespace = 0
  end
  
  -- Improve terminal rendering in WezTerm
  vim.opt.termguicolors = true
  
  -- Windows console title
  vim.opt.title = true
  vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')} - Neovim"

-- WSL configuration (kept as fallback)
elseif vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "win32yank",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = false,
  }
end

-- Setup lazy.nvim with the specified configuration
require("lazy").setup({
  spec = {
    -- Add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    
    -- Editor plugins - highly rated for Windows
    { import = "lazyvim.plugins.extras.editor.harpoon2" },
    { import = "lazyvim.plugins.extras.editor.mini-files" },
    { import = "lazyvim.plugins.extras.editor.snacks_picker" },
    { import = "lazyvim.plugins.extras.editor.mini-diff" },

    -- Formatting plugins - excellent Windows compatibility
    { import = "lazyvim.plugins.extras.formatting.biome" },
    { import = "lazyvim.plugins.extras.formatting.prettier" },

    -- Linting plugins
    { import = "lazyvim.plugins.extras.linting.eslint" },

    -- Coding plugins
    { import = "lazyvim.plugins.extras.coding.mini-surround" },

    -- Utility plugins
    { import = "lazyvim.plugins.extras.util.mini-hipatterns" },

    -- Lang: Web Dev stack (TypeScript, Tailwind, JSON)
    -- lang.markdown está excluido: lo manejamos en lua/plugins/markdown.lua
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.tailwind" },
    { import = "lazyvim.plugins.extras.lang.json" },

    -- Import/override with your custom plugins
    { import = "plugins" },
  },
  defaults = {
    -- lazy=true: plugins cargan bajo demanda (correcto con LazyVim)
    lazy = true,
    version = false,
  },
  install = { colorscheme = { "catppuccin", "gentleman-kanagawa-blur", "habamax" } },
  ui = { border = "rounded" }, -- Bordes redondeados premium para lazy.nvim UI
  checker = { enabled = true }, -- Verificar actualizaciones automáticamente
  performance = {
    rtp = {
      -- Desactivar plugins innecesarios para mejor rendimiento en Windows
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})