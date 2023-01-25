let
    git-zsh-powerlevel10k = builtins.fetchGit {
        url = "git@github.com:romkatv/powerlevel10k.git";
        ref = "master";
        rev = "0adbc1415bf1bad46a7fd111b39640d995294dad";
    };
    git-zsh-defer = builtins.fetchGit {
        url = "git@github.com:romkatv/zsh-defer.git";
        ref = "master";
        rev = "57a6650ff262f577278275ddf11139673e01e471";
    };
    git-zsh-autosuggestions = builtins.fetchGit {
        url = "git@github.com:zsh-users/zsh-autosuggestions";
        ref = "master";
        rev = "a411ef3e0992d4839f0732ebeb9823024afaaaa8";
    };
    git-zsh-fast-syntax-highlighting = builtins.fetchGit {
        url = "git@github.com:zdharma-continuum/fast-syntax-highlighting";
        ref = "master";
        rev = "7c390ee3bfa8069b8519582399e0a67444e6ea61";
    };
in ''
    source '${git-zsh-powerlevel10k}/powerlevel10k.zsh-theme';
    source '${git-zsh-defer}/zsh-defer.plugin.zsh';
    source '${git-zsh-autosuggestions}/zsh-autosuggestions.plugin.zsh';
    source '${git-zsh-fast-syntax-highlighting}/fast-syntax-highlighting.plugin.zsh';                
''