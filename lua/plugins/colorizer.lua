-- ─── nvim-colorizer — Preview inline de colores #hex ─────────────────────────
-- Renders #RRGGBB, #RGB, #RRGGBBAA como swatch de fondo detrás del texto.
-- Essential para desarrollo de temas/colorschemes: ves el color sin salir del archivo.
-- Activa automáticamente en todos los buffers excepto paneles especiales.
-- Soporte extendido en CSS/SCSS: rgb(), hsl(), color names.
return {
	{
		"NvChad/nvim-colorizer.lua",
		event = "BufReadPre",
		opts = {
			filetypes = {
				-- Todos los tipos de archivo
				"*",
				-- Excluir paneles y terminales (no tienen colores hex)
				"!toggleterm",
				"!neo-tree",
				"!lazy",
				"!mason",
				-- CSS/SCSS: habilitar soporte extra (rgb(), hsl(), named colors)
				css  = { css = true, css_fn = true },
				scss = { css = true, css_fn = true },
				html = { css = true },
			},
			user_default_options = {
				RGB      = true,    -- #RGB → swatch
				RRGGBB   = true,    -- #RRGGBB → swatch (el más común en nvim config)
				RRGGBBAA = true,    -- #RRGGBBAA → swatch (catppuccin alpha colors)
				names    = false,   -- "red"/"blue" etc = demasiado ruido en código normal
				rgb_fn   = false,   -- rgb() — solo en CSS (habilitado por filetype)
				hsl_fn   = false,   -- hsl() — solo en CSS
				-- mode: "background" = swatch detrás del texto (más legible que "foreground")
				-- Alternativa: "virtualtext" con symbol="■" para no alterar el texto
				mode     = "background",
				always_update = false,  -- solo actualizar en TextChanged (no en CursorMoved)
			},
		},
	},
}
