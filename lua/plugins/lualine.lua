-- ─── Lualine: temas para variantes Kanagawa ──────────────────────────────────
-- kanagawa-paper-ink/canvas → usa el tema nativo del plugin (no custom)
-- gentleman-kanagawa-blur   → custom: texto blanco + mode bgs oscuros (WCAG AA)
-- catppuccin y sonokai tienen sus propias integraciones — este archivo no interfiere.
return {
	"nvim-lualine/lualine.nvim",
	opts = function(_, opts)
		local cs = vim.g.colors_name or ""

		-- kanagawa-paper: integración nativa — simplemente asignar el tema
		if cs:find("kanagawa%-paper") then
			opts.options = opts.options or {}
			opts.options.theme = "kanagawa-paper"
			return
		end

		-- gentleman-kanagawa-blur: custom (el plugin no tiene integración nativa)
		if not cs:find("gentleman") then return end

		-- Bloques de modo con TEXTO BLANCO — WCAG AA en todos los modos:
		--   NORMAL=ocean blue(5.5:1)  INSERT=forest green(5.6:1)
		--   VISUAL=deep amber(4.9:1)  REPLACE=deep rose(8:1)
		--   COMMAND=deep gold(5:1)    TERMINAL=deep teal(5.5:1)
		local s0   = "#282F3E"   -- surface0: sección c/x (filename, extras)
		local s1   = "#2E3748"   -- surface1: sección b/y (branch, filetype)
		local fg   = "#F3F6F9"   -- texto modo: blanco — contraste uniforme todos los modos
		local fd   = "#8394A3"   -- fg_dim: texto secundario (5.6:1)

		local function sec(mode_bg)
			return {
				a = { fg = fg, bg = mode_bg, gui = "bold" },
				b = { fg = fg,  bg = s1 },
				c = { fg = fd,  bg = s0 },
			}
		end

		opts.options = opts.options or {}
		opts.options.theme = {
			normal   = sec("#2D6585"),  -- ocean blue     — NORMAL
			insert   = sec("#3A7048"),  -- forest green   — INSERT
			visual   = sec("#8C5820"),  -- deep amber     — VISUAL/SELECT
			replace  = sec("#7A2848"),  -- deep rose      — REPLACE
			command  = sec("#7A6018"),  -- deep gold      — COMMAND
			terminal = sec("#2B7070"),  -- deep teal      — TERMINAL
			inactive = {
				a = { fg = fd, bg = s0 },
				b = { fg = fd, bg = s0 },
				c = { fg = fd, bg = s0 },
			},
		}
	end,
}
