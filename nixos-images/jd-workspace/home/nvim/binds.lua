local opts = {noremap = true, silent = true}
local mapOpts = {noremap = false, silent = true}

-- Disable that annoying thing
vim.api.nvim_set_keymap('n', 'Q', '<nop>', opts)

-- NvimTree
vim.api.nvim_set_keymap('n', '<C-n>', ':Neotree toggle<CR>', opts)

-- Window movement
vim.api.nvim_set_keymap('n', '<C-j>', '<C-w>j', opts)
vim.api.nvim_set_keymap('n', '<C-k>', '<C-w>k', opts)
vim.api.nvim_set_keymap('n', '<C-h>', '<C-w>h', opts)
vim.api.nvim_set_keymap('n', '<C-l>', '<C-w>l', opts)


-- navigation
vim.api.nvim_set_keymap('n', '<Leader><Leader>', '<C-^>', opts)
-- disable highlight
vim.api.nvim_set_keymap('n', '<Leader>sh', ':noh<CR>', opts)

-- Clipboard
if vim.fn.has('nvim') == 1 then
  vim.api.nvim_set_keymap('v', '<C-c>', '"+y', opts)
  vim.api.nvim_set_keymap('v', '<C-x>', '"+d', opts)
  vim.api.nvim_set_keymap('v', '<C-v>', '"+p', opts)
  vim.api.nvim_set_keymap('i', '<C-v>', '<C-r><C-o>+', opts)
end

-- Files
vim.api.nvim_set_keymap('n', '<C-p>', ':Telescope find_files<CR>', opts)
vim.api.nvim_set_keymap('n', '<C-g>', ':Telescope git_files<CR>', opts)
vim.api.nvim_set_keymap('n', '<Leader>l', ':Telescope buffers<CR>', opts)
vim.api.nvim_set_keymap('n', '<Leader>st', ':Telescope live_grep<CR>', opts)

-- NerdCommenter
vim.api.nvim_set_keymap('n', '<Leader>/', ":call nerdcommenter#Comment('Toggle', 'Toggle')<CR>", mapOpts)
vim.api.nvim_set_keymap('v', '<Leader>/', ":call nerdcommenter#Comment('Toggle', 'Toggle')<CR>gv", mapOpts)
