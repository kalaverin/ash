zmodload zsh/regex


local this="$(fs.ash.self "$0" 'boot/setup/compat.sh')"


req_bins=(
    cc
    git
    make
    pkg-config
    python3
    tmux
    zsh
)

req_libs=(
    openssl
    libevent
)


function compat.check.exe {
    local missing=""
    for exe in $@; do
        if [ ! -x "$(builtin which -p $exe 2>/dev/null)" ]; then
            local missing="$missing $exe"
        fi
    done
    if [ "$missing" ]; then
        printf " ** warn ($0): missing required executable: $missing\n" >&2
        return 1
    fi
    return 0
}


function compat.check.lib {
    local missing=""
    for lib in $@; do
        pkg-config --libs --cflags $lib 1&>/dev/null 2&>/dev/null
        if [ "$?" -gt 0 ]; then
            if [ "$lib" = "openssl" ]; then

                if [ "$ASH_PLATFORM" = "mac" ]; then
                    local lookup_path="/usr/local/opt/"

                elif [ "$ASH_PLATFORM" = "linux" ]; then
                    local lookup_path="/usr/lib/"

                elif [ "$ASH_PLATFORM" = "bsd" ]; then
                    local lookup_path="/usr/local/"

                else
                    if [ -z "$missing"]; then
                        local missing="$lib"
                    else
                        local missing="$missing $lib"
                    fi
                    continue
                fi
                printf " ** warn ($0): pkg-config $lib failed, try to find openssl.pc in $lookup_path\n" >&2

                local openssl_path="$(fs.path.dir `find "$lookup_path" -type f -name "openssl.pc" -follow 2>/dev/null | head -n 1`)"
                if [ ! -d "$openssl_path" ]; then
                    printf " ** fail ($0): pkg-config $lib: nothing about openssl.pc in $lookup_path\n" >&2
                    local missing="$missing $lib"
                    continue
                fi
                printf " -- info ($0): retry pkg-config $lib: openssl.pc found in $openssl_path\n" >&2
                export PKG_CONFIG_PATH="$openssl_path"

                pkg-config --libs --cflags $lib 1&>/dev/null 2&>/dev/null
                if [ "$?" -gt 0 ]; then
                    printf " ** fail ($0): pkg-config $lib: nothing about openssl.pc in $PKG_CONFIG_PATH too\n" >&2
                    local missing="$missing $lib"
                    continue
                fi
                printf " -- info ($0): pkg-config $lib: openssl.pc found in $PKG_CONFIG_PATH\n" >&2

            else
                if [ -z "$missing"]; then
                    local missing="$lib"
                else
                    local missing="$missing $lib"
                fi
            fi
        fi
    done
    if [ "$missing" ]; then
        printf " ** warn ($0): missing required libraries: $missing\n" >&2
        return 1
    fi
    return 0
}


function compat.version_is_greather {
    if [ -z "$1" ] || [ -z "$2" ]; then
        printf " ** fail ($0): call without args: '$1' '$2', I need to do — what?\n" >&2
        return 2

    elif [ "$1" != "$2" ]; then
        local version="$(printf '%s\n%s\n' "$1" "$2" | sort --version-sort | tail -n 1)"

        if [ "$?" -gt 0 ]; then
            printf " ** fail ($0): something wrong with: '$1' <> '$2'\n" >&2
            return 2

        elif [[ "$version" -regex-match "^$2$" ]]; then
            return 1
        fi
    fi
}


function compat.check {
    if [ -n "$(uname | grep -i freebsd)" ]; then
        printf " ++ info ($0): platform FreeBSD (`uname -srv`)\n" >&2
        export ASH_PLATFORM="bsd"

        local cmd="sudo pkg install -y"
        local pkg=(
            bash
            coreutils
            findutils
            git
            gnugrep
            gnuls
            gsed
            gtar
            openssl
            pkgconf
            python310
            zsh
        )
        req_sys_bins=(
            bash
            pkg
            /usr/local/bin/gcut
            /usr/local/bin/gfind
            /usr/local/bin/gnuls
            /usr/local/bin/greadlink
            /usr/local/bin/grealpath
            /usr/local/bin/grep
            /usr/local/bin/gsed
            /usr/local/bin/gtar
        )

    elif [ -n "$(uname | grep -i darwin)" ]; then
        printf " ++ info ($0): platform MacOS (`uname -srv`)\n" >&2
        export ASH_PLATFORM="mac"

        local cmd="brew update && brew install"
        local pkg=(
            bash
            coreutils
            findutils
            git
            gnu-tar
            grep
            gsed
            openssl
            pkg-config
            python@3
            zsh
        )
        req_sys_bins=(
            bash
            brew
            /usr/local/bin/gcut
            /usr/local/bin/gfind
            /usr/local/bin/ggrep
            /usr/local/bin/gls
            /usr/local/bin/greadlink
            /usr/local/bin/grealpath
            /usr/local/bin/gsed
            /usr/local/bin/gtar
        )


    elif [ -n "$(uname -srv | grep -i linux)" ]; then
        export ASH_PLATFORM="linux"

        if [ -f "/etc/debian_version" ] || [ -n "$(uname -v | grep -Pi '(debian|ubuntu)')" ]; then
            req_sys_bins=( apt )
            printf " ++ info ($0): platform Debian (`uname -srv`)\n" >&2

            [ "$commands[apt]" ] && local bin="apt" || local bin="apt-get"

            local cmd="(sudo $bin update --yes --quiet || true) && sudo $bin install --yes --quiet --no-remove"

            local pkg=(
                build-essential
                clang
                git
                libevent-dev
                libpq-dev
                libssl-dev
                make
                pkg-config
                python3
                python3-distutils
                zsh
            )


        elif [ -f "/etc/arch-release" ] || [ -n "$(uname -v | grep -Pi '(arch|manjaro)')"; then
            req_sys_bins=( pacman )
            printf " ++ info ($0): platform Arch (`uname -srv`)\n" >&2

            local cmd="sudo pacman --sync --noconfirm"
            local pkg=(
                base-devel
                clang
                gcc
                git
                libevent
                openssl
                pkg-config
                postgresql-libs
                python3
                tmux
                zsh
            )

        elif [ -n "$(uname -srv | grep -i gentoo)" ]; then
            printf " ++ info ($0): platform Gentoo (`uname -srv`)\n" >&2

        elif [ -n "$(uname -srv | grep -i microsoft)" ]; then
            printf " ++ info ($0): platform Windows/WSL (`uname -srv`)\n" >&2

        else
            printf " ++ info ($0): platform generic Linux (`uname -srv`)\n" >&2

        fi
    else
        printf " ** warn ($0): unknown platform (`uname -srv`)\n" >&2
        export ASH_PLATFORM="unknown"
    fi

    compat.check.lib $req_libs $req_sys_libs && \
    compat.check.exe $req_bins $req_sys_bins

    if [ $? -gt 0 ]; then
        local msg="install required packages"
        [ "$cmd" ] && local msg=" -- info ($0): requirements unresolved, $msg: \"$cmd $pkg\" and retry"

        if [ ! "$ASH_FORCE_INSTALL" ]; then
            printf "$msg\n" && return 1
        else
            printf "$msg\n"
        fi
    else

        printf " -- info ($0): requirements resolved, executives: $req_bins $req_sys_bins, libraries: $req_libs $req_sys_libs\n" >&2
    fi
    return 0
}
