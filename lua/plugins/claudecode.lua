-- Claude Code for Neovim (coder/claudecode.nvim)
-- Ctrl+q = toggle float (como Alt+Tab en Windows)

return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSend",
      "ClaudeCodeAdd",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeSelectModel",
    },
    keys = {
      -- Ctrl+q: toggle mostrar/ocultar (normal + terminal mode)
      { "<C-q>", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code", mode = { "n", "t" } },

      -- Acciones bajo <leader>a
      { "<leader>aa", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume session" },
      { "<leader>ac", "<cmd>ClaudeCode --continue<cr>", desc = "Continue session" },
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer to context" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
      { "<leader>ay", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff (yes)" },
      { "<leader>an", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff (no)" },
    },
    opts = {
      terminal_cmd = "claude",
      auto_start = true,
      git_repo_cwd = true,

      terminal = {
        provider = "snacks",
        auto_close = false,

        snacks_win_opts = {
          position = "float",
          width = 0.9,
          height = 0.92,
          backdrop = 50,
          border = "rounded",
          title = " 󰚩 Claude Code ",
          title_pos = "center",
          wo = {
            winblend = 0,
            winhighlight = "Normal:NormalFloat,FloatBorder:ClaudeCodeBorder,FloatTitle:ClaudeCodeTitle",
          },
          keys = {
            -- Ctrl+q dentro del float: oculta (Claude sigue vivo)
            claude_hide = {
              "<C-q>",
              function(self)
                self:hide()
              end,
              mode = "t",
              desc = "Hide Claude",
            },
          },
          -- Al perder foco → se oculta automáticamente
          on_blur = function(self)
            self:hide()
          end,
        },
      },

      diff_opts = {
        auto_close_on_accept = true,
        vertical_split = true,
        open_in_current_tab = true,
      },

      track_selection = true,
      log_level = "info",
    },

    config = function(_, opts)
      require("claudecode").setup(opts)

      -- Auto-ocultar el float de Claude Code al perder el foco
      -- nvim_win_hide: oculta la ventana SIN matar el proceso (equivalente a <C-q>)
      -- on_blur de snacks no siempre dispara con mouse → esta es la solución robusta
      vim.api.nvim_create_autocmd("WinEnter", {
        group = vim.api.nvim_create_augroup("claudecode_autohide", { clear = true }),
        callback = function()
          local cur_buf = vim.api.nvim_get_current_buf()
          -- Si entramos al propio terminal de claude, no ocultarlo
          if vim.api.nvim_buf_get_name(cur_buf):find("claude", 1, true) then return end

          local cur_win = vim.api.nvim_get_current_win()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if win ~= cur_win then
              local buf = vim.api.nvim_win_get_buf(win)
              local cfg = vim.api.nvim_win_get_config(win)
              -- Solo cerrar: floats de terminal con "claude" en el nombre del buffer
              if vim.api.nvim_buf_get_name(buf):find("claude", 1, true)
                and vim.bo[buf].buftype == "terminal"
                and cfg.relative ~= "" then
                vim.api.nvim_win_hide(win)
              end
            end
          end
        end,
      })
    end,
  },
}
