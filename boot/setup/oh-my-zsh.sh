OH_MY_ZSH="$HOME/.oh-my-zsh"
OH_MY_ZSH_CUSTOM="$OH_MY_ZSH/custom/plugins"
OH_MY_ZSH_BOOTSTAP='https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh'
OH_MY_ZSH_PACKAGES=(
    # "https://github.com/alecthomas/ondir.git $OH_MY_ZSH_CUSTOM/ondir"
    # "https://github.com/MestreLion/git-tools.git $OH_MY_ZSH_CUSTOM/git-tools"
    "https://github.com/chrissicool/zsh-256color $OH_MY_ZSH_CUSTOM/zsh-256color"
    "https://github.com/facebook/PathPicker.git $OH_MY_ZSH_CUSTOM/fpp"
    "https://github.com/hlissner/zsh-autopair.git $OH_MY_ZSH_CUSTOM/zsh-autopair"
    "https://github.com/leophys/zsh-plugin-fzf-finder.git $OH_MY_ZSH_CUSTOM/zsh-plugin-fzf-finder"
    "https://github.com/mafredri/zsh-async.git $OH_MY_ZSH_CUSTOM/zsh-async"
    "https://github.com/mollifier/anyframe.git $OH_MY_ZSH_CUSTOM/anyframe"
    "https://github.com/seletskiy/zsh-fuzzy-search-and-edit.git $OH_MY_ZSH_CUSTOM/zsh-fuzzy-search-and-edit"
    "https://github.com/TamCore/autoupdate-oh-my-zsh-plugins $OH_MY_ZSH_CUSTOM/autoupdate"
    "https://github.com/trapd00r/zsh-syntax-highlighting-filetypes.git $OH_MY_ZSH_CUSTOM/zsh-syntax-highlighting-filetypes"
    "https://github.com/wfxr/forgit.git $OH_MY_ZSH_CUSTOM/forgit"
    "https://github.com/zdharma-continuum/history-search-multi-word.git $OH_MY_ZSH_CUSTOM/history-search-multi-word"
    "https://github.com/zlsun/solarized-man.git $OH_MY_ZSH_CUSTOM/solarized-man"
    "https://github.com/zsh-users/zsh-autosuggestions $OH_MY_ZSH_CUSTOM/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-completions $OH_MY_ZSH_CUSTOM/zsh-completions"
    "https://github.com/zsh-users/zsh-syntax-highlighting.git $OH_MY_ZSH_CUSTOM/zsh-syntax-highlighting"
)


if [ -z "$ZSH_VERSION" ]; then
    cmd="`$(which ps) -p\$\$ -ocomm=`"

    if [ ! -x "`which zsh`" ]; then
        printf " ** fail ($0): I was made for zsh, not for $cmd; please, install zsh\n" >&2
    else
        printf " ** fail ($0): I was made for zsh, not for $cmd; please change default shell: \"sudo chsh -s `which zsh` $USER\" and run again\n" >&2
    fi

else
    zmodload zsh/datetime


    local this="$(fs.ash.self "$0" 'boot/setup/oh-my-zsh.sh')"


    function deploy.ohmyzsh() {
        if [ -z "$ASH_HTTP" ]; then
            printf " ** fail ($0): HTTP getter undefined\n" >&2
            return 1

        elif [ -z "$commands[git]" ]; then
            printf " ** fail ($this): git must be installed\n" >&2
            return 1
        fi


        if [ ! -d "$OH_MY_ZSH" ]; then
            zsh=$commands[zsh]

            printf " ++ info ($0): oh-my-zsh deploy to $OH_MY_ZSH\n" >&2

            $zsh -c "$ASH_HTTP $OH_MY_ZSH_BOOTSTAP | \
            CHSH=no RUNZSH=no KEEP_ZSHRC=yes ZSH=$OH_MY_ZSH $zsh -s - --unattended --keep-zshrc"

            if [ $? -gt 0 ] || [ ! -f "$OH_MY_ZSH/oh-my-zsh.sh" ]; then
                printf " ** fail ($0): oh-my-zsh deployment failed\n" >&2
                return 1
            fi

        else
            git=$commands[git]
            local CWD="$PWD" && \
            builtin cd "$OH_MY_ZSH"

            printf " ++ info ($0): oh-my-zsh already in $OH_MY_ZSH, just update\n" >&2

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

        fi
    }


    function deploy.ohmyzsh.extensions() {
        if [ -z "$commands[git]" ]; then
            printf " ** fail ($this): git must be installed\n" >&2
            return 1
        fi

        [ ! -d "$OH_MY_ZSH_CUSTOM" ] && mkdir -p "$OH_MY_ZSH_CUSTOM"

        git=$commands[git]

        printf " ++ info ($0): deploy oh-my-zsh extenstions to $OH_MY_ZSH_CUSTOM\n" >&2

        for pkg in "${OH_MY_ZSH_PACKAGES[@]}"; do

            local dst="$OH_MY_ZSH_CUSTOM/$(fs.path.base $pkg)"

            if [ ! -d "$dst/.git" ]; then
                local verb='clone'

                $commands[zsh] -c "GIT_TERMINAL_PROMPT=0 $git clone --depth 1 $pkg"

                if [ "$?" -gt 0 ]; then
                    printf " ** fail ($0): clone $pkg to '$dst'\n" >&2
                else
                    [ -d "$dst/.git" ] && [ -x "`which git-restore-mtime`" ] && \
                        git-restore-mtime --skip-missing --work-tree "$dst/" --git-dir "$dst/.git/"
                fi

            else
                let fetch_every="${ASH_UPDATE_ZSH_DAYS:-1} * 86400"
                local last_fetch="$(fs.stat.mtime "$dst/.git/FETCH_HEAD" 2>/dev/null)"
                [ -z "$last_fetch" ] && local last_fetch=0


                let need_fetch="$EPOCHSECONDS - $fetch_every > $last_fetch"
                echo "$EPOCHSECONDS - $fetch_every > $last_fetch // $need_fetch"
                if [ "$need_fetch" -gt 0 ]; then
                    local verb='pull'
                    local branch="$($git --git-dir="$dst/.git" --work-tree="$dst/" rev-parse --quiet --abbrev-ref HEAD)"

                    if [ -z "$branch" ]; then
                        printf " ** fail ($0): fetch $pkg/$branch to '$dst'\n" >&2
                        continue

                    else
                        $commands[zsh] -c "GIT_TERMINAL_PROMPT=0 $git --git-dir='$dst/.git' --work-tree='$dst/' pull origin '$branch'"
                        [ -x "`which git-restore-mtime`" ] && \
                            git-restore-mtime --skip-missing --work-tree "$dst/" --git-dir "$dst/.git/"
                    fi
                else
                    local verb='skip fresh'
                fi
            fi

            [ $? -gt 0 ] \
                && local result="--" \
                || local result="++"
            printf " $result info ($0): fetch $pkg\n" >&2
        done

        printf " ++ info ($0): total ${#OH_MY_ZSH_PACKAGES[@]} plugins'\n" >&2
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
