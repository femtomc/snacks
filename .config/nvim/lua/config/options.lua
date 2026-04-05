local opt = vim.opt

opt.wrap = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = "no"
opt.cursorline = false
opt.showmode = false
opt.ruler = false
opt.laststatus = 3

-- Breathing room
opt.foldcolumn = "1"

-- Soft splits and clean chrome
opt.fillchars = {
  eob = " ",
  vert = " ",
  horiz = "─",
  horizup = "─",
  horizdown = "─",
  vertleft = " ",
  vertright = " ",
  verthoriz = " ",
  fold = " ",
  foldsep = " ",
}

-- Thin line cursor, no blink
opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,a:blinkon0"

-- Floating window style
opt.pumblend = 10
opt.winblend = 10

-- OSC 52 clipboard: yank reaches local clipboard over SSH/Zellij
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}
opt.clipboard = "unnamedplus"
