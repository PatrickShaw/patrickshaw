# zshrc-config

# Font
https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/SourceCodePro/Regular/complete

https://github.com/ryanoasis/nerd-fonts/tree/gh-pages
https://www.nerdfonts.com/font-downloads

# git diff

See: https://github.com/dandavison/delta#configuration
```ini
[pager]
    diff = delta
    log = delta
    reflog = delta
    show = delta

[delta]
    plus-style = "syntax #012800"
    minus-style = "syntax #340001"
    syntax-theme = Monokai Extended
    navigate = true

[interactive]
    diffFilter = delta --color-only
```