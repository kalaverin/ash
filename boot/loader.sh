if [ -z "$ZSH_VERSION" ]; then
    cmd="`$(which ps) -p\$\$ -ocomm=`"

    if [ ! -x "`which zsh`" ]; then
        printf " ** fail ($0): I was made for zsh, not for $cmd; please, install zsh\n" >&2
    else
        printf " ** fail ($0): I was made for zsh, not for $cmd; please change default shell: \"sudo chsh -s `which zsh` $USER\" and run again\n" >&2
    fi

elif [ -n "$SUDO_USER" ] && [ ! "$SUDO_USER" = "$USER" ]; then
    printf " ** fail ($0): do not run me under sudo ($SUDO_USER as $USER)\n" >&2

elif [ -n "${(M)zsh_eval_context:#file}" ]; then
    printf " ** fail ($0): do not source me, just run me\n" >&2
    source $ASH/boot/init.sh

else
    zmodload zsh/stat
    zmodload zsh/datetime
    zmodload zsh/parameter
    zmodload zsh/pcre


    function fs.stat.mtime {
        if [ -z "$1" ]; then
            printf " ** fail ($0): call without args, I need to do — what?\n" >&2
            return 1
        fi

        builtin zstat -LA result "$1" 2>/dev/null || return "$?"
        printf "$result[10]"
    }


    function fs.link.read {
        if [ -z "$1" ]; then
            printf " ** fail ($0): call without args, I need to do — what?\n" >&2
            return 1
        fi

        builtin zstat -LA result "$1" 2>/dev/null || return "$?"
        printf "$result[14]"
    }


    function fs.path.base {
        if [ -z "$1" ]; then
            printf " ** fail ($0): call without args, I need to do — what?\n" >&2
            return 1
        fi

        [[ "$1" -regex-match '[^/]+/?$' ]] && printf "$MATCH"
    }


    function fs.path.dir {
        if [ -z "$1" ]; then
            printf " ** fail ($0): call without args, I need to do — what?\n" >&2
            return 1
        fi

        local result="$(fs.path.base $1)"
        [ -z "$result" ] && return 2

        let offset="${#1} - ${#result} -1"
        printf "${1[0,$offset]}"
    }


    function fs.path {
        if [ -z "$1" ]; then
            printf " ** fail ($0): call without args, I need to do — what?\n" >&2
            return 1

        elif [ -e "$1" ]; then
            if [ ! -L "$1" ] && [[ "$1" =~ "^/" ]] && [[ ! "$1" =~ "/../" ]]; then
                # it's not link, it is full file path

                printf "$1"
                return 0

            elif [ -L "$1" ]; then

                local node="`fs.link.read "$1"`"
                if [ -n "$node" ]; then

                    if [ -x "$node" ] && [ ! -L "$node" ] && [[ "$node" =~ "^/" ]]; then
                        # target it's absolute path to executable, not to link

                        printf "$node"
                        return 0

                    elif [[ "$1" =~ "^/" ]] && [[ ! "$node" =~ "/" ]]; then
                        # target it's relative path from source location

                        local node="`fs.path.dir "$1"`/$node"
                        if [ -x "$node" ]; then
                            if [ ! -L "$node" ]; then
                                # target it's regular executable node

                                printf "$node"
                                return 0

                            else  # target it's symlink, okay
                                local node="`fs.path "$node"`"
                                printf "$node"
                                return "$?"
                            fi
                        fi
                    fi
                fi
            fi

            if [ -n "$commands[realpath]" ]; then
                local resolver="$commands[realpath] -q"

            elif [ -n "$commands[readlink]" ]; then

                if [ -z "$(uname | grep -i darwin)" ]; then
                    local resolver="$commands[readlink] -n"
                else
                    local resolver="$commands[readlink] -qf"
                fi
                printf " ++ warn ($0): realpath isn't installed, using fallback: $resolver\n" >&2

            else
                printf " ** fail ($0): realpath or readlink must be installed\n" >&2
                printf "$1"
                return 2
            fi

            eval "$resolver $1"

        else
            printf " ** fail ($0): '$1' invalid\n" >&2
            return 2
        fi
    }


    function fs.path.dir.real {
        if [ -z "$1" ]; then
            printf " ** fail ($0): call without args, I need to do — what?\n" >&2
            return 1
        fi

        local result="$(fs.path "$1")"
        [ -z "$result" ] && return 2

        local result="$(fs.path.dir "$result")"
        [ -z "$result" ] && return 3

        printf "$result"
    }


    function fs.ash.path {
        if [ -z "$1" ]; then
            printf " ** fail ($0): call without args, I need to do — what?\n" >&2
            return 1

        elif [ -z "$ASH" ]; then
            printf " ** fail ($0): kalash root '$ASH' isn't defined\n" >&2
            return 1
        fi

        local result="$(fs.path "$1")"
        if [ -z "$result" ]; then
            printf " ** fail ($0): '$1' isn't found\n" >&2
            return 2
        fi

        local ashed="$(fs.path $ASH)"
        if [[ ! "$result" -regex-match "^$ashed" ]]; then
            printf " ++ warn ($0): source '$1' not in '$ashed'\n" >&2
            printf "$result"
            return 2
        fi

        let length="${#result} - ${#ashed} - 2"
        local result="${result[${#result} - $length,${#result}]}"
        if [ ! -e "$ASH/$result" ]; then
            printf " ** fail ($0): something wrong '$1' -> '$result'\n" >&2
            return 3
        fi
        printf "$result"
    }


    function fs.home.get {
        if [ "$commands[getent]" ]; then
            local result="$($commands[getent] passwd $USER 2>/dev/null | cut -f6 -d:)"
            if [ "$?" -eq 0 ] && [ -x "$result" ]; then
                printf "$result"
                return 0
            fi
        fi

        if [ "$commands[awk]" ]; then
            local result="$($commands[awk] -v u="$USER" -v FS=':' '$1==u {print $6}' /etc/passwd 2>/dev/null)"
            if [ "$?" -eq 0 ] && [ -x "$result" ]; then
                printf "$result"
                return 0
            fi
        fi

        local result="$(echo ~$USER)"
        if [ "$?" -eq 0 ] && [ -x "$result" ]; then
            printf "$result"
            return 0
        fi
    }


    function fs.home {
        local src="$(fs.home.get)"
        if [ ! -x "$src" ]; then
            printf " ** fail ($0): couldn't detect user HOME directory\n" >&2
            return 1
        fi

        local dst="$(fs.path $src)"
        if [ ! -x "$src" ]; then
            printf " ** fail ($0): couldn't detect realpath for user HOME '$src' directory\n" >&2
            return 2
        fi

        if [ "$src" != "$dst" ]; then
            printf " -- info ($0): user home '$src' really locate in '$dst'\n" >&2
        fi
        printf "$dst"
    }


    function fs.ash.link {
        if [ -z "$1" ]; then
            printf " ** fail ($0): call without args, I need to do — what?\n" >&2
            return 1

        elif [ -z "$ASH" ]; then
            printf " ** fail ($0): kalash root '$ASH' isn't defined\n" >&2
            return 1
        fi

        local dst="$(fs.path "$1")"
        if [ ! -f "$dst" ] || [ ! -x "$dst" ]; then
            printf " ** fail ($0): link target '$1' -> '$dst' isn't executable (exists?) file\n" >&2
            return 1
        fi

        local dir="$ASH/bin"
        if [ -z "$2" ]; then
            local src="$dir/$(fs.path.base "$1")"

        else
            if [[ "$2" =~ "/" ]]; then
                printf " ** fail ($0): link name '$2' couldn't contains slashes\n" >&2
                return 2
            fi
            local src="$dir/$2"
        fi

        if [ -L "$src" ] && [ "$dst" != "$(fs.path "$src")" ]; then
            printf " ++ warn ($0): source '$src' with target '$dst' point to '$(fs.path "$src")' (we are unlink that)\n" >&2
            unlink "$src"
        fi

        if [ ! -L "$src" ]; then
            [ ! -d "$dir" ] && mkdir -p "$dir"
            ln -s "$dst" "$src"
        fi
        printf "$dst"
        return 0
    }


    function fs.ash.link.is {
        if [ -z "$1" ]; then
            printf " ** fail ($0): call without args, I need to do — what?\n" >&2
            return 1

        elif [ -n "$2" ] && [[ "$2" =~ "/" ]]; then
            printf " ** fail ($0): link name '$2' couldn't contains slashes\n" >&2
            return 1

        elif [ -z "$ASH" ]; then
            printf " ** fail ($0): kalash root '$ASH' isn't defined\n" >&2
            return 1
        fi

        if [ -z "$2" ]; then
            if [[ ! "$1" =~ "/" ]]; then
                # zsh checks for link zsh exists and points to executive
                if [ -L "$ASH/bin/$1" ]; then
                    local src="$(fs.path "$ASH/bin/$1" 2>/dev/null)"
                    if [ -x "$src" ]; then
                        printf "$src"
                        return 0
                    fi
                fi

            else
                # /bin/zsh checks for link zsh points to /bin/zsh
                local src="$(fs.path "$1")"
                local dst="$(fs.path.base "$1")"
                if [ -z "$src" ]; then
                    printf " ** fail ($0): something wrong with source, '$1' ($ASH) -> nothing\n" >&2

                elif [ -z "$dst" ]; then
                    printf " ** fail ($0): something wrong with target, '$1' ($ASH) -> nothing\n" >&2

                elif [ -L "$ASH/bin/$dst" ] && [ "$src" = "$(fs.path "$ASH/bin/$dst" 2>/dev/null)" ]; then
                    printf "$src"
                    return 0
                fi
            fi

        else
            if [[ "$1" =~ "/" ]]; then
                # /bin/zsh + zsh: zsh linkg points to /bin/zsh
                local src="$(fs.path "$1")"
                if [ "$src" = "$(fs.ash.link.is "$2" 2>/dev/null)" ]; then
                    printf "$src"
                    return 0
                fi
            else
                # zsh1 + zsh2: zsh2 linkg points to /bin/zsh1
                local src="$(fs.ash.link.is "$2" 2>/dev/null)"
                if [ -x "$src" ] && [ "$(fs.path.base "$src")" = "$1" ]; then
                    printf "$src"
                    return 0
                fi
            fi
        fi
        return 1
    }


    function fs.path.lookup {
        if [[ "$1" =~ "/" ]]; then
            printf " ** fail ($0): link name '$1' couldn't contains slashes\n" >&2
            return 2
        fi

        for sub in $path; do
            if [ -f "$sub/$1" ] && [ -x "$sub/$1" ]; then
                printf "$sub/$1"
                return 0
            fi
        done

        return 1
    }


    function fs.path.which {
        if [ -z "$1" ]; then
            printf " ** fail ($0): call without args, I need to do — what?\n" >&2
            return 2

        elif [[ "$1" =~ "/" ]]; then
            printf " ** fail ($0): link name '$1' couldn't contains slashes\n" >&2
            return 2

        elif [ -z "$ASH" ]; then
            printf " ++ warn ($0): kalash root '$ASH' isn't defined\n" >&2
        fi

        if [ -n "$ASH" ] && [ -L "$ASH/bin/$1" ]; then
            printf "$ASH/bin/$1"
            return 0

        elif [ "$commands[$1]" ]; then
            printf "$commands[$1]"
            return 0

        else
            printf " -- info ($0): query term '$1' isn't found, fallback to PATH scan\n" >&2

            local dst="$(fs.path.lookup "$1")"
            [ "$dst" ] && printf "$dst" && return "$?"
            return "$?"

        fi

        return 1
    }


    function fs.path.rebuild {
        local dir="$(fs.home)"
        if [ ! -x "$dir" ]; then
            printf " ** fail ($0): couldn't detect user HOME directory\n" >&2
            return 1
        fi

        path_ash_defined=(
            $ASH/bin
            $dir/.cargo/bin
            $dir/.python/default/bin
            $dir/.brew/bin
            $dir/.local/bin
            $dir/bin
            /usr/local/bin
            /bin
            /sbin
            /usr/bin
            /usr/sbin
            /usr/local/sbin
        )

        path=(
            $path_user_prepend
            $path_ash_defined
            $path
        )

        local order="$(
            printf "$path" | sed 's#:#\n#' | sed "s:^~/:$dir/:" | \
            xargs -n 1 realpath 2>/dev/null | \
            grep -v "$ASH" | \
            awk '!x[$0]++' | \
            sed -z 's#\n#:#g' | sed 's#:$##g' \
        )"
        local ret="$?"

        if [ "$ret" -eq 0 ] && [ -n "$order" ]; then
            export PATH="$ASH/bin:$order"
        fi
        return "$ret"
    }


    #


    if [ -z "$ASH" ]; then
        local dir="$(fs.home)"
        if [ -d "$dir" ] && [ -x "$dir" ] && [ ! "$dir" = "$HOME" ]; then
            if [ ! "$(fs.path "$dir")" = "$(fs.path "$HOME")" ]; then
                printf " -- info ($0): set HOME '$HOME' -> '$src'\n" >&2
            fi
            export HOME="$dir"
        fi
        export ASH="$HOME/${ASH_SUBDIR:-.kalash}"
    fi

    function fs.ash.self {
        if [ -z "$1" ]; then
            printf " ** fail ($0): call without args, I need to do — what?\n" >&2
            return 1

        elif [ -z "$ASH" ]; then
            printf " ++ warn ($0): kalash root '$ASH' isn't defined\n" >&2

        fi

        if [[ "$1" =~ "/zsh$" ]]; then
            if [ -n "$2" ]; then
                local result='boot/loader.sh'
            else
                local result="$1"
            fi
        else
            local result="$(fs.ash.path "$1")"
            [ -z "$result" ] && local result="$0"
        fi

        if [ -z "$result" ]; then
            printf " ** fail ($0): something wrong, '$1' ($ASH) + '$2' -> '$result'\n" >&2
            return 2
        fi

        printf "$result"
    }

    local this="$(fs.ash.self "$0" 'boot/loader.sh')"

    # if [ ! -f "$ASH/boot/strap.sh" ]; then
        if [ -z "$commands[git]" ]; then
            printf " ** fail ($this): git must be installed\n" >&2

        else
            git=$commands[git]
            branch="${ASH_BRANCH:-"master"}"
            repo="${ASH_REPO:-"https://github.com/kalaverin/ash"}"

            if [ ! -d "$ASH" ]; then
                printf " ++ warn ($this): initial deploy from $repo/$branch to $ASH\n" >&2
                $git \
                    clone --depth 1 \
                    --single-branch --branch "$branch" \
                    "$repo" \
                    "$ASH"
                local ret="$?"

            else
                printf " ++ info ($this): pull from $repo/$branch to $ASH\n" >&2

                CWD="$PWD" && builtin cd "$ASH"

                current="`git rev-parse --show-toplevel`"
                modified="$(git ls-files --modified  "$current")$(git ls-files --deleted --others --exclude-standard "$current")"

                if [ -z "$modified" ]; then
                    $git fetch origin -fu "$branch":"$branch" && \
                    $git reset --hard && \
                    $git checkout --force --quiet $branch && \
                    $git pull --ff-only --no-edit --no-commit --verbose origin $branch
                    local ret="$?"
                else
                    printf " ** fail ($this): $ASH isn't clean, have changes\n" >&2
                    local ret=1
                fi

                builtin cd "$CWD"
            fi

            [ -x "`which git-restore-mtime`" ] && \
                git-restore-mtime --skip-missing --work-tree "$ASH/" --git-dir "$ASH/.git/"

            if [ "$ret" -eq 0 ]; then
                source $ASH/boot/strap.sh && \
                    boot.strap && \
                # builtin cd "$HOME" && exec zsh
            fi
        fi
    # fi

    fs.path.rebuild
    function which { eval "fs.path.which $@"; return "$?" }
    source "$ASH/boot/init.sh"
fi
