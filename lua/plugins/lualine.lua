-- ─── Lualine: temas para variantes Kanagawa + Sublime ────────────────────────
-- kanagawa-paper-ink/canvas → usa el tema nativo del plugin (no custom)
-- gentleman-kanagawa-blur   → custom: texto blanco + mode bgs oscuros (WCAG AA)
-- sublime                   → custom: sección a con bg sutil, b/c transparentes
-- catppuccin y sonokai tienen sus propias integraciones — este archivo no interfiere.
return {
	"nvim-lualine/lualine.nvim",
	opts = function(_, opts)
		local cs = vim.g.colors_name or ""

		-- sublime: modo con bg sutil en sección a, b/c transparentes
		if cs:find("sublime") then
			local bg_a = "#312f28"   -- sección a: pill warm visible (1.4:1 vs bg) — modo legible
			local fg   = "#c2c2bf"   -- editor.foreground
			local dim  = "#908c79"   -- section_c/inactive: olive cálido más legible (+lum)

			local function sec(mode_fg)
				return {
					a = { fg = mode_fg, bg = bg_a, gui = "bold" },
					b = { fg = fg,      bg = "NONE" },
					c = { fg = dim,     bg = "NONE" },
				}
			end

			opts.options = opts.options or {}
			opts.options.theme = {
				normal   = sec("#66d9ef"),
				insert   = sec("#a6e22e"),
				visual   = sec("#e6db74"),
				replace  = sec("#f92672"),
				command  = sec("#fd971f"),
				terminal = sec("#66d9ef"),
				inactive = {
					a = { fg = dim, bg = "NONE" },
					b = { fg = dim, bg = "NONE" },
					c = { fg = dim, bg = "NONE" },
				},
			}
			opts.options.section_separators   = { left = "", right = "" }
			opts.options.component_separators = { left = "│", right = "│" }
			return
		end

		-- catppuccin: integración nativa via LazyVim/lualine (no custom needed)
	end,

	-- config: parchea on_click en secciones existentes (no reemplaza) luego llama setup
	-- Busca branch/diff/diagnostics en CUALQUIER sección donde LazyVim los haya puesto
	config = function(_, opts)
		local function add_click(comps, target, handler)
			for i, comp in ipairs(comps or {}) do
				local name = type(comp) == "string" and comp
					or (type(comp) == "table" and type(comp[1]) == "string" and comp[1])
					or nil
				if name == target then
					if type(comp) == "string" then
						comps[i] = { comp, on_click = handler }
					else
						comp.on_click = comp.on_click or handler
					end
					break
				end
			end
		end

		local git_click  = function() pcall(function() require("snacks").picker.git_log() end) end
		local diag_click = function() pcall(vim.cmd, "Trouble diagnostics toggle filter.buf=0") end
		local diff_click = function() pcall(vim.cmd, "DiffviewOpen") end

		for _, section in pairs(opts.sections or {}) do
			add_click(section, "branch",      git_click)
			add_click(section, "diff",        diff_click)
			add_click(section, "diagnostics", diag_click)
		end
		require("lualine").setup(opts)
	end,
}
