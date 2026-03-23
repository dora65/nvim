-- opencode.nvim: dual-agent AI workflow dentro de Neovim
-- Rol: exploración/análisis/draft barato → Claude Code: decisiones/implementación final
-- Prerequisito (una sola vez): npm install -g opencode-ai
-- Keymaps: <leader>o* (sin conflicto con <leader>a* de Claude Code)

return {
	{
		"nickjvandyke/opencode.nvim",
		version = "*",
		dependencies = { "folke/snacks.nvim" },
		keys = {
			-- Paleta de comandos + controles (punto de entrada principal)
			{ "<leader>oo", function() require("opencode").select() end, desc = "OpenCode: paleta" },
			-- Ask con contexto del buffer activo
			{ "<leader>oa", function() require("opencode").ask() end, desc = "OpenCode: ask" },
			-- Ask sobre selección visual — complementa <leader>as de Claude
			{ "<leader>oa", function() require("opencode").ask() end, mode = "v", desc = "OpenCode: ask (selección)" },
			-- Prompts especializados de alto valor
			{ "<leader>or", function() require("opencode").prompt("diff review") end, desc = "OpenCode: diff review" },
			{ "<leader>od", function() require("opencode").prompt("fix diagnostics") end, desc = "OpenCode: fix diagnostics" },
			{ "<leader>oe", function() require("opencode").prompt("explanation") end, desc = "OpenCode: explain" },
			{ "<leader>op", function() require("opencode").prompt("optimization") end, desc = "OpenCode: optimize" },
			-- Operator: agrega rango/motion a la conversación (vim-nativo)
			{ "go", function() require("opencode").operator() end, desc = "OpenCode: add range" },
		},
		config = function()
			-- autoread: esencial para que nvim acepte los cambios de archivo que genera opencode
			vim.o.autoread = true
			vim.g.opencode_opts = {}
		end,
	},

	-- which-key: grupo <leader>o (discoverability)
	{
		"folke/which-key.nvim",
		optional = true,
		opts = {
			spec = {
				{ "<leader>o", group = "OpenCode AI", icon = { icon = "󱠇", color = "cyan" } },
				{ "<leader>oo", desc = "Paleta de comandos" },
				{ "<leader>oa", desc = "Ask con contexto" },
				{ "<leader>or", desc = "Diff review" },
				{ "<leader>od", desc = "Fix diagnostics" },
				{ "<leader>oe", desc = "Explain code" },
				{ "<leader>op", desc = "Optimize" },
			},
		},
	},
}
