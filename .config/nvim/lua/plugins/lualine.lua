return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    opts.options = {
      theme = "gruvbox",
      component_separators = "",
      section_separators = "",
      globalstatus = true,
    }
    -- Bottom bar: just mode hint + diagnostics + location
    opts.sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {
        { "mode", fmt = function(s) return s:sub(1, 1) end, color = { gui = "bold" } },
        { "diagnostics" },
      },
      lualine_x = {
        { "branch" },
        { "location" },
      },
      lualine_y = {},
      lualine_z = {},
    }
    opts.inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    }
    -- Header line (winbar) — nano-style buffer name at top
    opts.winbar = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {
        { "filename", path = 1, color = { gui = "bold" } },
        { "modified", color = { gui = "bold" } },
      },
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    }
    opts.inactive_winbar = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {
        { "filename", path = 1 },
      },
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    }
  end,
}
