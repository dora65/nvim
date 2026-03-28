return {
	-- ─── Catppuccin Mocha — tema premium unificado con Windows Terminal ─────────
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		opts = {
			flavour = "mocha",
			transparent_background = true,
			term_colors = true,
			show_end_of_buffer = false,
			no_italic = false,
			no_bold = false,
			no_underline = false,      -- underlines: URLs, LSP refs, deprecated
			no_strikethrough = false,  -- strikethrough: deprecated symbols (@lsp.typemod.*.deprecated)

			-- Dim inactivo: 30% para compensar que NormalNC bg=mantle ya da distinción
			-- NormalNC override abajo hace el trabajo principal; dim_inactive refuerza fg
			dim_inactive = {
				enabled = true,
				shade = "dark",
				percentage = 0.30,
			},

			-- Puente Térmico Neutro (Oro Puro):
			-- Catppuccin Mocha tiene un base frío (azul/violeta). Sublime tiene un base cálido (oliva oscuro).
			-- Al flotar un menú Catppuccin sobre Sublime, el choque térmico (frío sobre cálido) crea
			-- disonancia visual agotadora o color "sucio" (muddy).
			-- Solución: Matemáticamente derivamos superficies grises ACROMÁTICAS (neutras perfectas) 
			-- para que el cromo de la UI sea un marco limpio que no compite con el código cálido.
			-- crust/mantle/surfacex actúan ahora como cristal polarizado neutro (#1a1a1c).
			color_overrides = {
				mocha = {
					crust    = "#111112",
					mantle   = "#1a1a1c",
					surface0 = "#242523",
					surface1 = "#343532",
					surface2 = "#444541",
				},
			},

			styles = {
				comments    = { "italic" },
				conditionals= { "italic" },
				functions   = { "bold" },
				keywords    = { "italic" },
				strings     = {},
				variables   = {},
			},

			-- Highlight overrides: Gentleman-inspired — full transparency stack
			highlight_overrides = {
				mocha = function(colors)
					local t = "NONE"
					return {
						-- ── Separadores: línea sutil, fondo transparente ────────────────
						WinSeparator = { fg = colors.surface1, bg = t },
						VertSplit = { fg = colors.surface1, bg = t },

						-- ── Fondos: full transparency — el terminal brilla a través ─────
						Normal = { bg = t },
						NormalNC = { bg = colors.mantle, fg = colors.overlay0 },
						NormalFloat = { bg = colors.mantle, fg = colors.text },
						FloatBorder = { fg = colors.surface2, bg = colors.mantle }, -- Border invisible en winblend
						FloatTitle = { fg = colors.mauve, bg = colors.mantle, bold = true },

						-- ── Corrección de Consistencia: Someter Plugins a Mantle (#1a1a1c) ─
						-- Éstos plugins ignoran NormalFloat y usan sus propios fondos (rompiendo el Fit).
						-- Snacks (FZF/Picker):
						SnacksPickerNormal = { bg = colors.mantle, fg = colors.text },
						SnacksPickerBorder = { fg = colors.surface2, bg = colors.mantle },
						SnacksPickerTitle  = { fg = colors.mauve, bg = colors.mantle, bold = true },
						-- Noice (Cmdline/Popups):
						NoiceCmdlinePopup       = { bg = colors.mantle, fg = colors.text },
						NoiceCmdlinePopupBorder = { fg = colors.surface2, bg = colors.mantle },
						NoiceCmdlinePopupTitle  = { fg = colors.mauve, bg = colors.mantle, bold = true },
						NoiceMini               = { bg = colors.mantle },
						-- Lazygit / Mason / Lazy:
						LazyNormal  = { bg = colors.mantle },
						MasonNormal = { bg = colors.mantle },
						TelescopeNormal = { bg = colors.mantle },
						TelescopeBorder = { fg = colors.surface2, bg = colors.mantle },

						-- ── Cursor line: sutil sobre transparencia ──────────────────────
						CursorLine   = { bg = "#2d2e2a" },   -- warm Sublime +4% L*
						CursorLineNr = { fg = colors.lavender, bold = true },
						-- overlay0 (#6c7086) = 4.1:1 contraste vs crust: legible sin competir con código
						-- surface1 (#45475a) = ~2.5:1 → insuficiente (principio fg_dim de Kanagawa)
						LineNr = { fg = colors.overlay0 },

						-- ── Popups y menús: semi-transparente, elegante ─────────────────
						Pmenu = { bg = colors.mantle, fg = colors.text },
						PmenuSel = { bg = "#3a2d52", fg = colors.text, bold = true },  -- mauve-tinted (Kanagawa accent principle)
						PmenuThumb = { bg = colors.surface1 },

						-- ── Neo-tree: Principios Kanagawa (Luminance Hierarchy) ─────────────────
						-- Kanagawa: bg oscuro, hover=surface1 (nota: en transparent mode bg=NONE)
						-- Principio: el item activo/hoveredsiempre tiene acento LUMINOSO y VISIBLE
						NeoTreeNormal = { bg = t, fg = colors.text },
						NeoTreeNormalNC = { bg = t, fg = colors.subtext0 },
						NeoTreeWinSeparator = { fg = colors.mantle, bg = t },
						NeoTreeEndOfBuffer = { bg = t, fg = t },
						-- Hover/cursor: surface0 exactamente (Kanagawa rosewater no sirve; surface0 subtle = 4.2:1)
						-- ANTES: overlay0 era demasiado claro para un bg transparent → parecia un borde
						NeoTreeCursorLine = { bg = colors.surface0, bold = false },
						NeoTreeDimText = { fg = colors.overlay0 },
						NeoTreeIndentMarker = { fg = colors.surface1 },
						NeoTreeGitAdded = { fg = colors.green },
						NeoTreeGitModified = { fg = colors.yellow },
						NeoTreeGitDeleted = { fg = colors.red },
						NeoTreeGitUntracked = { fg = colors.teal },
						NeoTreeDirectoryIcon = { fg = colors.lavender },
						NeoTreeDirectoryName = { fg = colors.lavender },
						NeoTreeRootName = { fg = colors.mauve, bold = true, italic = true },
						NeoTreeFileName = { fg = colors.text },
						-- Archivo activo ABIERTO: brilla en amarillo cálido Sublime (como VSCode)
						-- Principio Kanagawa: el item activo usa el accent más brillante disponible
						-- #e6db74 = yellow Sublime ST3 — warm, distinguible pero no agresivo
						NeoTreeFileNameOpened = { fg = "#e6db74", bold = true },
						-- Highlights faltantes (usados en git_status component de neo-tree.lua)
						NeoTreeGitStaged   = { fg = colors.green,  bold = true },
						NeoTreeGitConflict = { fg = colors.red,    bold = true },
						NeoTreeGitRenamed  = { fg = colors.yellow },
						-- DropBar: menú dropdown integrado con paleta Catppuccin
						DropBarIconUISeparator    = { fg = colors.overlay0 },
						DropBarMenuNormalFloat    = { bg = colors.mantle,   fg = colors.text },
						DropBarMenuFloatBorder    = { fg = colors.surface2, bg = colors.mantle },
						DropBarMenuHoverEntry     = { bg = "#3a2d52",       fg = colors.text, bold = true },
						DropBarMenuCurrentContext = { bg = colors.surface1, fg = colors.subtext0 },
						DropBarKindFile      = { fg = colors.blue },
						DropBarKindFolder    = { fg = colors.overlay0 },
						DropBarKindFunction  = { fg = colors.blue },
						DropBarKindMethod    = { fg = colors.blue },
						DropBarKindClass     = { fg = colors.yellow },
						DropBarKindModule    = { fg = colors.lavender },
						DropBarKindInterface = { fg = colors.yellow },
						DropBarKindVariable  = { fg = colors.text },
						DropBarKindProperty  = { fg = colors.teal },
						DropBarKindField     = { fg = colors.teal },
						DropBarKindConstant  = { fg = colors.lavender },
						DropBarKindEnum      = { fg = colors.lavender },
						DropBarKindKeyword   = { fg = colors.mauve },
						DropBarKindString    = { fg = colors.green },
						-- BqfPreview: preview float del quickfix
						BqfPreviewBorder  = { fg = colors.surface2 },
						BqfPreviewTitle   = { fg = colors.mauve,  bold = true },
						BqfPreviewRange   = { bg = "#3a2d52",     bold = true },
						BqfPreviewBufLabel= { fg = colors.mauve,  italic = true },
						BqfSign           = { fg = colors.mauve },

						-- ── Status line: transparente (lualine catppuccin integration lo maneja) ─
						StatusLine = { bg = t, fg = colors.text },
						-- overlay0 para texto de ventana inactiva: 4.1:1 contraste, legible
						StatusLineNC = { bg = t, fg = colors.overlay0 },

						-- ── Which-key: transparente ─────────────────────────────────────
						WhichKeyFloat = { bg = colors.mantle },
						WhichKeyBorder = { fg = colors.surface2, bg = colors.mantle },

						-- ── Claude Code: surface2 = uniforme con FloatBorder, título mauve ──
						ClaudeCodeBorder = { fg = colors.surface2, bg = colors.mantle },
						ClaudeCodeTitle = { fg = colors.mauve, bg = colors.mantle, bold = true },

						-- ── Terminal integrado (ToggleTerm) ────────────────────────────
						-- shade_terminals=false en terminal.lua → NormalFloat controla el bg
						-- Sin este override: el terminal queda negro puro (ANSI black 0 de WezTerm)
						ToggleTermNormal = { bg = colors.mantle },
						ToggleTermBorder = { fg = colors.surface2, bg = colors.mantle },

						-- ── Noice ──────────────────────────────────────────────
						NoiceCmdlinePopup       = { bg = colors.mantle, fg = colors.text },
						NoiceCmdlinePopupBorder = { fg = colors.surface2, bg = colors.mantle },
						NoiceCmdlinePopupTitle  = { fg = colors.mauve, bg = colors.mantle, bold = true },
						NoiceCmdlineIcon        = { fg = colors.mauve },
						NoiceMini               = { bg = colors.mantle },

						-- ── Telescope/Picker: full transparent ──────────────────────────
						TelescopeNormal = { bg = colors.mantle },
						TelescopeBorder = { fg = colors.surface2, bg = colors.mantle },
						TelescopePromptNormal = { bg = colors.mantle },
						TelescopePromptBorder = { fg = colors.mauve, bg = colors.mantle },
						TelescopePromptTitle = { fg = colors.mauve, bg = colors.mantle, bold = true },
						TelescopeResultsNormal = { bg = colors.mantle },
						TelescopeResultsBorder = { fg = colors.surface2, bg = colors.mantle },
						TelescopePreviewNormal = { bg = colors.mantle },
						TelescopePreviewBorder = { fg = colors.surface2, bg = colors.mantle },
						TelescopeSelection = { bg = colors.surface0, fg = colors.text },

						-- ── Snacks picker ───────────────────────────────────────────────
						SnacksPickerBorder  = { fg = colors.surface2, bg = colors.mantle },
						SnacksPickerNormal  = { bg = colors.mantle, fg = colors.text },
						SnacksPickerTitle   = { fg = colors.mauve, bg = colors.mantle, bold = true },

						-- ── Indent guides: muy discretos ────────────────────────────────
						MiniIndentscopeSymbol    = { fg = "#2e2f2b" },
						IndentBlanklineChar      = { fg = "#252622" },
							IblIndent                = { fg = "#252622" },
							IblScope                 = { fg = "#2e2f2b" },

						-- ── Visual selection: dark mauve blend — consistente con WezTerm selection_bg ──
						-- #394361 = blend(blue #89b4fa, base #1e1e2e, 25%) — H=222° azul puro, no rosado, 6.4:1 WCAG AA
						Visual = { bg = "#394361" },
						VisualNOS = { bg = "#394361" },

						-- ── Search highlights ───────────────────────────────────────────
						Search = { bg = colors.surface1, fg = colors.text },
						IncSearch = { bg = colors.peach, fg = colors.base, bold = true },
						CurSearch = { bg = colors.mauve, fg = colors.base, bold = true },

						-- ── Winbar / incline: transparente ──────────────────────────────
						WinBar = { bg = t, fg = colors.text },
						WinBarNC = { bg = t, fg = colors.overlay0 },

						-- ── SignColumn: transparente ─────────────────────────────────────
						SignColumn     = { bg = t },
						FoldColumn     = { fg = colors.surface1, bg = t },
						CursorLineSign = { bg = colors.surface0 },            -- sign col en cursor line = fondo CursorLine (sin gap)
						CursorLineFold = { bg = colors.surface0 },            -- fold col en cursor line = fondo CursorLine (sin gap)

						-- ── Listchars: dots/arrows sutiles (con vim.opt.list=true) ──────
						Whitespace  = { fg = colors.surface1 },               -- space dots (·) tab arrows (→) — casi invisibles
						NonText     = { fg = colors.surface0 },               -- extends/precedes/eob — receden al fondo
						SpecialKey  = { fg = colors.surface1 },               -- SpecialKey contexts (^I etc)

						-- ── vim-illuminate: word occurrences (LazyVim dep) ───────────
						IlluminatedWordText  = { bg = colors.surface1 },
						IlluminatedWordRead  = { bg = colors.surface1 },
						IlluminatedWordWrite = { bg = colors.surface1, underline = true, sp = colors.lavender },

						-- ── Snacks terminal/float: surface2 uniforme ────────────────────
						SnacksNormal = { bg = colors.mantle },
						SnacksBorder = { fg = colors.surface2, bg = colors.mantle },

						-- ── Database (nvim-dbee) ────────────────────────────────────────
						DbeeNormal = { bg = colors.mantle, fg = colors.text },
						DbeeBorder = { fg = colors.mauve, bg = colors.mantle },
						DbeeTitle = { fg = colors.mauve, bg = t, bold = true },

						-- ── Cursor premium ──────────────────────────────────────────────
						Cursor = { fg = colors.crust, bg = colors.mauve },
						lCursor = { fg = colors.crust, bg = colors.mauve },
						CursorIM = { fg = colors.crust, bg = colors.mauve },

						-- ── Matching parentheses ────────────────────────────────────────
						MatchParen = { fg = colors.peach, bg = colors.surface1, bold = true },

						-- ── Diagnostics ─────────────────────────────────────────────────
						DiagnosticError = { fg = colors.red },
						DiagnosticWarn = { fg = colors.yellow },
						DiagnosticInfo = { fg = colors.sky },
						DiagnosticHint = { fg = colors.teal },
						DiagnosticVirtualTextError = { fg = colors.red, bg = t, italic = true },
						DiagnosticVirtualTextWarn = { fg = colors.yellow, bg = t, italic = true },
						DiagnosticVirtualTextInfo = { fg = colors.sky, bg = t },
						DiagnosticVirtualTextHint = { fg = colors.teal, bg = t },
						DiagnosticUnderlineError = { sp = colors.red, undercurl = true },
						DiagnosticUnderlineWarn = { sp = colors.yellow, undercurl = true },
						DiagnosticUnderlineInfo = { sp = colors.sky, undercurl = true },
						DiagnosticUnderlineHint = { sp = colors.teal, undercurl = true },
						-- Código muerto/unused: dim+italic como comentario — IntelliJ/VS Code/Rider standard
						DiagnosticUnnecessary = { fg = colors.overlay0, italic = true },

						-- ── Diff ────────────────────────────────────────────────────────
						DiffAdd = { bg = "#1a3a2a" },
						DiffChange = { bg = "#1a2a3a" },
						DiffDelete = { bg = "#3a1a1a" },
						DiffText = { bg = "#1a3a4a", bold = true },

						-- ── Folding ─────────────────────────────────────────────────────
						Folded = { fg = colors.blue, bg = colors.surface0, italic = true },

						-- ── LSP references ──────────────────────────────────────────────
						LspReferenceText = { bg = colors.surface0 },
						LspReferenceRead = { bg = colors.surface0 },
						LspReferenceWrite = { bg = colors.surface0, bold = true },
						LspInfoBorder = { fg = colors.surface2, bg = colors.mantle },

						-- ── LSP Inlay Hints: overlay1 italic — secundarios, badge sobre mantle ──
						-- overlay1 (#7f849c) ≈ 5:1 contraste: más legible que overlay0 sin competir
						LspInlayHint = { fg = colors.overlay1, bg = colors.mantle, italic = true },
						-- Code lens (N references, N implementations): UI secundaria semántica
						LspCodeLensText      = { fg = colors.overlay1, italic = true },
						LspCodeLensSeparator = { fg = colors.surface2 },

						-- ── C# Semantic Tokens & Treesitter (Diferenciación Visual Élite basada en AST) ────────────
						-- Estas reglas dominan visualmente el código basándose en el motor sintáctico y semántico,
						-- eliminando la necesidad de subrayados falsos. El código "habla" por sus colores.

						-- LSP Semantics
						["@lsp.type.interface"] = { fg = colors.yellow, italic = true },
						["@lsp.type.class"] = { fg = colors.yellow, bold = true },
						["@lsp.type.method"] = { fg = colors.blue, bold = true },
						["@lsp.type.property"] = { fg = colors.teal },
						["@lsp.type.parameter"] = { fg = colors.peach, italic = true }, -- ST3 orange lane = peach
						-- Kanagawa principle: namespace es estructural, no semántico → overlay1 (dim)
						["@lsp.type.namespace"] = { fg = colors.overlay1 },
						-- enumMember: lavender — distinto de class (yellow) y property (teal)
						["@lsp.type.enumMember"] = { fg = colors.lavender },

						-- Treesitter Captures (Inspirado en tu :Inspect)
						["@function.method.call.c_sharp"] = { fg = colors.blue, bold = true },
						["@function.method.c_sharp"] = { fg = colors.blue, bold = true },
						["@variable.member.c_sharp"] = { fg = colors.teal },
						["@variable.c_sharp"] = { fg = colors.text },
						["@type.c_sharp"] = { fg = colors.yellow, bold = true },
						["@keyword.modifier.c_sharp"] = { fg = colors.mauve, italic = true },

						-- ── Flash/Leap ──────────────────────────────────────────────────
						FlashLabel = { fg = colors.base, bg = colors.peach, bold = true },
						FlashMatch = { fg = colors.lavender, bg = colors.surface0 },

						-- ── Lazy.nvim UI ────────────────────────────────────────────────
						LazyNormal = { bg = colors.mantle, fg = colors.text },
						LazyButton = { bg = colors.surface0, fg = colors.text },
						LazyButtonActive = { bg = colors.mauve, fg = colors.base, bold = true },
						LazyH1 = { bg = colors.mauve, fg = colors.base, bold = true },

						-- ── Mason ───────────────────────────────────────────────────────
						MasonNormal = { bg = colors.mantle },

						-- ── Treesitter Context: cabecera sticky (función/clase actual) ───
						-- Sin esto el contexto es casi invisible sobre fondo transparente
						TreesitterContext = { bg = colors.surface0, italic = true },
						TreesitterContextLineNumber = { fg = colors.lavender, bg = colors.surface0 },
						TreesitterContextBottom = { sp = colors.surface1, underline = true },
						TreesitterContextSeparator = { fg = colors.surface1 },

						-- ── Blink.cmp: completion menu unificado ────────────────────────
						BlinkCmpMenuBorder = { fg = colors.surface2, bg = colors.mantle },
						BlinkCmpDocBorder = { fg = colors.surface2, bg = colors.mantle },
						BlinkCmpDocSeparatorLine = { fg = colors.surface2 },
						BlinkCmpGhostText = { fg = colors.overlay0, italic = true },
						BlinkCmpSignatureHelpBorder = { fg = colors.surface2, bg = colors.mantle },

						-- ── Oil.nvim: legibilidad en file browser ────────────────────────
						OilDir = { fg = colors.lavender, bold = true },
						OilDirIcon = { fg = colors.lavender },
						OilFile = { fg = colors.text },
						OilLink = { fg = colors.teal, italic = true },
						OilLinkTarget = { fg = colors.teal, italic = true },
						OilCopy = { fg = colors.peach, bold = true },
						OilMove = { fg = colors.yellow, bold = true },
						OilDelete = { fg = colors.red, bold = true },
						OilCreate = { fg = colors.green, bold = true },

						-- ── Kulala HTTP client: panel respuesta + sintaxis .http ─────────
						KulalaNormal = { bg = colors.mantle, fg = colors.text },
						KulalaBorder = { fg = colors.mauve, bg = colors.mantle },
						-- Métodos HTTP con color semántico
						KulalaMethodGet = { fg = colors.green, bold = true },
						KulalaMethodPost = { fg = colors.yellow, bold = true },
						KulalaMethodPut = { fg = colors.peach, bold = true },
						KulalaMethodDelete = { fg = colors.red, bold = true },
						KulalaMethodPatch = { fg = colors.sky, bold = true },
						KulalaMethodHead = { fg = colors.teal, bold = true },
						-- Códigos de estado HTTP
						KulalaStatusCodeSuccess = { fg = colors.green, bold = true },
						KulalaStatusCodeRedirect = { fg = colors.yellow, bold = true },
						KulalaStatusCodeClientError = { fg = colors.peach, bold = true },
						KulalaStatusCodeServerError = { fg = colors.red, bold = true },
						-- URLs y headers
						KulalaURL = { fg = colors.blue, underline = true },
						KulalaHeader = { fg = colors.teal },
						KulalaHeaderValue = { fg = colors.text },
						-- Variables {{var}}: lavender = distinción visual clara
						KulalaVariableName = { fg = colors.lavender, italic = true },
						KulalaVariableValue = { fg = colors.peach },
						-- Comentarios # y // en .http
						KulalaComment = { fg = colors.overlay0, italic = true },
						-- Inlay icons (loading · done · error)
						KulalaInlayHint = { fg = colors.surface2 },

						-- u2500u2500 SnacksNotify: notificaciones con identidad Catppuccin u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500
						SnacksNotifyERROR = { fg = colors.red },
						SnacksNotifyWARN  = { fg = colors.yellow },
						SnacksNotifyINFO  = { fg = colors.teal },
						SnacksNotifyDEBUG = { fg = colors.overlay0 },
						SnacksNotifyBorderERROR = { fg = colors.red,     bg = t },
						SnacksNotifyBorderWARN  = { fg = colors.yellow,  bg = t },
						SnacksNotifyBorderINFO  = { fg = colors.teal,    bg = t },
						SnacksNotifyBorderDEBUG = { fg = colors.overlay0, bg = t },
						SnacksNotifyTitleERROR  = { fg = colors.red,     bold = true },
						SnacksNotifyTitleWARN   = { fg = colors.yellow,  bold = true },
						SnacksNotifyTitleINFO   = { fg = colors.teal,    bold = true },
						SnacksNotifyTitleDEBUG  = { fg = colors.overlay0, bold = true },
						SnacksNotifyIconERROR   = { fg = colors.red },
						SnacksNotifyIconWARN    = { fg = colors.yellow },
						SnacksNotifyIconINFO    = { fg = colors.teal },
						SnacksNotifyIconDEBUG   = { fg = colors.overlay0 },

						-- u2500u2500 TabLine: barra de pestanas nativa nvim u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500
						TabLine     = { fg = colors.overlay1, bg = colors.mantle },
						TabLineFill = { fg = t,               bg = colors.mantle },
						TabLineSel  = { fg = colors.mauve,    bg = colors.surface0, bold = true },

						-- u2500u2500 RenderMarkdown: jerarquia visual con tints Catppuccin u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500
						-- Headings: jerarquía luminancia (Kanagawa) — warm-white→olive-dim
						-- NO rainbow: gradiente comunica jerarquía sin ruido visual
						RenderMarkdownH1 = { fg = "#e8e6e0", bold = true },   -- H1: máximo brillo
						RenderMarkdownH2 = { fg = "#cccac4", bold = true },   -- H2: brillante
						RenderMarkdownH3 = { fg = "#b0aea8", bold = true },   -- H3: medio
						RenderMarkdownH4 = { fg = "#969490", bold = true },   -- H4: dim
						RenderMarkdownH5 = { fg = "#7c7a76", italic = true }, -- H5: muy dim italic
						RenderMarkdownH6 = { fg = "#75715e", italic = true }, -- H6: comment-level
						RenderMarkdownH1Bg = { bg = "#2D1B28" },  -- red/mantle tint
						RenderMarkdownH2Bg = { bg = "#2D2218" },  -- peach/mantle tint
						RenderMarkdownH3Bg = { bg = "#2D2B18" },  -- yellow/mantle tint
						RenderMarkdownH4Bg = { bg = "#1C2D1C" },  -- green/mantle tint
						RenderMarkdownH5Bg = { bg = "#1C272D" },  -- teal/mantle tint
						RenderMarkdownH6Bg = { bg = "#261C2D" },  -- mauve/mantle tint
						RenderMarkdownCode = { bg = colors.mantle },
						RenderMarkdownCodeInline = { bg = colors.surface0, fg = colors.peach },
						RenderMarkdownBullet = { fg = "#fd971f" },       -- orange ST3 (menos invasivo que red/mauve)
						RenderMarkdownLink   = { fg = colors.blue, underline = true },
						RenderMarkdownTodo   = { fg = colors.yellow, bold = true },
						RenderMarkdownQuote  = { fg = "#8a8878",         italic = true }, -- muted olive (Kanagawa: UI recede)
						RenderMarkdownDash   = { fg = colors.surface1 },
						RenderMarkdownTableHead = { fg = colors.mauve, bold = true },
						RenderMarkdownTableRow  = { fg = colors.text },
						RenderMarkdownTableFill = { fg = colors.surface1 },

						-- u2500u2500 MiniFiles: file explorer flotante u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500
						MiniFilesNormal       = { bg = colors.mantle, fg = colors.text },
						MiniFilesBorder       = { fg = colors.surface2, bg = colors.mantle },
						MiniFilesTitle        = { fg = colors.overlay1, bg = colors.mantle },
						MiniFilesTitleFocused = { fg = colors.mauve, bg = colors.mantle, bold = true },
						MiniFilesDirectory    = { fg = colors.blue, bold = true },
						MiniFilesCursorLine   = { bg = colors.surface0 },
						-- ── Treesitter: jerárquía de color AST-aware (Kanagawa principle) ────────────────────
						-- Kanagawa pioneeró strict semantic lanes: cada rol visual = UN color único.
						-- Aquí aplicamos esa disciplina sobre la paleta Catppuccin Mocha.

						-- Variables
						["@variable"]              = { fg = colors.text },
						["@variable.builtin"]      = { fg = colors.mauve, italic = true },  -- self/this/super (Kanagawa: builtins=italic)
						["@variable.parameter"]         = { fg = colors.peach, italic = true }, -- parámetros fn: peach=ST3 orange #fd971f equiv
						["@variable.parameter.builtin"] = { fg = colors.peach, bold = true, italic = true }, -- self/this/super
						["@variable.member"]            = { fg = colors.teal },          -- fields de struct/object

						-- Funciones
						["@function"]              = { fg = colors.blue, bold = true },
						["@function.call"]         = { fg = colors.blue },
						["@function.builtin"]      = { fg = colors.peach, italic = true },  -- print/len/range (italic=magia del lenguaje)
						["@function.method"]       = { fg = colors.blue, bold = true },
						["@function.method.call"]  = { fg = colors.blue },
						["@constructor"]           = { fg = colors.sapphire },        -- distinto de fn(blue) y type(yellow)

						-- Tipos
						["@type"]                  = { fg = colors.yellow },
						["@type.builtin"]          = { fg = colors.yellow, italic = true }, -- string, int, bool
						["@type.qualifier"]        = { fg = colors.mauve, italic = true },  -- const, abstract, readonly
						["@type.definition"]       = { fg = colors.yellow, bold = true },   -- typedef, type alias

						-- Keywords: diferenciación por peso semántico
						["@keyword.return"]        = { fg = colors.mauve, italic = true, bold = true }, -- return resalta
						["@keyword.exception"]     = { fg = colors.red },             -- throw, raise, catch
						["@keyword.import"]        = { fg = colors.teal, italic = true }, -- import, using, require
						["@keyword.operator"]      = { fg = colors.teal, bold = true }, -- is, in, not, and, or
						["@keyword.type"]          = { fg = colors.yellow },          -- type keyword (TypeScript)
						-- Explícitos para garantizar italic aunque styles-propagation falle
						["@keyword"]               = { fg = colors.mauve, italic = true },             -- base keyword: italic universal
						["@keyword.conditional"]   = { fg = colors.mauve, italic = true },             -- if/else/switch/match/when
						["@keyword.loop"]          = { fg = colors.mauve, italic = true },             -- for/while/do/loop/repeat
						["@keyword.coroutine"]     = { fg = colors.blue,  italic = true },             -- async/await/yield → azul async lane
						["@keyword.modifier"]      = { fg = colors.mauve, italic = true },             -- public/private/protected/override/sealed
						["@keyword.function"]      = { fg = colors.mauve, italic = true },             -- 'function'/'def'/'fn' (ST3: storage.type = italic)
						["@keyword.storage"]       = { fg = colors.mauve, italic = true },             -- var/let/const/val/ref (declaracion de variable)

						-- Constantes y literales numéricos
						["@constant"]              = { fg = colors.peach },
						["@constant.builtin"]      = { fg = colors.lavender, bold = true }, -- nil/true/false/None → ST3 purple lane
						["@constant.macro"]        = { fg = colors.mauve },           -- #define macros
						["@number"]                = { fg = colors.lavender },             -- ST3 #ae81ff → lavender
						["@number.float"]          = { fg = colors.lavender },
						["@boolean"]               = { fg = colors.lavender, bold = true },

						-- Strings: diferenciación interna crítica (principio Kanagawa)
						["@string"]                = { fg = colors.green },
						["@string.escape"]         = { fg = colors.maroon },         -- Kanagawa sakuraPink: sutil            -- \n \t \\ escapes resaltados
						["@string.regexp"]         = { fg = colors.peach },           -- regex patterns
						["@string.special"]        = { fg = colors.maroon },         -- maroon: elegante no agresivo            -- format strings %s, {}
						-- URLs en código: blue+underline — mismo estándar que VS Code/Sublime/JetBrains
						["@string.special.url"]         = { fg = colors.blue, underline = true },
						["@string.special.url.comment"] = { fg = colors.sky, underline = true },

						-- Operadores y puntuación (Kanagawa: UI recede, código emerge)
						["@operator"]              = { fg = colors.teal },            -- + - * / = < >
						["@punctuation.delimiter"] = { fg = colors.overlay2 },        -- , ; .  casi invisibles
						["@punctuation.bracket"]   = { fg = colors.overlay1 },        -- () [] {} receden
						["@punctuation.special"]   = { fg = colors.mauve },           -- interpolación #{} ``

						-- Comentarios semánticos (Kanagawa distingue intención del comentario)
						["@comment"]               = { fg = colors.overlay0, italic = true },
						["@comment.todo"]          = { fg = colors.yellow, bold = true },
						["@comment.note"]          = { fg = colors.blue, bold = true },
						["@comment.warning"]       = { fg = colors.peach, bold = true },
						["@comment.error"]         = { fg = colors.red, bold = true },
						["@comment.documentation"] = { fg = colors.sky, italic = true }, -- JSDoc, docstrings

						-- ── Markup/Markdown: hex Monokai Night exactos (ref: syntax.json, override por autocmd) ──
						["@markup.heading"]               = { fg = "#BDBDBD", bold = true },
						["@markup.heading.marker"]        = { fg = "#FD9621" },
						["@markup.heading.1.markdown"]    = { fg = "#e8e6e0", bold = true }, -- H1: máximo brillo
						["@markup.heading.2.markdown"]    = { fg = "#cccac4", bold = true }, -- H2: brillante
						["@markup.heading.3.markdown"]    = { fg = "#b0aea8", bold = true }, -- H3: medio
						["@markup.heading.4.markdown"]    = { fg = "#969490", bold = true }, -- H4: dim
						["@markup.heading.5.markdown"]    = { fg = "#7c7a76", italic = true }, -- H5: muy dim italic
						["@markup.heading.6.markdown"]    = { fg = "#75715e", italic = true }, -- H6: comment-level
						["@markup.bold"]                  = { bold = true },                      -- style-only: bold inherits fg
						["@markup.italic"]                = { italic = true },                    -- style-only: italic inherits fg
						["@markup.strikethrough"]         = { fg = "#75715E", strikethrough = true },
						["@markup.raw.inline"]            = { fg = "#FD9621" },
						["@markup.link"]                  = { fg = "#66D9EF" },
						["@markup.link.url"]              = { fg = "#66D9EF", underline = true },
						["@markup.link.label"]            = { fg = "#967EFB", italic = true },
						["@markup.list"]                  = { fg = "#fd971f" },  -- orange: bullets estructurales
						["@markup.list.checked"]          = { fg = "#A6E22E" },
						["@markup.list.unchecked"]        = { fg = "#75715E" },
						["@markup.quote"]                 = { fg = "#8a8878", italic = true },  -- muted olive (UI recede)
						["@markup.math"]                  = { fg = "#967EFB" },

						-- Tags HTML/JSX/TSX/Svelte
						["@tag"]                   = { fg = colors.mauve },
						["@tag.attribute"]         = { fg = colors.peach, italic = true },
						["@tag.delimiter"]         = { fg = colors.overlay1 },        -- < > / receden

						-- Módulos, atributos y decoradores
						["@module"]                = { fg = colors.overlay1 },        -- estructural, no semántico
						["@module.builtin"]        = { fg = colors.blue },            -- builtins del lenguaje
						["@attribute"]             = { fg = colors.lavender, italic = true }, -- decoradores @Deco
						["@attribute.builtin"]     = { fg = colors.lavender },

						-- ── LSP semantic token modifiers: dominan sobre treesitter ──────────────────
						-- typemod = tipo + modificador. Fuente: typescript-language-server, gopls, omnisharp
						["@lsp.type.decorator"]                  = { fg = colors.lavender, italic = true },
						["@lsp.type.macro"]                      = { fg = colors.mauve },
						["@lsp.type.enum"]                       = { fg = colors.yellow },
						["@lsp.type.struct"]                     = { fg = colors.yellow, bold = true },
						["@lsp.type.event"]                      = { fg = colors.yellow, italic = true },  -- C# event (tipo-nivel)
						["@lsp.type.delegate"]                   = { fg = colors.yellow, italic = true },  -- C# delegate (tipo callable)
						["@lsp.type.typeParameter"]              = { fg = colors.peach, italic = true }, -- T, K, V
						["@lsp.typemod.variable.readonly"]       = { fg = colors.lavender },       -- const vars
						["@lsp.typemod.variable.defaultLibrary"] = { fg = colors.peach },          -- console, process
						["@lsp.typemod.function.defaultLibrary"] = { fg = colors.peach },          -- stdlib fns
						["@lsp.typemod.function.async"]          = { fg = colors.blue, italic = true }, -- async fn
						["@lsp.typemod.method.async"]            = { fg = colors.blue, italic = true },
						["@lsp.typemod.class.abstract"]          = { fg = colors.yellow, italic = true },
						["@lsp.typemod.variable.deprecated"]     = { fg = colors.overlay0, strikethrough = true },
						["@lsp.typemod.function.deprecated"]     = { fg = colors.overlay0, strikethrough = true },
						["@lsp.typemod.keyword.documentation"]   = { fg = colors.overlay1, italic = true }, -- @param

						-- ── Static members: italic = "clase/nivel" (no instancia) ───────────────────────────
						-- Principio: italic indica que el símbolo NO pertenece a una instancia concreta
						["@lsp.typemod.method.static"]           = { fg = colors.blue,     italic = true },             -- Math.Abs, Console.Write
						["@lsp.typemod.property.static"]         = { fg = colors.teal,     italic = true },             -- static prop
						["@lsp.typemod.field.static"]            = { fg = colors.teal,     italic = true },             -- static field
						["@lsp.typemod.variable.static"]         = { fg = colors.lavender, italic = true },             -- static var/const class-level

						-- ── Abstract / Virtual: italic+bold = contrato no implementado ───────────────────────
						-- bold = peso semántico alto (hay contrato), italic = no-concreto
						["@lsp.typemod.method.abstract"]         = { fg = colors.blue,     italic = true, bold = true },
						["@lsp.typemod.property.abstract"]       = { fg = colors.teal,     italic = true, bold = true },
						["@lsp.typemod.method.virtual"]          = { fg = colors.blue,     italic = true },             -- overridable (sin bold: tiene impl)

						-- ── Extension methods (C# this-parameter, LINQ) ───────────────────────────────────────
						["@lsp.typemod.method.extension"]        = { fg = colors.blue,     italic = true },

						-- ── Readonly / immutable: lavender lane (const principle) ────────────────────────────
						["@lsp.typemod.property.readonly"]       = { fg = colors.lavender },                            -- string.Length, .Count
						["@lsp.typemod.field.readonly"]          = { fg = colors.lavender },                            -- readonly field

						-- ── Sealed: bold sin italic = concreto+cerrado ────────────────────────────────────────
						["@lsp.typemod.class.sealed"]            = { fg = colors.yellow,   bold = true },

						-- ── Stdlib / defaultLibrary: peach lane = magic del runtime ──────────────────────────
						["@lsp.typemod.type.defaultLibrary"]     = { fg = colors.peach },                               -- IEnumerable, Task, ValueTuple
						["@lsp.typemod.class.defaultLibrary"]    = { fg = colors.peach },                               -- Console, Math, String, GC
						["@lsp.typemod.method.defaultLibrary"]   = { fg = colors.peach },                               -- .ToString(), .GetHashCode()

						-- ── Deprecated members: overlay0+strikethrough (requiere no_strikethrough=false) ──────
						["@lsp.typemod.property.deprecated"]     = { fg = colors.overlay0, strikethrough = true },
						["@lsp.typemod.field.deprecated"]        = { fg = colors.overlay0, strikethrough = true },
						["@lsp.typemod.class.deprecated"]        = { fg = colors.overlay0, italic = true },
						["@lsp.typemod.method.deprecated"]       = { fg = colors.overlay0, strikethrough = true },

						-- ── Blink.cmp: completion kinds con identidad visual (Kanagawa mapping) ───────
						-- Cada kind = color de su rol semántico. Consistente con treesitter + LSP arriba.
						BlinkCmpKindFunction      = { fg = colors.blue },
						BlinkCmpKindMethod        = { fg = colors.blue },
						BlinkCmpKindConstructor   = { fg = colors.sapphire },
						BlinkCmpKindClass         = { fg = colors.yellow },
						BlinkCmpKindInterface     = { fg = colors.yellow },
						BlinkCmpKindStruct        = { fg = colors.yellow },
						BlinkCmpKindEnum          = { fg = colors.yellow },
						BlinkCmpKindEnumMember    = { fg = colors.lavender },
						BlinkCmpKindVariable      = { fg = colors.text },
						BlinkCmpKindField         = { fg = colors.teal },
						BlinkCmpKindProperty      = { fg = colors.teal },
						BlinkCmpKindConstant      = { fg = colors.lavender },
						BlinkCmpKindModule        = { fg = colors.overlay1 },
						BlinkCmpKindKeyword       = { fg = colors.mauve },
						BlinkCmpKindOperator      = { fg = colors.teal },
						BlinkCmpKindSnippet       = { fg = colors.green },
						BlinkCmpKindText          = { fg = colors.text },
						BlinkCmpKindTypeParameter = { fg = colors.peach },
						BlinkCmpKindFile          = { fg = colors.blue },
						BlinkCmpKindFolder        = { fg = colors.lavender },
						BlinkCmpKindColor         = { fg = colors.peach },
						BlinkCmpKindReference     = { fg = colors.teal },
						BlinkCmpKindUnit          = { fg = colors.peach },
						BlinkCmpKindValue         = { fg = colors.peach },
						BlinkCmpKindEvent         = { fg = colors.peach },
						PmenuSbar                 = { bg = colors.surface0 },

						-- ── UI Messages: informativos, no compiten con código (Kanagawa: UI recede) ───
						MsgArea    = { fg = colors.subtext0 },
						ModeMsg    = { fg = colors.text, bold = true },
						MoreMsg    = { fg = colors.teal, bold = true },
						ErrorMsg   = { fg = colors.red, bold = true },
						WarningMsg = { fg = colors.yellow },
						Question   = { fg = colors.green, bold = true },
						-- ── Rainbow Delimiters: color lanes del sistema semántico ────────────────────
						-- Pre-definidos aquí para estar listos cuando rainbow-delimiters.nvim esté activo.
						-- Sin plugin activo: grupos ignorados silenciosamente (zero-risk).
						RainbowDelimiterMauve    = { fg = colors.mauve },    -- nivel 1: acento/identidad
						RainbowDelimiterBlue     = { fg = colors.blue },     -- nivel 2: funciones
						RainbowDelimiterTeal     = { fg = colors.teal },     -- nivel 3: propiedades/ops
						RainbowDelimiterYellow   = { fg = colors.yellow },   -- nivel 4: tipos/clases
						RainbowDelimiterPeach    = { fg = colors.peach },    -- nivel 5: números/literales
						RainbowDelimiterLavender = { fg = colors.lavender }, -- nivel 6: constantes/enum
						RainbowDelimiterPink     = { fg = colors.maroon },   -- nivel 7: escapes/esp (maroon=sutil)

						-- ── @character: literales de caracter (’a’, ’\n’) en C/C#/Java ────────────────
						-- maroon = familia "literales especiales" (consistente con @string.escape)
						Character                  = { fg = colors.maroon },
						SpecialChar                = { fg = colors.maroon },
						["@character"]             = { fg = colors.maroon },
						["@character.special"]     = { fg = colors.maroon },

						-- ── Satellite.nvim: scrollbar premium con HUD de navegacion ─────────────
						-- Cursor=mauve (acento), Search=peach (destacado), Diag=semantic, Git=semantic
						SatelliteBar                 = { fg = colors.overlay0, bg = "NONE" },
						SatelliteCursor              = { fg = colors.mauve,   bg = "NONE" },
						SatelliteSearch              = { fg = colors.peach,   bg = "NONE" },
						SatelliteDiagnosticError     = { fg = colors.red,     bg = "NONE" },
						SatelliteDiagnosticWarn      = { fg = colors.yellow,  bg = "NONE" },
						SatelliteDiagnosticInfo      = { fg = colors.sky,     bg = "NONE" },
						SatelliteDiagnosticHint      = { fg = colors.teal,    bg = "NONE" },
						SatelliteGitsignsAdd         = { fg = colors.green,   bg = "NONE" },
						SatelliteGitsignsChange      = { fg = colors.yellow,  bg = "NONE" },
						SatelliteGitsignsDelete      = { fg = colors.red,     bg = "NONE" },
						-- ── FzfLua: picker flotante transparente ────────────────────────────────────────────
						FzfLuaNormal        = { bg = colors.mantle, fg = colors.text },
						FzfLuaBorder        = { fg = colors.surface2, bg = colors.mantle },
						FzfLuaTitle         = { fg = colors.mauve, bg = colors.mantle, bold = true },
						FzfLuaPreviewBorder = { fg = colors.surface2, bg = colors.mantle },
						FzfLuaPreviewTitle  = { fg = colors.overlay1, bg = colors.mantle },
						FzfLuaFzfBorder     = { fg = colors.surface2 },
						FzfLuaFzfSeparator  = { fg = colors.surface2 },
						FzfLuaFzfGutter     = { bg = t },
						FzfLuaCursorLine    = { bg = colors.surface0 },

						-- ── GrugFar: search/replace panel ──────────────────────────────────────────────
						GrugFarNormal       = { bg = colors.mantle, fg = colors.text },
						GrugFarBorder       = { fg = colors.surface2, bg = colors.mantle },
						GrugFarInputNormal  = { bg = colors.surface0, fg = colors.text },
						GrugFarInputBorder  = { fg = colors.surface2, bg = colors.surface0 },

						-- ── Trouble: lista de diagnósticos ──────────────────────────────────────────────
						TroubleNormal       = { bg = t, fg = colors.text },
						TroubleNormalNC     = { bg = t, fg = colors.overlay0 },

						-- ── DiffView: paneles de code review ──────────────────────────────────────────
						DiffviewNormal            = { bg = t, fg = colors.text },
						DiffviewCursorLine        = { bg = colors.surface0 },
						DiffviewFilePanelFileName  = { fg = colors.text },
						DiffviewFilePanelTitle     = { fg = colors.mauve, bold = true },
						DiffviewFolderName         = { fg = colors.blue },
						DiffviewFilePanelSelected  = { bg = colors.surface0, fg = colors.mauve },

						-- ── MiniIcons: catppuccin latte color mapping → mocha ────────────────────────
						-- Solo glifos/iconos. Texto/labels: gestionados por NeoTree/Blink highlights.
						-- latte semantic → mocha equivalente (mismo nombre de color, diferente hex).
						MiniIconsAzure  = { fg = colors.sky },      -- .ts, .cs, .go (sky #89dceb)
						MiniIconsBlue   = { fg = colors.blue },     -- .lua, .vim, .py (blue #89b4fa)
						MiniIconsCyan   = { fg = colors.teal },     -- .sh, .bash, .zsh (teal #94e2d5)
						MiniIconsGreen  = { fg = colors.green },    -- .md, .txt, .env (green #a6e3a1)
						MiniIconsGrey   = { fg = colors.overlay1 }, -- sin icono / unknown
						MiniIconsOrange = { fg = colors.peach },    -- .rs, .html, .c (peach #fab387)
						MiniIconsPurple = { fg = colors.lavender }, -- .rb, .ex, .clj (lavender #b4befe)
						MiniIconsRed    = { fg = colors.red },      -- .err, .lock, .log
						MiniIconsWhite  = { fg = colors.text },     -- .toml, .yaml, .ini
						MiniIconsYellow = { fg = colors.yellow },   -- .js, .json, .cpp (yellow #f9e2af)



					}
				end,
			},

			-- Integraciones: activar todas las relevantes
			integrations = {
				blink_cmp = true,
				dap = true,
				dap_ui = true,
				gitsigns = true,
				harpoon = true,
				lsp_trouble = true,
				mason = true,
				mini = { enabled = true },
				neotree = true,
				noice = true,
				notify = true,
				render_markdown = true,
				snacks = true,
				symbols_outline = true,
				telescope = { enabled = true },
				treesitter = true,
				which_key = true,
				lualine = true,
			},
		},
	},

	-- ─── nvim-web-devicons: colores Catppuccin oficiales ──────────────────────
	{
		"nvim-tree/nvim-web-devicons",
		opts = {
			color_icons = true,
			default = true,
		},
	},

	-- ─── LazyVim: catppuccin como colorscheme default ───────────────────────────
	{
		"LazyVim/LazyVim",
		opts = { colorscheme = "sublime" },
	},
}
