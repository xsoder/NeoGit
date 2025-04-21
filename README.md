# NeoGit

A Git interface for Neovim, inspired by Magit for Emacs.

## Overview

NeoGit brings the power and convenience of Magit to Neovim. It provides an intuitive interface for performing Git operations directly from your editor, with a focus on keyboard-driven workflows and clear visual feedback.

## Features

- Interactive status buffer with detailed file information
- Stage/unstage files or individual hunks
- Commit changes with a dedicated message editor
- View commit history and diffs
- Branch management (create, checkout, merge)
- Remote operations (fetch, pull, push)
- Stash management
- Intuitive key bindings consistent with Neovim philosophy

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'xsoder/NeoGit',
  requires = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim', -- Optional, for enhanced file picking
  }
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim' " Optional
Plug 'xcoder/neogit'
```

## Usage

### Basic Commands

- `:NeoGit` - Open the main NeoGit status buffer
- `:NeoGitCommit` - Start a commit
- `:NeoGitPush` - Push to remote
- `:NeoGitPull` - Pull from remote
- `:NeoGitLog` - Show commit history

### Recommended Mappings

Add to your init.lua:

```lua
vim.api.nvim_set_keymap('n', '<leader>gs', ':NeoGit<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gc', ':NeoGitCommit<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gp', ':NeoGitPush<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>gl', ':NeoGitLog<CR>', { noremap = true, silent = true })
```

### Status Buffer Keybindings

In the NeoGit status buffer:

- `s` - Stage file/hunk under cursor
- `u` - Unstage file/hunk under cursor
- `c` - Commit staged changes
- `p` - Push to remote
- `f` - Fetch from remote
- `r` - Pull (rebase) from remote
- `b` - Branch operations menu
- `z` - Stash operations menu
- `?` - Show help
- `q` - Close NeoGit buffer

### Harpoon-like Buffer Pinning

NeoGit supports Harpoon-style buffer pinning and movement in the status buffer:

- `P` — Pin the current buffer (adds to the pinned list)
- `R` — Repin the current buffer (move to top of pinned list)
- `K` — Move the current pinned buffer up in the list
- `J` — Move the current pinned buffer down in the list

Pinned buffers can be viewed in the help menu (`?`). This allows you to quickly mark and reorder important NeoGit buffers for fast navigation, similar to [ThePrimeagen/harpoon](https://github.com/ThePrimeagen/harpoon).

## Configuration

NeoGit can be configured in your init.lua:

```lua
require('neogit').setup({
  -- Default values
  disable_signs = false,
  disable_hint = false,
  disable_context_highlighting = false,
  status = {
    recent_commit_count = 10,
  },
  auto_refresh = true,
  integrations = {
    telescope = true,
    diffview = false,
  },
  sections = {
    -- Configuration for different sections in the status buffer
    untracked = {
      folded = false,
    },
    unstaged = {
      folded = false,
    },
    staged = {
      folded = false,
    },
    stashes = {
      folded = true,
    },
    unpulled = {
      folded = true,
    },
    unmerged = {
      folded = false,
    },
    recent = {
      folded = true,
    },
  },
})
```

## Requirements

- Neovim >= 0.7.0
- Git (tested with 2.30+)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Optional: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced picking

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
