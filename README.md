# Awesome Neovim Config

My personal Neovim configuration based on [LazyVim](https://www.lazyvim.org/).

## Features

- 🚀 Fast startup with lazy loading
- 🎨 Beautiful colorschemes (Catppuccin, Tokyo Night)
- 📦 Comprehensive plugin setup
- 🔧 Customized keymaps and options
- 🤖 AI-powered coding with CodeCompanion
- 📚 And much more!

## Installation

### Prerequisites

- Neovim >= 0.9.0
- Git
- A [Nerd Font](https://www.nerdfonts.com/) (optional, but recommended)

### Quick Start

**Important:** I recommend **forking this repository** rather than cloning it directly. This config is meant to be a starting point for building your own personalized setup, not something to rely on exclusively.

```bash
# 1. Fork this repo on GitHub (click the "Fork" button)

# 2. Backup your existing config (if any)
mv ~/.config/nvim ~/.config/nvim.backup

# 3. Clone YOUR fork (replace YOUR-USERNAME with your GitHub username)
git clone https://github.com/YOUR-USERNAME/awesome-nvim-config.git ~/.config/nvim

# 4. Start Neovim - plugins will install automatically
nvim
```

### Why Fork?

- **Personalization**: Neovim configs are highly personal. What works for me might not work for you.
- **Control**: You'll have full control over your configuration and can customize it freely.
- **Updates**: You can still pull updates from my repo when you want, but on your own terms.
- **Learning**: Forking encourages you to understand and modify the config rather than blindly using someone else's setup.

### Syncing Updates from Upstream

If you've forked the repo and want to pull in my latest changes:

```bash
# Add the original repo as upstream (one-time setup)
cd ~/.config/nvim
git remote add upstream https://github.com/fredguile/awesome-nvim-config.git

# Pull and merge updates when desired
git fetch upstream
git merge upstream/master
```

## Structure

```
~/.config/nvim/
├── init.lua              # Entry point
├── lua/
│   ├── config/          # Core configuration
│   │   ├── keymaps.lua  # Key mappings
│   │   ├── lazy.lua     # Lazy.nvim setup
│   │   └── options.lua  # Neovim options
│   └── plugins/         # Plugin configurations
└── bin/                 # Helper scripts
```

## Customization

This configuration is **designed to be customized**! Here's how:

- **Add/remove plugins**: Edit files in `lua/plugins/`
- **Modify keymaps**: Update `lua/config/keymaps.lua`
- **Adjust settings**: Change options in `lua/config/options.lua`
- **Try different colorschemes**: Check out the colorscheme plugins

Feel free to delete anything you don't need and add what you want!

## Credits

- Based on [LazyVim](https://www.lazyvim.org/)
- Inspired by the amazing Neovim community

## License

MIT License - feel free to use and modify!
