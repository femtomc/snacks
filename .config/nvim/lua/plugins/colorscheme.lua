return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      contrast = "hard",
      overrides = {
        SignColumn = { bg = "NONE" },
        FoldColumn = { bg = "NONE", fg = "#3c3836" },
        GruvboxRedSign = { bg = "NONE" },
        GruvboxGreenSign = { bg = "NONE" },
        GruvboxYellowSign = { bg = "NONE" },
        GruvboxBlueSign = { bg = "NONE" },
        GruvboxPurpleSign = { bg = "NONE" },
        GruvboxAquaSign = { bg = "NONE" },
        GruvboxOrangeSign = { bg = "NONE" },
        WinBar = { bg = "NONE", fg = "#ebdbb2", bold = true },
        WinBarNC = { bg = "NONE", fg = "#928374" },
        WinSeparator = { bg = "NONE", fg = "#3c3836" },
        FloatBorder = { bg = "NONE", fg = "#665c54" },
        NormalFloat = { bg = "#1d2021" },
        WhichKeyFloat = { bg = "#1d2021" },
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
