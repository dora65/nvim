-- ─── Kanagawa Blur — paleta de referencia para highlight_overrides ───────────
-- Blur variant hex codes (de variant.lua + windows-terminal.json oficial)
local K = {
	none = "NONE",
	-- Fondos (bg_dark = "none" = transparente en la variante blur)
	bg = "#161617", -- fondo terminal (Windows Terminal JSON)
	gray1 = "#191E28",
	gray2 = "#232A40",
	gray3 = "#313342",
	gray4 = "#27345C",
	gray5 = "#5C6170",
	surface0 = "#1C212C",
	surface1 = "#232A36",
	surface2 = "#2A3142",
	lsp_bg = "#2D3C4A",
	-- Texto
	fg = "#F3F6F9",
	fg_muted = "#5C6170",
	fg_dim = "#8394A3",
	-- Acento principal: oro (Ray-Ban aviator — firma del autor)
	accent = "#E0C15A",
	-- Colores semánticos
	red = "#CB7C94",
	green = "#B7CC85",
	yellow = "#FFE066",
	orange = "#DEBA87",
	blue = "#7FB4CA",
	cyan = "#7AA89F",
	purple = "#A3B5D6",
	magenta = "#FF8DD7",
	-- Sintaxis
	func_ = "#B99BF2",
	keyword_ = "#C99AD6",
	str_ = "#DFBD76",
	comment_ = "#8394A3",
	type_ = "#8FB8DD",
	variable_ = "#C4746E",
	prop_ = "#A1B5C7",
	var_param = "#C7A8DF",
	var_mem = "#B8AFC6",
	type_i = "#98CCE6", -- type_interface
	type_s = "#92B3CC", -- type_super
	-- UI
	selection = "#1E2A3A",  -- waveBlue-inspired: sutil tint azul, no navy saturado
	-- Diffs
	diff_add = "#1E2D1E",
	diff_chg = "#2D2A1E",
	diff_del = "#2D211E",
	diff_txt = "#332F1E",
}

