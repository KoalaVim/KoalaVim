<img src="https://github.com/KoalaVim/KoalaVim/assets/4954051/bfdd2db9-1957-4a7f-8ada-f561f2ec5860" align="right" width="350" />

# KoalaVim


Extendable preconfigured configuration for Neovim powered by [lazy.nvim](https://github.com/folke/lazy.nvim).

<br><br><br><br><br><br>

---

## 🚧 **This configuration is in an early alpha stage** 🚧

# Installation
* Make a backup for your current nvim configuration 
    ```bash
    mv ~/.config/nvim ~/.config/nvim.bak
    mv ~/.local/share/nvim ~/.local/share/nvim.bak
    ```
* Optional: copy [KoalaConfig.template](https://github.com/KoalaVim/KoalaConfig.template) (Use this template)
* Clone your config or the template
    ```bash
    git clone https://github.com/<your_github_username>/KoalaConfig ~/.config/nvim

    ### Clone the template if you didn't make a copy
    git clone https://github.com/KoalaVim/KoalaConfig.template ~/.config/nvim
    # Remove .git if you want to push it as yours later
    rm -rf ~/.config/nvim/.git
    ```

Note: currently KoalaVim install all treesitter's parsers so the first launch might be laggy. It's highly recommended to restart nvim after treesitter's finish installs all the parsers.

---

Requirements:
- [Nerd Font](https://www.nerdfonts.com/)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fd](https://github.com/sharkdp/fd)
- [fzf](https://github.com/junegunn/fzf)
- Terminal with true color and undercurl support:
    - [kitty](https://github.com/kovidgoyal/kitty)
    - [wezterm](https://github.com/wez/wezterm)
    - [alacritty](https://github.com/alacritty/alacritty)
    - [iterm2](https://iterm2.com/)

TODO:
- cleanup root directory
- fire-nvim
- nvlog ()
- whichkey
- checkhealth
- Navigate to KoalaVim's plugins directory
- Move to personal:
    - keymaps
    - autocmds
    - usercmds
