-- ─── Lualine: tema Gentleman Kanagawa Blur ──────────────────────────────────
-- gentleman-kanagawa-blur NO tiene integración nativa de lualine.
-- Sin este archivo, el modo "NORMAL" aparece como texto plano sin bloque de color.
-- Este archivo aplica el tema sólo si el colorscheme activo es kanagawa/gentleman.
-- catppuccin y sonokai tienen sus propias integraciones — este archivo no interfiere.
return {
	"nvim-lualine/lualine.nvim",
	opts = function(_, opts)
		local cs = vim.g.colors_name or ""
		if not (cs:find("kanagawa") or cs:find("gentleman")) then return end

		-- Bloques de modo: identidad visual instantánea (igual que Catppuccin, Tokyo Night)
		-- NORMAL=azul  INSERT=verde  VISUAL=naranja  REPLACE=rojo  COMMAND=oro  TERMINAL=teal
		local bg      = "#161617"   -- texto sobre bloque de color (oscuro)
		local s0      = "#1C212C"   -- surface0: sección c/x (filename, extras)
		local s1      = "#232A36"   -- surface1: sección b/y (branch, filetype)
		local fg      = "#F3F6F9"   -- texto normal
		local fd      = "#8394A3"   -- fg_dim: texto secundario (contrast 5.6:1)

		local function sec(mode_bg)
			return {
				a = { fg = bg, bg = mode_bg, gui = "bold" },
				b = { fg = fg,  bg = s1 },
				c = { fg = fd,  bg = s0 },
			}
		end

		opts.options = opts.options or {}
		opts.options.theme = {
			normal   = sec("#7FB4CA"),  -- blue
			insert   = sec("#B7CC85"),  -- green
			visual   = sec("#DEBA87"),  -- orange
			replace  = sec("#CB7C94"),  -- red/pink
			command  = sec("#E0C15A"),  -- oro: único uso justificado del acento en status
			terminal = sec("#7AA89F"),  -- teal/cyan
			inactive = {
				a = { fg = fd, bg = s0 },
				b = { fg = fd, bg = s0 },
				c = { fg = fd, bg = s0 },
			},
		}
	end,
}
