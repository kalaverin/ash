if [[ "$0" =~ "/zsh$" ]]; then
    local this='boot/setup/oh-my-zsh.sh'
else
    local this="$(fs.ash.path "$0")"
fi


if [ -z "$ZSH_VERSION" ]; then
    cmd="`$(which ps) -p\$\$ -ocomm=`"

    if [ ! -x "`which zsh`" ]; then
        printf " ** halt ($0): I was made for zsh, not for $cmd; please, install zsh\n" >&2
    else
        printf " ** halt ($0): I was made for zsh, not for $cmd; please change default shell: \"sudo chsh -s `which zsh` $USER\" and run again\n" >&2
    fi

else
    function boot.strap {
        if [ -z "$ASH" ]; then
            printf " ** halt ($0): kalash root '$ASH' isn't defined\n" >&2
            return 1

        elif [ -z "$commands[git]" ]; then
            printf " ** halt ($0): git must be installed\n" >&2
            return 1
        fi

        source $ASH/boot/setup/compat.sh && compat.check || return 1

        git=$commands[git]
        CWD="$PWD" && builtin cd "$ASH"

        local branch="$($git rev-parse --quiet --abbrev-ref HEAD)"
        if [ "$branch" = "HEAD" ] || [ -z "$branch" ]; then
            cd "$CWD"
            printf " ** halt ($0): can't upgrade from '$branch'\n" >&2
            return 1
        fi

        printf " ++ info ($0): get last '$branch' commits to '$ASH'\n" >&2

        $git pull --ff-only --no-edit --no-commit origin "$branch" || return 1

        current="`git rev-parse --show-toplevel`"
        modified="$(git ls-files --modified  "$current")$(git ls-files --deleted --others --exclude-standard "$current")"

        $git update-index --refresh &>/dev/null
        if [ "$?" -gt 0 ] || [ -n "$modified" ]; then
            printf " ** halt ($0): $ASH isn't clean, have changes\n" >&2
            return 1

        elif [ -x "`which git-restore-mtime`" ]; then
            git-restore-mtime --skip-missing --quiet
        fi

        source $ASH/boot/init.sh && \
        printf " ++ info ($0): works in $PWD, deploy and configure oh-my-zsh\n" >&2
        source $ASH/boot/setup/oh-my-zsh.sh && \
            deploy.ohmyzsh
             # && deploy.ohmyzsh.extensions
        # source run/units/binaries.sh && \
        # source run/units/configs.sh && \
        # source lib/python.sh && \
        # source lib/rust.sh
    }
fi
