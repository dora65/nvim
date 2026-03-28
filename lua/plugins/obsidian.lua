local vault = vim.fn.expand("~/Documents/Obsidian/JaedenNotes")

return {
	"epwalsh/obsidian.nvim",
	version = "*",
	dependencies = { "nvim-lua/plenary.nvim" },
	-- Solo cargar dentro del vault — evita conflictos con otros .md del sistema
	event = {
		"BufReadPre " .. vault .. "/*.md",
		"BufReadPre " .. vault .. "/**/*.md",
		"BufNewFile " .. vault .. "/*.md",
		"BufNewFile " .. vault .. "/**/*.md",
	},
	cmd = { "ObsidianSearch", "ObsidianNew", "ObsidianToday", "ObsidianQuickSwitch" },
	keys = {
		-- ── Vault: acceso rapido (funciona desde CUALQUIER buffer) ──
		{ "<leader>Ns", "<cmd>ObsidianSearch<CR>",      desc = "Vault: search" },
		{ "<leader>Nq", "<cmd>ObsidianQuickSwitch<CR>", desc = "Vault: quick switch" },
		{ "<leader>Nn", "<cmd>ObsidianNew<CR>",         desc = "Vault: new note" },
		{ "<leader>Nd", "<cmd>ObsidianToday<CR>",       desc = "Vault: today note" },
		{
			"<leader>Ni",
			function() vim.cmd("edit " .. vault .. "/index.md") end,
			desc = "Vault: open index",
		},
		{
			"<leader>Ng",
			function()
				-- Regenerar grafo desde engram.db y abrir en browser
				local script = vault .. "/engram-sync.py"
				vim.notify("Sincronizando engram -> graph...", vim.log.levels.INFO, { title = "Engram" })
				vim.fn.jobstart({
					"/c/Python313/python.exe", script, "--serve",
				}, {
					env = { PYTHONIOENCODING = "utf-8" },
					on_exit = function(_, code)
						vim.schedule(function()
							if code == 0 then
								vim.notify("Grafo neural abierto", vim.log.levels.INFO, { title = "Engram" })
							else
								vim.notify("Error generando grafo", vim.log.levels.ERROR, { title = "Engram" })
							end
						end)
					end,
				})
			end,
			desc = "Engram: neural graph (sync + browser)",
		},
		-- ── Dentro del vault (buffer-local via mappings) ──
		{ "<leader>Nb", "<cmd>ObsidianBacklinks<CR>",   desc = "Vault: backlinks" },
		{ "<leader>Nl", "<cmd>ObsidianLinks<CR>",       desc = "Vault: links" },
		{ "<leader>Nt", "<cmd>ObsidianTemplate<CR>",    desc = "Vault: template" },
		{ "<leader>Nc", "<cmd>ObsidianCheck<CR>",       desc = "Vault: toggle checkbox" },
	},
	opts = {
		workspaces = {
			{
				name = "JaedenNotes",
				path = vault,
			},
		},
		completion = {
			nvim_cmp = false,
			blink = true,
		},
		-- obsidian.nvim solo soporta telescope y fzf-lua (v3.9)
		picker = { name = "fzf-lua" },
		new_notes_location = "current_dir",
		wiki_link_func = function(opts)
			if opts.id == nil then
				return string.format("[[%s]]", opts.label)
			elseif opts.label ~= opts.id then
				return string.format("[[%s|%s]]", opts.id, opts.label)
			else
				return string.format("[[%s]]", opts.id)
			end
		end,
		mappings = {
			["gf"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true },
			},
			["<leader>Nh"] = {
				action = function()
					return require("obsidian").util.toggle_checkbox()
				end,
				opts = { buffer = true },
			},
			["<cr>"] = {
				action = function()
					return require("obsidian").util.smart_action()
				end,
				opts = { buffer = true, expr = true },
			},
		},
		templates = {
			subdir = "templates",
			date_format = "%Y-%m-%d-%a",
			time_format = "%H:%M",
		},
	},
}
