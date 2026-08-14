local M = {}

local theme = require("themes.matugen")
local c = theme.base_30

M.base46 = {
  theme = "matugen",
  transparency = true,
}

M.ui = {
  statusline = {
    separator_style = {
      left = "",
      right = "",
    },
  },
  hl_override = {
    St_NormalMode = { bg = c.sun, fg = c.dark_purple, bold = true },
    St_NormalModeSep = { fg = c.sun, bg = c.black },
    St_InsertMode = { bg = c.sun, fg = c.dark_purple, bold = true },
    St_InsertModeSep = { fg = c.sun, bg = c.black },
    St_VisualMode = { bg = c.sun, fg = c.dark_purple, bold = true },
    St_VisualModeSep = { fg = c.sun, bg = c.black },
    St_ReplaceMode = { bg = c.red, fg = c.baby_pink, bold = true },
    St_ReplaceModeSep = { fg = c.red, bg = c.black },
    St_CommandMode = { bg = c.sun, fg = c.dark_purple, bold = true },
    St_CommandModeSep = { fg = c.sun, bg = c.black },
    St_TerminalMode = { bg = c.sun, fg = c.dark_purple, bold = true },
    St_TerminalModeSep = { fg = c.sun, bg = c.black },
    St_file = { bg = c.black2, fg = c.white },
    St_file_sep = { fg = c.black2, bg = c.black },
    St_gitIcons = { bg = c.black2, fg = c.sun },
    St_LspMsg = { bg = c.black2, fg = c.white },
    St_Lsp = { bg = c.black2, fg = c.white },
    St_diagnostics = { bg = c.black2, fg = c.grey_fg2 },
    St_cwd_sep = { fg = c.black2, bg = c.black },
    St_cwd_icon = { bg = c.black2, fg = c.sun },
    St_cwd_text = { bg = c.black2, fg = c.white },
    St_pos_sep = { fg = c.sun, bg = c.black },
    St_pos_icon = { bg = c.sun, fg = c.dark_purple },
    St_pos_text = { bg = c.sun, fg = c.dark_purple, bold = true },
    ST_EmptySpace = { bg = c.black },
  },
}

return M
