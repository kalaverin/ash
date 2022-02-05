BREW_REС_PACKAGES=(
    ag    # silver searcher, another one fast source grep on golang
    htop  # instead system-wide htop
    jq    # JSON swiss-knife, format, highlight, traversal and query tool
    pv    # contatenate pipes with monitoring
    tmux  # terminal multiplexer
    tree  # hierarchy explore tool
    git   # always use last version of all used tools:
    coreutils
    findutils
    fzf
    gnu-tar
    grep
    gsed
    micro
    nano
    zsh
)


function brew.root {
    local msg=" - $0 fatal: isn't supported \`$JOSH_OS\`: `uname -srv`"

    if [ "$JOSH_OS" = "BSD" ]; then
        echo "$msg" >&2
        return 1

    elif [ "$JOSH_OS" = "MAC" ]; then
        echo "$msg" >&2
        return 1
    fi

    echo "$HOME/.brew"
    return 0
}


function brew.env {
    local root="$(brew.root 2>/dev/null)"
    if [ -z "$root" ]; then
        return 1

    elif [ ! -x "$root/bin/brew" ]; then
        echo " - $0 fatal: brew binary \`$root/bin/brew\` isn't found" >&2
        return 2
    fi

    eval $($root/bin/brew shellenv)

    HOMEBREW_CELLAR="$root/Cellar"
    HOMEBREW_PREFIX="$root"
    HOMEBREW_REPOSITORY="$root"
    HOMEBREW_SHELLENV_PREFIX="$root"

    fs.path.rebuild
    rehash
}


function brew.exe {
    local root="`brew.root`"
    [ -z "$root" ] && return 1

    local bin="$root/bin/brew"
    if [ ! -x "$bin" ]; then
        echo " - $0 fatal: brew binary \`$root/bin/brew\` isn't found" >&2
        return 2
    fi

    echo "$bin"
    return 0
}

function brew.deploy {
    local root="`brew.root`"
    [ -z "$root" ] && return 1

    if [ -d "$root" ]; then
        echo " - $0 fatal: brew path \`$root\` exists" >&2
        return 2

    elif [ ! -d "`fs_dirname $root`" ]; then
        echo " - $0 fatal: brew path \`$root\` subroot isn't found" >&2
        return 3
    fi

    git clone --depth 1 "https://github.com/Homebrew/brew" "$root" && \
    eval $($root/bin/brew shellenv) && \
    rehash

    local bin="`brew.exe`"
    [ ! -x "$bin" ] && return 4
    $bin update --force

    return "$?"
}

function brew.init {
    local root="`brew.root`"
    [ -z "$root" ] && return 1

    if [ ! -x "$root/bin/brew" ]; then
        echo " - $0 fatal: brew binary \`$root/bin/brew\` isn't found, deploy now" >&2
        brew.deploy || return 2
    fi

    brew.env
}

function brew.add {
    brew.init || return 1

    if [ -z "$*" ]; then
        echo " - $0 fatal: nothing to do" >&2
        return 2
    fi

    local brew="`brew.exe`"
    [ ! -x "$brew" ] && return 3

    for row in $*; do
        run_show "$brew install $row"

        local exe="`fs_basename $row`"
        if [ -z "$exe" ]; then
            echo " - $0 fatal: basename for \`$row\` empty" >&2
            continue
        fi

        local bin="$HOMEBREW_PREFIX/bin/$exe"
        if [ -x "$bin" ]; then
            local dst="`shortcut "$bin"`"
            if [ -n "$dst" ]; then
                echo " + $0 info: $exe -> `which $exe` ($dst)" >&2
            fi
        fi
    done
}

function brew.extras {
    run_show "brew.add $BREW_REС_PACKAGES"
    return 0
}

function brew.update {
    brew.env || return 1

    local bin="`brew.exe`"
    [ ! -x "$bin" ] && return 2
    $bin update && $bin upgrade
}
