-- Global options
vim.o.background = 'dark'
vim.o.termguicolors = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hidden = true
vim.o.incsearch = true
vim.o.scrolloff = 7
vim.o.mouse = 'a'
-- vim.o.cmdheight = 2
vim.o.updatetime = 100
vim.o.undodir = os.getenv("HOME") .. '/.cache/vim/undo';


-- Window options
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.signcolumn = 'number'
vim.wo.wrap = false
vim.wo.cursorline = true


-- Buffer options
vim.o.tabstop = 2
vim.bo.tabstop = 2
vim.o.softtabstop = 2
vim.bo.softtabstop = 2
vim.o.shiftwidth = 2
vim.bo.shiftwidth = 2
vim.o.autoindent = true
vim.bo.autoindent = true
vim.o.expandtab = true
vim.bo.expandtab = true
vim.o.swapfile = false
vim.bo.swapfile = false
vim.o.undofile = true
vim.bo.undofile = true


vim.g.mapleader = ' '
vim.b.mapleader = ' '

-- Show extra whitespaces
vim.wo.list = true
vim.o.listchars = 'tab:┆·,trail:·,precedes:,extends:'


-- NerdCommenter
vim.g.NERDSpaceDelims = 1
vim.g.NERDCreateDefaultMappings = 0
vim.g.NERDDefaultAlign = 'left'

-- GitGutter
vim.g.gitgutter_override_sign_column_highlight = 0
vim.g.gitgutter_sign_added                     = '+'
vim.g.gitgutter_sign_modified                  = '±'
vim.g.gitgutter_sign_removed                   = '-'
vim.g.gitgutter_sign_removed_first_line        = '×'
vim.g.gitgutter_sign_modified_removed          = '×'