return {
	-- ─── Gentleman Kanagawa Blur — tema default ──────────────────────────────────
	{
		"Gentleman-Programming/gentleman-kanagawa-blur",
		name = "gentleman-kanagawa-blur",
		priority = 1000,
		opts = {
			variant = "blur",
			terminal_colors = true,
			-- styles: no se especifica → el plugin usa sus propios defaults.
			-- NUNCA usar { "italic" } (array) → nvim_set_hl recibe key [1] → error.
			integrations = {
				-- Módulos exactos del plugin (24 total). Claves inválidas → error "module not found".
				telescope = true,
				neo_tree = true,
				gitsigns = true,
				noice = true,
				notify = true,
				treesitter = true,
				lsp = true,
				mason = true,
				lazy = true,
				render_markdown = true,
				snacks = true,
				flash = true,
				indent_blankline = true,
				blink = true, -- blink.cmp (NO blink_cmp)
				mini = true,
				markdown = true,
				-- which_key / trouble / lsp_trouble: no existen en este plugin
			},
			-- highlight_overrides: tabla plana — se aplica last, sobreescribe todo.
			-- Cubre: transparencia, todos los plugins, LSP, C#, sintaxis, UI.
			highlight_overrides = {
				-- ── Transparency stack ───────────────────────────────────────────
				Normal = { bg = K.none },
				NormalNC = { bg = K.none, fg = K.fg_dim },
				NormalFloat = { bg = K.none, fg = K.fg },
				FloatBorder = { fg = K.gray3, bg = K.none },
				FloatTitle = { fg = K.accent, bg = K.none, bold = true },
				FloatFooter = { fg = K.fg_dim, bg = K.none },
				WinSeparator = { fg = K.gray2, bg = K.none },
				VertSplit = { fg = K.gray2, bg = K.none },

				-- ── Editor base ──────────────────────────────────────────────────
				CursorLine = { bg = K.surface0 },
				CursorLineNr = { fg = K.blue, bold = true },
				LineNr = { fg = K.fg_dim },
				Pmenu = { bg = K.gray1, fg = K.fg },
				PmenuSel = { bg = K.surface1, fg = K.fg, bold = true },
				PmenuSbar = { bg = K.surface0 },
				PmenuThumb = { bg = K.surface2 },
				Visual = { bg = K.selection },
				VisualNOS = { bg = K.selection },
				Search = { bg = K.surface1, fg = K.fg },
				IncSearch = { bg = K.orange, fg = K.gray1, bold = true },
				CurSearch = { bg = K.accent, fg = K.gray1, bold = true },
				SignColumn = { bg = K.none },
				FoldColumn = { fg = K.gray3, bg = K.none },
				Folded = { fg = K.fg_muted, bg = K.surface0, italic = true },
				StatusLine = { bg = K.surface1, fg = K.fg },
				StatusLineNC = { bg = K.surface0, fg = K.fg_dim },
				WinBar = { bg = K.none, fg = K.fg },
				WinBarNC = { bg = K.none, fg = K.fg_dim },
				Cursor = { fg = K.gray1, bg = K.accent },
				lCursor = { fg = K.gray1, bg = K.accent },
				CursorIM = { fg = K.gray1, bg = K.accent },
				MatchParen = { fg = K.orange, bg = K.surface1, bold = true },

				-- ── Diff ────────────────────────────────────────────────────────
				DiffAdd = { bg = K.diff_add },
				DiffChange = { bg = K.diff_chg },
				DiffDelete = { bg = K.diff_del },
				DiffText = { bg = K.diff_txt, bold = true },

				-- ── LSP Diagnostics ──────────────────────────────────────────────
				DiagnosticError = { fg = K.red },
				DiagnosticWarn = { fg = K.yellow },
				DiagnosticInfo = { fg = K.cyan },
				DiagnosticHint = { fg = K.green },
				DiagnosticVirtualTextError = { fg = K.red, bg = K.none, italic = true },
				DiagnosticVirtualTextWarn = { fg = K.yellow, bg = K.none, italic = true },
				DiagnosticVirtualTextInfo = { fg = K.cyan, bg = K.none },
				DiagnosticVirtualTextHint = { fg = K.green, bg = K.none },
				DiagnosticUnderlineError = { sp = K.red, undercurl = true },
				DiagnosticUnderlineWarn = { sp = K.yellow, undercurl = true },
				DiagnosticUnderlineInfo = { sp = K.cyan, undercurl = true },
				DiagnosticUnderlineHint = { sp = K.green, undercurl = true },
				LspInlayHint = { fg = K.fg_dim, italic = true },
				LspReferenceText = { bg = K.lsp_bg },
				LspReferenceRead = { bg = K.lsp_bg },
				LspReferenceWrite = { bg = K.lsp_bg, bold = true },
				LspInfoBorder = { fg = K.gray3, bg = K.none },

				-- ── C# / LSP semántico ────────────────────────────────────────────
				["@lsp.type.interface"] = { fg = K.type_i, italic = true },
				["@lsp.type.class"] = { fg = K.type_, bold = true },
				["@lsp.type.method"] = { fg = K.func_, bold = true },
				["@lsp.type.property"] = { fg = K.prop_ },
				["@lsp.type.parameter"] = { fg = K.var_param, italic = true },
				["@lsp.type.namespace"] = { fg = K.fg_dim },
				["@lsp.type.enumMember"] = { fg = K.purple },
				["@function.method.call.c_sharp"] = { fg = K.func_, bold = true },
				["@function.method.c_sharp"] = { fg = K.func_, bold = true },
				["@variable.member.c_sharp"] = { fg = K.var_mem },
				["@variable.c_sharp"] = { fg = K.fg },
				["@type.c_sharp"] = { fg = K.type_, bold = true },
				["@keyword.modifier.c_sharp"] = { fg = K.keyword_, italic = true },

				-- ── Neo-tree ─────────────────────────────────────────────────────
				NeoTreeNormal = { bg = K.none, fg = K.fg },
				NeoTreeNormalNC = { bg = K.none, fg = K.fg_dim },
				NeoTreeWinSeparator = { fg = K.gray2, bg = K.none },
				NeoTreeEndOfBuffer = { bg = K.none, fg = K.none },
				NeoTreeCursorLine = { bg = K.surface0 },
				NeoTreeDimText = { fg = K.fg_dim },
				NeoTreeIndentMarker = { fg = K.gray3 },
				NeoTreeGitAdded = { fg = K.green },
				NeoTreeGitModified = { fg = K.yellow },
				NeoTreeGitDeleted = { fg = K.red },
				NeoTreeGitUntracked = { fg = K.cyan },
				NeoTreeDirectoryIcon = { fg = K.blue },
				NeoTreeDirectoryName = { fg = K.blue },
				NeoTreeRootName = { fg = K.accent, bold = true, italic = true },
				NeoTreeFileName = { fg = K.fg },
				NeoTreeFileNameOpened = { fg = K.accent, bold = true },

				-- ── Which-key ────────────────────────────────────────────────────
				WhichKeyFloat = { bg = K.none },
				WhichKeyBorder = { fg = K.gray3, bg = K.none },

				-- ── Noice ────────────────────────────────────────────────────────
				NoiceCmdlinePopupBorder = { fg = K.gray3, bg = K.none },
				NoiceCmdlineIcon = { fg = K.accent },

				-- ── Telescope / Picker ───────────────────────────────────────────
				TelescopeNormal = { bg = K.none },
				TelescopeBorder = { fg = K.gray3, bg = K.none },
				TelescopePromptNormal = { bg = K.none },
				TelescopePromptBorder = { fg = K.accent, bg = K.none },
				TelescopePromptTitle = { fg = K.accent, bg = K.none, bold = true },
				TelescopeResultsNormal = { bg = K.none },
				TelescopeResultsBorder = { fg = K.gray3, bg = K.none },
				TelescopePreviewNormal = { bg = K.none },
				TelescopePreviewBorder = { fg = K.gray3, bg = K.none },
				TelescopeSelection = { bg = K.surface0, fg = K.fg },

				-- ── Snacks ───────────────────────────────────────────────────────
				SnacksPickerBorder = { fg = K.gray3, bg = K.none },
				SnacksNormal = { bg = K.none },
				SnacksBorder = { fg = K.accent, bg = K.none },

				-- ── Blink.cmp ────────────────────────────────────────────────────
				BlinkCmpMenuBorder = { fg = K.gray3, bg = K.none },
				BlinkCmpDocBorder = { fg = K.gray3, bg = K.none },
				BlinkCmpDocSeparatorLine = { fg = K.gray3 },
				BlinkCmpGhostText = { fg = K.fg_dim, italic = true },
				BlinkCmpSignatureHelpBorder = { fg = K.gray3, bg = K.none },

				-- ── Lazy.nvim UI ─────────────────────────────────────────────────
				LazyNormal = { bg = K.none, fg = K.fg },
				LazyButton = { bg = K.surface0, fg = K.fg },
				LazyButtonActive = { bg = K.accent, fg = K.gray1, bold = true },
				LazyH1 = { bg = K.accent, fg = K.gray1, bold = true },

				-- ── Mason ────────────────────────────────────────────────────────
				MasonNormal = { bg = K.none },

				-- ── Treesitter Context ───────────────────────────────────────────
				TreesitterContext = { bg = K.surface0, italic = true },
				TreesitterContextLineNumber = { fg = K.blue, bg = K.surface0 },
				TreesitterContextBottom = { sp = K.gray3, underline = true },
				TreesitterContextSeparator = { fg = K.gray3 },

				-- ── Indent guides ────────────────────────────────────────────────
				MiniIndentscopeSymbol = { fg = K.gray3 },
				IndentBlanklineChar = { fg = K.surface0 },

				-- ── Flash/Leap ───────────────────────────────────────────────────
				FlashLabel = { fg = K.gray1, bg = K.orange, bold = true },
				FlashMatch = { fg = K.blue, bg = K.surface0 },

				-- ── Claude Code ──────────────────────────────────────────────────
				ClaudeCodeBorder = { fg = K.accent, bg = K.none },
				ClaudeCodeTitle = { fg = K.accent, bg = K.none, bold = true },

				-- ── Toggle Terminal ──────────────────────────────────────────────
				ToggleTermBorder = { fg = K.gray3, bg = K.none },

				-- ── Oil.nvim ─────────────────────────────────────────────────────
				OilDir = { fg = K.blue, bold = true },
				OilDirIcon = { fg = K.blue },
				OilFile = { fg = K.fg },
				OilLink = { fg = K.cyan, italic = true },
				OilLinkTarget = { fg = K.cyan },
				OilCopy = { fg = K.orange, bold = true },
				OilMove = { fg = K.yellow, bold = true },
				OilDelete = { fg = K.red, bold = true },
				OilCreate = { fg = K.green, bold = true },

				-- ── nvim-dbee ────────────────────────────────────────────────────
				DbeeNormal = { bg = K.none, fg = K.fg },
				DbeeBorder = { fg = K.accent, bg = K.none },
				DbeeTitle = { fg = K.accent, bg = K.none, bold = true },

				-- ── Kulala HTTP ──────────────────────────────────────────────────
				KulalaNormal = { bg = K.none, fg = K.fg },
				KulalaBorder = { fg = K.accent, bg = K.none },
				KulalaMethodGet = { fg = K.green, bold = true },
				KulalaMethodPost = { fg = K.yellow, bold = true },
				KulalaMethodPut = { fg = K.orange, bold = true },
				KulalaMethodDelete = { fg = K.red, bold = true },
				KulalaMethodPatch = { fg = K.cyan, bold = true },
				KulalaMethodHead = { fg = K.green, bold = true },
				KulalaStatusCodeSuccess = { fg = K.green, bold = true },
				KulalaStatusCodeRedirect = { fg = K.yellow, bold = true },
				KulalaStatusCodeClientError = { fg = K.orange, bold = true },
				KulalaStatusCodeServerError = { fg = K.red, bold = true },
				KulalaURL = { fg = K.blue, underline = true },
				KulalaHeader = { fg = K.cyan },
				KulalaHeaderValue = { fg = K.fg },
				KulalaVariableName = { fg = K.purple, italic = true },
				KulalaVariableValue = { fg = K.orange },
				KulalaComment = { fg = K.comment_, italic = true },
				KulalaInlayHint = { fg = K.fg_dim },

				-- ── RenderMarkdown ───────────────────────────────────────────────
				RenderMarkdownH1 = { fg = K.red, bold = true },
				RenderMarkdownH2 = { fg = K.orange, bold = true },
				RenderMarkdownH3 = { fg = K.yellow, bold = true },
				RenderMarkdownH4 = { fg = K.green, bold = true },
				RenderMarkdownH5 = { fg = K.cyan, bold = true },
				RenderMarkdownH6 = { fg = K.purple, bold = true },
				RenderMarkdownH1Bg = { bg = "#2D1E25" },
				RenderMarkdownH2Bg = { bg = "#2D2619" },
				RenderMarkdownH3Bg = { bg = "#2D2B19" },
				RenderMarkdownH4Bg = { bg = "#1E2D1E" },
				RenderMarkdownH5Bg = { bg = "#1E252D" },
				RenderMarkdownH6Bg = { bg = "#231E2D" },
				RenderMarkdownCode = { bg = K.surface0 },
				RenderMarkdownCodeInline = { bg = K.surface0, fg = K.orange },
				RenderMarkdownBullet = { fg = K.accent },
				RenderMarkdownLink = { fg = K.blue, underline = true },
				RenderMarkdownTodo = { fg = K.yellow, bold = true },
				RenderMarkdownQuote = { fg = K.fg_dim, italic = true },
				RenderMarkdownDash = { fg = K.gray3 },
				RenderMarkdownTableHead = { fg = K.accent, bold = true },
				RenderMarkdownTableRow = { fg = K.fg },
				RenderMarkdownTableFill = { fg = K.gray3 },

				-- ── Mini.files ───────────────────────────────────────────────────
				MiniFilesNormal = { bg = K.none, fg = K.fg },
				MiniFilesBorder = { fg = K.gray3, bg = K.none },
				MiniFilesTitle = { fg = K.fg_dim, bg = K.none },
				MiniFilesTitleFocused = { fg = K.accent, bg = K.none, bold = true },
				MiniFilesDirectory = { fg = K.blue, bold = true },
				MiniFilesCursorLine = { bg = K.surface0 },

				-- ── Mini.icons ───────────────────────────────────────────────────
				MiniIconsBlue = { fg = K.blue },
				MiniIconsCyan = { fg = K.cyan },
				MiniIconsGreen = { fg = K.green },
				MiniIconsYellow = { fg = K.yellow },
				MiniIconsOrange = { fg = K.orange },
				MiniIconsPurple = { fg = K.purple },
				MiniIconsRed = { fg = K.red },
				MiniIconsAzure = { fg = K.blue },
				MiniIconsGrey = { fg = K.fg_dim },

				-- ── GitSigns ─────────────────────────────────────────────────────
				GitSignsAdd = { fg = K.green },
				GitSignsChange = { fg = K.yellow },
				GitSignsDelete = { fg = K.red },
				GitSignsAddNr = { fg = K.green },
				GitSignsChangeNr = { fg = K.yellow },
				GitSignsDeleteNr = { fg = K.red },
				GitSignsAddLn = { bg = K.diff_add },
				GitSignsChangeLn = { bg = K.diff_chg },

				-- ── Trouble.nvim ─────────────────────────────────────────────────
				TroubleNormal = { bg = K.none, fg = K.fg },
				TroubleText = { fg = K.fg },
				TroubleCount = { fg = K.yellow, bold = true },
				TroubleIndent = { fg = K.gray3 },
				TroubleLocation = { fg = K.fg_dim },
				TroubleFile = { fg = K.blue, bold = true },
				TroubleSource = { fg = K.fg_dim },

				-- ── Todo-comments ────────────────────────────────────────────────
				TodoBgFIX = { fg = K.gray1, bg = K.red, bold = true },
				TodoBgHACK = { fg = K.gray1, bg = K.yellow, bold = true },
				TodoBgNOTE = { fg = K.gray1, bg = K.green, bold = true },
				TodoBgPERF = { fg = K.gray1, bg = K.cyan, bold = true },
				TodoBgTEST = { fg = K.gray1, bg = K.purple, bold = true },
				TodoBgTODO = { fg = K.gray1, bg = K.accent, bold = true },
				TodoBgWARN = { fg = K.gray1, bg = K.orange, bold = true },
				TodoFgFIX = { fg = K.red },
				TodoFgHACK = { fg = K.yellow },
				TodoFgNOTE = { fg = K.green },
				TodoFgPERF = { fg = K.cyan },
				TodoFgTEST = { fg = K.purple },
				TodoFgTODO = { fg = K.accent },
				TodoFgWARN = { fg = K.orange },
				TodoSignFIX = { fg = K.red },
				TodoSignHACK = { fg = K.yellow },
				TodoSignNOTE = { fg = K.green },
				TodoSignPERF = { fg = K.cyan },
				TodoSignTEST = { fg = K.purple },
				TodoSignTODO = { fg = K.accent },
				TodoSignWARN = { fg = K.orange },

				-- ── Snacks Notify ─────────────────────────────────────────────────
				SnacksNotifyERROR = { fg = K.red, bg = K.none },
				SnacksNotifyWARN = { fg = K.yellow, bg = K.none },
				SnacksNotifyINFO = { fg = K.cyan, bg = K.none },
				SnacksNotifyDEBUG = { fg = K.fg_dim, bg = K.none },
				SnacksNotifyBorderERROR = { fg = K.red },
				SnacksNotifyBorderWARN = { fg = K.yellow },
				SnacksNotifyBorderINFO = { fg = K.accent },
				SnacksNotifyBorderDEBUG = { fg = K.fg_dim },
				SnacksNotifyTitleERROR = { fg = K.red, bold = true },
				SnacksNotifyTitleWARN = { fg = K.yellow, bold = true },
				SnacksNotifyTitleINFO = { fg = K.accent, bold = true },
				SnacksNotifyTitleDEBUG = { fg = K.fg_dim, bold = true },
				SnacksNotifyIconERROR = { fg = K.red },
				SnacksNotifyIconWARN = { fg = K.yellow },
				SnacksNotifyIconINFO = { fg = K.accent },
				SnacksNotifyIconDEBUG = { fg = K.fg_dim },

				-- ── TabLine ──────────────────────────────────────────────────────
				TabLine = { fg = K.fg_muted, bg = K.none },
				TabLineFill = { fg = K.none, bg = K.none },
				TabLineSel = { fg = K.accent, bg = K.surface0, bold = true },

				-- ── Quickfix / Help ──────────────────────────────────────────────
				qfFileName = { fg = K.blue },
				qfLineNr = { fg = K.accent },
				qfError = { fg = K.red },
				helpHyperTextJump = { fg = K.blue, underline = true },
				helpHeadline = { fg = K.accent, bold = true },
				helpSectionDelim = { fg = K.gray3 },
			},
		},
	},

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

			-- Dim inactivo: 30% para compensar que NormalNC bg=mantle ya da distinción
			-- NormalNC override abajo hace el trabajo principal; dim_inactive refuerza fg
			dim_inactive = {
				enabled = true,
				shade = "dark",
				percentage = 0.30,
			},

			styles = {
				comments = { "italic" },
				conditionals = { "italic" },
				functions = { "bold" },
				keywords = { "italic" },
				strings = {},
				variables = {},
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
						NormalFloat = { bg = t, fg = colors.text },
						FloatBorder = { fg = colors.surface1, bg = t },
						FloatTitle = { fg = colors.mauve, bg = t, bold = true },

						-- ── Cursor line: sutil sobre transparencia ──────────────────────
						CursorLine = { bg = colors.surface0 },
						CursorLineNr = { fg = colors.lavender, bold = true },
						-- overlay0 (#6c7086) = 4.1:1 contraste vs crust: legible sin competir con código
						-- surface1 (#45475a) = ~2.5:1 → insuficiente (principio fg_dim de Kanagawa)
						LineNr = { fg = colors.overlay0 },

						-- ── Popups y menús: semi-transparente, elegante ─────────────────
						Pmenu = { bg = colors.mantle, fg = colors.text },
						PmenuSel = { bg = "#3a2d52", fg = colors.text, bold = true },  -- mauve-tinted (Kanagawa accent principle)
						PmenuThumb = { bg = colors.surface1 },

						-- ── Neo-tree: full transparent, integrado con terminal ──────────
						NeoTreeNormal = { bg = t, fg = colors.text },
						NeoTreeNormalNC = { bg = t, fg = colors.subtext0 },
						NeoTreeWinSeparator = { fg = colors.mantle, bg = t },
						NeoTreeEndOfBuffer = { bg = t, fg = t },
						NeoTreeCursorLine = { bg = colors.surface1 },
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
						-- Archivo activo: brilla en mauve para indicar que esta abierto
						NeoTreeFileNameOpened = { fg = colors.mauve, bold = true },

						-- ── Status line: transparente (lualine catppuccin integration lo maneja) ─
						StatusLine = { bg = t, fg = colors.text },
						-- overlay0 para texto de ventana inactiva: 4.1:1 contraste, legible
						StatusLineNC = { bg = t, fg = colors.overlay0 },

						-- ── Which-key: transparente ─────────────────────────────────────
						WhichKeyFloat = { bg = t },
						WhichKeyBorder = { fg = colors.surface1, bg = t },

						-- ── Claude Code: borde mauve premium ────────────────────────────
						ClaudeCodeBorder = { fg = colors.mauve, bg = t },
						ClaudeCodeTitle = { fg = colors.mauve, bg = t, bold = true },

						-- ── Terminal integrado ──────────────────────────────────────────
						ToggleTermBorder = { fg = colors.surface1, bg = t },

						-- ── Noice ───────────────────────────────────────────────────────
						NoiceCmdlinePopupBorder = { fg = colors.surface1, bg = t },
						NoiceCmdlineIcon = { fg = colors.mauve },

						-- ── Telescope/Picker: full transparent ──────────────────────────
						TelescopeNormal = { bg = t },
						TelescopeBorder = { fg = colors.surface1, bg = t },
						TelescopePromptNormal = { bg = t },
						TelescopePromptBorder = { fg = colors.mauve, bg = t },
						TelescopePromptTitle = { fg = colors.mauve, bg = t, bold = true },
						TelescopeResultsNormal = { bg = t },
						TelescopeResultsBorder = { fg = colors.surface1, bg = t },
						TelescopePreviewNormal = { bg = t },
						TelescopePreviewBorder = { fg = colors.surface1, bg = t },
						TelescopeSelection = { bg = colors.surface0, fg = colors.text },

						-- ── Snacks picker ───────────────────────────────────────────────
						SnacksPickerBorder = { fg = colors.surface1, bg = t },

						-- ── Indent guides: muy discretos ────────────────────────────────
						MiniIndentscopeSymbol = { fg = colors.surface1 },
						IndentBlanklineChar = { fg = colors.surface0 },

						-- ── Visual selection: dark mauve blend — consistente con WezTerm selection_bg ──
						-- #413956 = 20% mauve + 80% base — visible, no agresivo, tinte temático
						Visual = { bg = "#413956" },
						VisualNOS = { bg = "#413956" },

						-- ── Search highlights ───────────────────────────────────────────
						Search = { bg = colors.surface1, fg = colors.text },
						IncSearch = { bg = colors.peach, fg = colors.base, bold = true },
						CurSearch = { bg = colors.mauve, fg = colors.base, bold = true },

						-- ── Winbar / incline: transparente ──────────────────────────────
						WinBar = { bg = t, fg = colors.text },
						WinBarNC = { bg = t, fg = colors.overlay0 },

						-- ── SignColumn: transparente ─────────────────────────────────────
						SignColumn = { bg = t },
						FoldColumn = { fg = colors.surface1, bg = t },

						-- ── Snacks terminal/float: transparente ─────────────────────────
						SnacksNormal = { bg = t },
						SnacksBorder = { fg = colors.mauve, bg = t },

						-- ── Database (nvim-dbee) ────────────────────────────────────────
						DbeeNormal = { bg = t, fg = colors.text },
						DbeeBorder = { fg = colors.mauve, bg = t },
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
						LspInfoBorder = { fg = colors.surface1, bg = t },

						-- ── LSP Inlay Hints: overlay1 italic — secundarios, badge sobre mantle ──
						-- overlay1 (#7f849c) ≈ 5:1 contraste: más legible que overlay0 sin competir
						LspInlayHint = { fg = colors.overlay1, bg = colors.mantle, italic = true },

						-- ── C# Semantic Tokens & Treesitter (Diferenciación Visual Élite basada en AST) ────────────
						-- Estas reglas dominan visualmente el código basándose en el motor sintáctico y semántico,
						-- eliminando la necesidad de subrayados falsos. El código "habla" por sus colores.

						-- LSP Semantics
						["@lsp.type.interface"] = { fg = colors.yellow, italic = true },
						["@lsp.type.class"] = { fg = colors.yellow, bold = true },
						["@lsp.type.method"] = { fg = colors.blue, bold = true },
						["@lsp.type.property"] = { fg = colors.teal },
						["@lsp.type.parameter"] = { fg = colors.maroon, italic = true },
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
						LazyNormal = { bg = t, fg = colors.text },
						LazyButton = { bg = colors.surface0, fg = colors.text },
						LazyButtonActive = { bg = colors.mauve, fg = colors.base, bold = true },
						LazyH1 = { bg = colors.mauve, fg = colors.base, bold = true },

						-- ── Mason ───────────────────────────────────────────────────────
						MasonNormal = { bg = t },

						-- ── Treesitter Context: cabecera sticky (función/clase actual) ───
						-- Sin esto el contexto es casi invisible sobre fondo transparente
						TreesitterContext = { bg = colors.surface0, italic = true },
						TreesitterContextLineNumber = { fg = colors.lavender, bg = colors.surface0 },
						TreesitterContextBottom = { sp = colors.surface1, underline = true },
						TreesitterContextSeparator = { fg = colors.surface1 },

						-- ── Blink.cmp: completion menu unificado ────────────────────────
						BlinkCmpMenuBorder = { fg = colors.surface1, bg = t },
						BlinkCmpDocBorder = { fg = colors.surface1, bg = t },
						BlinkCmpDocSeparatorLine = { fg = colors.surface1 },
						BlinkCmpGhostText = { fg = colors.overlay0, italic = true },
						BlinkCmpSignatureHelpBorder = { fg = colors.surface1, bg = t },

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
						KulalaNormal = { bg = t, fg = colors.text },
						KulalaBorder = { fg = colors.mauve, bg = t },
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
						RenderMarkdownH1 = { fg = colors.red,     bold = true },
						RenderMarkdownH2 = { fg = colors.peach,   bold = true },
						RenderMarkdownH3 = { fg = colors.yellow,  bold = true },
						RenderMarkdownH4 = { fg = colors.green,   bold = true },
						RenderMarkdownH5 = { fg = colors.teal,    bold = true },
						RenderMarkdownH6 = { fg = colors.mauve,   bold = true },
						RenderMarkdownH1Bg = { bg = "#2D1B28" },  -- red/mantle tint
						RenderMarkdownH2Bg = { bg = "#2D2218" },  -- peach/mantle tint
						RenderMarkdownH3Bg = { bg = "#2D2B18" },  -- yellow/mantle tint
						RenderMarkdownH4Bg = { bg = "#1C2D1C" },  -- green/mantle tint
						RenderMarkdownH5Bg = { bg = "#1C272D" },  -- teal/mantle tint
						RenderMarkdownH6Bg = { bg = "#261C2D" },  -- mauve/mantle tint
						RenderMarkdownCode = { bg = colors.mantle },
						RenderMarkdownCodeInline = { bg = colors.surface0, fg = colors.peach },
						RenderMarkdownBullet = { fg = colors.mauve },
						RenderMarkdownLink   = { fg = colors.blue, underline = true },
						RenderMarkdownTodo   = { fg = colors.yellow, bold = true },
						RenderMarkdownQuote  = { fg = colors.overlay0, italic = true },
						RenderMarkdownDash   = { fg = colors.surface1 },
						RenderMarkdownTableHead = { fg = colors.mauve, bold = true },
						RenderMarkdownTableRow  = { fg = colors.text },
						RenderMarkdownTableFill = { fg = colors.surface1 },
						
						-- u2500u2500 MiniFiles: file explorer flotante u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500u2500
						MiniFilesNormal       = { bg = t, fg = colors.text },
						MiniFilesBorder       = { fg = colors.surface1, bg = t },
						MiniFilesTitle        = { fg = colors.overlay1, bg = t },
						MiniFilesTitleFocused = { fg = colors.mauve, bg = t, bold = true },
						MiniFilesDirectory    = { fg = colors.blue, bold = true },
						MiniFilesCursorLine   = { bg = colors.surface0 },
						-- ── Treesitter: jerárquía de color AST-aware (Kanagawa principle) ────────────────────
						-- Kanagawa pioneeró strict semantic lanes: cada rol visual = UN color único.
						-- Aquí aplicamos esa disciplina sobre la paleta Catppuccin Mocha.

						-- Variables
						["@variable"]              = { fg = colors.text },
						["@variable.builtin"]      = { fg = colors.mauve },           -- self, this, super
						["@variable.parameter"]    = { fg = colors.maroon, italic = true }, -- parámetros de fn
						["@variable.member"]       = { fg = colors.teal },            -- fields de struct/object

						-- Funciones
						["@function"]              = { fg = colors.blue, bold = true },
						["@function.call"]         = { fg = colors.blue },
						["@function.builtin"]      = { fg = colors.peach },           -- print, len, range
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

						-- Constantes y literales numéricos
						["@constant"]              = { fg = colors.peach },
						["@constant.builtin"]      = { fg = colors.peach, bold = true }, -- nil, true, false, None
						["@constant.macro"]        = { fg = colors.mauve },           -- #define macros
						["@number"]                = { fg = colors.peach },
						["@number.float"]          = { fg = colors.peach },
						["@boolean"]               = { fg = colors.peach, bold = true },

						-- Strings: diferenciación interna crítica (principio Kanagawa)
						["@string"]                = { fg = colors.green },
						["@string.escape"]         = { fg = colors.pink },            -- \n \t \\ escapes resaltados
						["@string.regexp"]         = { fg = colors.peach },           -- regex patterns
						["@string.special"]        = { fg = colors.pink },            -- format strings %s, {}

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

	-- ─── Sonokai (Monokai Pro / Sublime Text 3 ADN) ─────────────────────────────
	{
		"sainnhe/sonokai",
		priority = 1000,
		lazy = true, -- catppuccin es default; sonokai carga solo al :colorscheme sonokai
		init = function()
			vim.g.sonokai_style = "atlantis"
			vim.g.sonokai_enable_italic = 1
			vim.g.sonokai_transparent_background = 2 -- 2 = full (bg + floats)
			vim.g.sonokai_dim_inactive_windows = 1
			vim.g.sonokai_diagnostic_virtual_text = "grey"
			vim.g.sonokai_current_word = "grey background" -- espacio, NO guión bajo
			vim.g.sonokai_spell_foreground = "colored" -- spell check coloreado
		end,
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
		opts = { colorscheme = "catppuccin" },
	},
}
