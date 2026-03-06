-- rainbow-delimiters.nvim: bracket colorizer con paleta Catppuccin Mocha
-- Gold standard 2026: TSTree-based, reemplaza todas las alternativas deprecated.
-- Los colores (RainbowDelimiter*) están pre-definidos en colorscheme.lua.

return {
  "HiPhish/rainbow-delimiters.nvim",
  config = function()
    local rainbow = require("rainbow-delimiters")
    vim.g.rainbow_delimiters = {
      strategy = {
        [""] = rainbow.strategy["global"],
      },
      query = {
        [""]  = "rainbow-delimiters",
        lua   = "rainbow-blocks",
      },
      highlight = {
        "RainbowDelimiterMauve",    -- nivel 1: mauve  — acento/identidad
        "RainbowDelimiterBlue",     -- nivel 2: blue   — funciones
        "RainbowDelimiterTeal",     -- nivel 3: teal   — propiedades/ops
        "RainbowDelimiterYellow",   -- nivel 4: yellow — tipos/clases
        "RainbowDelimiterPeach",    -- nivel 5: peach  — números/literales
        "RainbowDelimiterLavender", -- nivel 6: lavender — constantes/enum
        "RainbowDelimiterPink",     -- nivel 7: pink   — escapes/especiales
      },
    }
  end,
}
