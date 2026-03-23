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
			-- Ctrl+q: OCULTAR/MOSTRAR — nvim_win_hide() garantiza que Claude NUNCA se termina
			-- • Si el float está visible → lo oculta (proceso Claude sigue corriendo en bg)
			-- • Si no está visible       → lo muestra o lo inicia
			-- • Modo solo "n": el float maneja <C-q> en terminal mode con self:hide() (ver abajo)
			--   Así evitamos que <C-q> en OTRA terminal (modo t) dispare ClaudeCode por error.
			{
				"<C-q>",
				function()
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						local buf = vim.api.nvim_win_get_buf(win)
						local cfg = vim.api.nvim_win_get_config(win)
						if
							vim.api.nvim_buf_get_name(buf):find("claude", 1, true)
							and vim.bo[buf].buftype == "terminal"
							and cfg.relative ~= ""
						then
							vim.api.nvim_win_hide(win) -- oculta la ventana, NO mata el proceso
							return
						end
					end
					vim.cmd("ClaudeCode") -- no está visible → mostrar o iniciar sesión
				end,
				desc = "Claude: hide/show (never terminate)",
				mode = "n",
			},

			-- Acciones bajo <leader>a
			{ "<leader>aa", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
			{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume session" },
			{ "<leader>ac", "<cmd>ClaudeCode --continue<cr>", desc = "Continue session" },
			{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select model" },
			{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer to context" },
			{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection" },
			{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude Code" },
			{ "<leader>at", "<cmd>ClaudeCodeTreeAdd<cr>", desc = "Add tree file to context" },
			{ "<leader>ay", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff (yes)" },
			{ "<leader>an", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff (no)" },
			-- Diagnósticos del buffer activo → clipboard para pegar en Claude
			-- Complementa ClaudeCodeAdd: da contexto de ERRORES sin adjuntar el archivo completo
			{ "<leader>ad", function()
				local diags = vim.diagnostic.get(0)
				if #diags == 0 then
					vim.notify("Sin diagnósticos", vim.log.levels.INFO, { title = "Claude AI" })
					return
				end
				local sev = { "ERROR", "WARN", "INFO", "HINT" }
				local lines = vim.tbl_map(function(d)
					return string.format("L%d: [%s] %s", d.lnum + 1, sev[d.severity] or "?", d.message)
				end, diags)
				vim.fn.setreg("+", table.concat(lines, "\n"))
				vim.notify(#diags .. " diagnóstico(s) → clipboard", vim.log.levels.INFO, { title = "Claude AI" })
			end, desc = "Copy diagnostics to clipboard" },
		},
		opts = {
			terminal_cmd = "claude",
			auto_start = true,
			git_repo_cwd = true,

			terminal = {
				provider = "snacks",
				-- auto_close=true: si Claude sale con /exit el float se cierra solo
				-- con hide() el proceso sigue vivo; solo se cierra cuando el proceso termina
				auto_close = true,

				snacks_win_opts = {
					position = "float",
					width = 0.9,
					height = 0.92,
					backdrop = 65,
					border = "rounded",
					wo = {
						-- winblend omitido: mini.animate lo gestiona (open: 80→0, close: 0→80)
						winhighlight = "Normal:NormalFloat,FloatBorder:ClaudeCodeBorder",
						wrap = false,
						sidescrolloff = 5,
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
					-- on_blur: oculta Claude al perder el foco (click o split a otro panel).
					-- self:hide() = nvim_win_hide → proceso Claude NUNCA se termina.
					-- Re-mostrar con <C-q> o <leader>aa desde cualquier ventana.
					on_blur = function(self)
						self:hide()
					end,
				},
			},

			diff_opts = {
				auto_close_on_accept = true,  -- cierra diff al aceptar (flujo limpio)
				vertical_split = true,        -- diff lado a lado (más legible)
				open_in_current_tab = true,   -- en tab actual, no nueva
				show_diff_stats = true,       -- muestra +N/-N en el header del diff
			},

			-- track_selection: contexto visual en tiempo real enviado a Claude
			-- visual_demotion_delay_ms: tiempo antes de degradar selección (50ms = default)
			-- focus_after_send: false = cursor permanece en editor al enviar selección
			track_selection = true,
			visual_demotion_delay_ms = 50,
			focus_after_send = false,

			log_level = "warn",       -- warn (vs info) = sin ruido por cada operación menor

			-- MCP Servers: extienden las capacidades de Claude con herramientas reales.
			-- GitHub MCP: se activa solo si GITHUB_TOKEN esta en el entorno shell.
			-- Setup (una sola vez en PowerShell profile):
			--   $env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxx"
			-- Permisos minimos del token: repo, issues, pull_requests
			-- GitHub MCP: activo si GITHUB_TOKEN_NVIM esta en el entorno (Windows user env).
			-- Setup: [System.Environment]::SetEnvironmentVariable("GITHUB_TOKEN_NVIM","ghp_...","User")
			mcps = (vim.env.GITHUB_TOKEN_NVIM ~= nil and vim.env.GITHUB_TOKEN_NVIM ~= "") and {
				{
					name = "github",
					command = "npx",
					args = { "-y", "@modelcontextprotocol/server-github" },
					env = { GITHUB_PERSONAL_ACCESS_TOKEN = vim.env.GITHUB_TOKEN_NVIM },
				},
			} or {},
		},

		config = function(_, opts)
			require("claudecode").setup(opts)
			-- Notifica cuando Claude se cierra con /exit (auto_close=true ya cierra el float)
			vim.api.nvim_create_autocmd("TermClose", {
				pattern = "term://*claude*",
				callback = function()
					vim.schedule(function()
						vim.notify("Claude Code session ended", vim.log.levels.INFO, { title = "Claude AI" })
					end)
				end,
			})
			end,
	},
	-- which-key: registrar grupo <leader>a para Claude Code (discoverability)
	{
		"folke/which-key.nvim",
		optional = true,
		opts = {
			spec = {
				{ "<leader>a", group = "Claude AI", icon = { icon = "󰚩", color = "yellow" } },
				{ "<leader>aa", desc = "Toggle panel" },
				{ "<leader>ar", desc = "Resume session" },
				{ "<leader>ac", desc = "Continue session" },
				{ "<leader>am", desc = "Select model" },
				{ "<leader>ab", desc = "Add buffer to context" },
				{ "<leader>as", desc = "Send selection", mode = "v" },
				{ "<leader>af", desc = "Focus panel" },
				{ "<leader>at", desc = "Add tree file to context" },
				{ "<leader>ay", desc = "Accept diff (yes)" },
				{ "<leader>an", desc = "Deny diff (no)" },
				{ "<leader>ad", desc = "Copy diagnostics" },
			},
		},
	},
}
