if [[ "$0" =~ "/zsh$" ]]; then
    local this='boot/setup/oh-my-zsh.sh'
else
    local this="$(fs.ash.path "$0")"
fi

OH_MY_ZSH="$HOME/.oh-my-zsh"
OH_MY_ZSH_PLUGINS="$OH_MY_ZSH/custom/plugins"
OH_MY_ZSH_BOOTSTAP='https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh'
OH_MY_ZSH_PACKAGES=(
    # "https://github.com/alecthomas/ondir.git $OH_MY_ZSH_PLUGINS/ondir"
    # "https://github.com/MestreLion/git-tools.git $OH_MY_ZSH_PLUGINS/git-tools"
    "https://github.com/chrissicool/zsh-256color $OH_MY_ZSH_PLUGINS/zsh-256color"
    "https://github.com/facebook/PathPicker.git $OH_MY_ZSH_PLUGINS/fpp"
    "https://github.com/hlissner/zsh-autopair.git $OH_MY_ZSH_PLUGINS/zsh-autopair"
    "https://github.com/leophys/zsh-plugin-fzf-finder.git $OH_MY_ZSH_PLUGINS/zsh-plugin-fzf-finder"
    "https://github.com/mafredri/zsh-async.git $OH_MY_ZSH_PLUGINS/zsh-async"
    "https://github.com/mollifier/anyframe.git $OH_MY_ZSH_PLUGINS/anyframe"
    "https://github.com/seletskiy/zsh-fuzzy-search-and-edit.git $OH_MY_ZSH_PLUGINS/zsh-fuzzy-search-and-edit"
    "https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $OH_MY_ZSH_PLUGINS/autoupdate"
    "https://github.com/trapd00r/zsh-syntax-highlighting-filetypes.git $OH_MY_ZSH_PLUGINS/zsh-syntax-highlighting-filetypes"
    "https://github.com/wfxr/forgit.git $OH_MY_ZSH_PLUGINS/forgit"
    "https://github.com/zdharma-continuum/history-search-multi-word.git $OH_MY_ZSH_PLUGINS/history-search-multi-word"
    "https://github.com/zlsun/solarized-man.git $OH_MY_ZSH_PLUGINS/solarized-man"
    "https://github.com/zsh-users/zsh-autosuggestions $OH_MY_ZSH_PLUGINS/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-completions $OH_MY_ZSH_PLUGINS/zsh-completions"
    "https://github.com/zsh-users/zsh-syntax-highlighting.git $OH_MY_ZSH_PLUGINS/zsh-syntax-highlighting"
)


if [ -z "$ZSH_VERSION" ]; then
    cmd="`$(which ps) -p\$\$ -ocomm=`"

    if [ ! -x "`which zsh`" ]; then
        printf " ** halt ($0): I was made for zsh, not for $cmd; please, install zsh\n" >&2
    else
        printf " ** halt ($0): I was made for zsh, not for $cmd; please change default shell: \"sudo chsh -s `which zsh` $USER\" and run again\n" >&2
    fi

else
    zmodload zsh/datetime

    function deploy.ohmyzsh() {
        if [ -z "$ASH_HTTP" ]; then
            printf " ** halt ($0): HTTP getter undefined\n" >&2
            return 1
        fi


        if [ -d "$OH_MY_ZSH" ]; then
            printf " ++ info ($0): oh-my-zsh already in $OH_MY_ZSH, just update\n" >&2

            local CWD="$PWD" && \
            builtin cd "$OH_MY_ZSH"

            local branch="$($git rev-parse --quiet --abbrev-ref HEAD)"
            if [ "$branch" = "HEAD" ] || [ -z "$branch" ]; then
                cd "$CWD"
                printf " ++ warn ($0): can't upgrade from '$branch'\n" >&2
                return 1
            fi

            $git fetch origin -fu "$branch":"$branch" && \
            $git reset --hard && \
            $git checkout --force --quiet $branch && \
            $git pull --ff-only --no-edit --no-commit --verbose origin $branch

            builtin cd "$CWD"

        else
            printf " ++ info ($0): oh-my-zsh deploy to $OH_MY_ZSH\n" >&2

            zsh=$commands[zsh]
            $zsh -c "$ASH_HTTP $OH_MY_ZSH_BOOTSTAP | \
            CHSH=no RUNZSH=no KEEP_ZSHRC=yes ZSH=$OH_MY_ZSH $zsh -s - --unattended --keep-zshrc"

            if [ $? -gt 0 ] || [ ! -f "$OH_MY_ZSH/oh-my-zsh.sh" ]; then
                printf " ** halt ($0): oh-my-zsh deployment failed\n" >&2
                return 1
            fi
        fi
    }


    function deploy.ohmyzsh.extensions() {
        [ ! -d "$OH_MY_ZSH_PLUGINS" ] && mkdir -p "$OH_MY_ZSH_PLUGINS"

        echo " + $0 to $OH_MY_ZSH_PLUGINS"

        for pkg in "${OH_MY_ZSH_PACKAGES[@]}"; do
            local dst="$OH_MY_ZSH_PLUGINS/`fs_basename $pkg`"
            if [ ! -x "$dst/.git" ]; then
                local verb='clone'
                $SHELL -c "git clone --depth 1 $pkg"
            else
                let fetch_every="${UPDATE_ZSH_DAYS:-1} * 86400"
                local last_fetch="`fs_mtime "$dst/.git/FETCH_HEAD" 2>/dev/null`"
                [ -z "$last_fetch" ] && local last_fetch=0

                let need_fetch="$EPOCHSECONDS - $fetch_every > $last_fetch"
                if [ "$need_fetch" -gt 0 ]; then
                    local verb='pull'
                    local branch="`git --git-dir="$dst/.git" --work-tree="$dst/" rev-parse --quiet --abbrev-ref HEAD`"
                    if [ -z "$branch" ]; then
                        echo " - $0 fail: get branch for $pkg in \`$dst\`"
                        continue
                    else
                        git --git-dir="$dst/.git" --work-tree="$dst/" pull origin "$branch"

                        if [ -x "`which git-restore-mtime`" ]; then
                            git-restore-mtime --skip-missing --work-tree "$dst/" --git-dir "$dst/.git/"
                        fi
                    fi
                else
                    local verb='skip fresh'
                fi
            fi

            if [ $? -gt 0 ]; then
                echo " - $0 $verb error: $pkg"
            else
                echo " + $0 $verb success: $pkg"
            fi
        done

        echo " + $0: ${#OH_MY_ZSH_PACKAGES[@]} complete"
        return 0
    }


    function save_previous_installation() {
        if [ -d "$ZSH" ]; then
            # another josh installation found, move backup

            dst="$ZSH-`date "+%Y.%m%d.%H%M"`-backup"
            echo " + another Josh found, backup to $dst"

            mv "$ZSH" "$dst"
            if [ $? -gt 0 ]; then
                echo " - warning: backup $ZSH failed"
                return 4
            fi
        fi

        if [ -f "$HOME/.zshrc" ]; then
            # .zshrc exists from non-josh installation

            dst="$HOME/.zshrc-`date "+%Y.%m%d.%H%M"`-backup"
            echo " + backup old .zshrc to $dst"

            cp -L "$HOME/.zshrc" "$dst" || mv "$HOME/.zshrc" "$dst"
            if [ $? -gt 0 ]; then
                echo " - warning: backup $HOME/.zshrc failed"
                return 4
            fi
            rm "$HOME/.zshrc"
        fi
        return 0
    }


    # ——— set current installation as main and link config

    function rename_and_link() {
        if [ "$OH_MY_ZSH" = "$ZSH" ]; then
            return 1
        fi

        echo " + finally, rename $OH_MY_ZSH -> $ZSH"
        mv "$OH_MY_ZSH" "$ZSH" && ln -s ../plugins/josh/themes/josh.zsh-theme $ZSH/custom/themes/josh.zsh-theme

        dst="`date "+%Y.%m%d.%H%M"`.bak"
        mv "$HOME/.zshrc" "$HOME/.zshrc-$dst" 2>/dev/null

        ln -s $ZSH/custom/plugins/josh/.zshrc $HOME/.zshrc
        if [ $? -gt 0 ]; then
            echo " - fatal: can't create symlink $ZSH/custom/plugins/josh/.zshrc -> $HOME/.zshrc"
            return 1
        fi
        return 0
    }
fi
