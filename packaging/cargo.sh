CARGO_REQ_PACKAGES=(
    bat              # modern replace for cat with syntax highlight
    cargo-update     # packages for auto-update installed crates
    chit             # crates info, just type: chit <any>
    csview           # for commas, tabs, etc
    fd-find          # fd, fast replace for find for humans
    git-delta        # fast replace for git delta with steroids
    git-interactive-rebase-tool
    lsd              # fast ls replacement
    mdcat            # Markdown files rendered viewer
    petname          # generate human readable strings
    proximity-sort   # path sorter
    ripgrep          # rg, fast replace for grep -ri for humans
    rm-improved      # rip, powerful rm replacement with trashcan
    runiq            # fast uniq replacement
    scotty           # directory crawling statistics with search
    sd               # fast sed replacement for humans
    starship         # shell prompt
    tabulate         # autodetect columns in stdin and tabulate
    vivid            # ls colors themes selections system
)
CARGO_REC_PACKAGES=(
    bump-bin         # versions with semver specification
    dtool            # code decode swiss knife
    dull             # strip any ANSI (color) sequences from pipe
    genact           # console activity generator
    pgen             # another yet
    procs            # ps aux replacement for humans
    pueue            # powerful tool to running and management background tasks
    qrrs             # qr code terminal tool
    quickdash        # hasher
    rcrawl           # very fast file by pattern in directory
    rhit             # very fast nginx log analyzer with graphical stats
    viu              # print images into terminal
    xkpwgen          # same story
    ytop             # same, line bottom
    # du, ncdu like tools
    dirstat-rs       # ds, du replace, summary tree
    du-dust          # dust, du replace, verbose tree
    durt             # du replace, just sum
    # search and grep tools
    lolcate-rs       # blazing fast filesystem database
    bingrep          # extract and grep strings from binaries
    # git related tools
    diffsitter       # AST based diff
    diffr            # word based diff
    gfold            # git reps in directory branches status
    git-bonsai       # full features analyze and remove unnecessary branches
    git-trim         # remove local branches when remote merged o stray
    git-hist         # git history for selected file
    git-local-ignore # local (without .gitignore) git ignore wrapper
    gitall           # search git subdirs and run custom command, find+xargs altarnative
    mrh              # recursively search git reps and return status (detached, tagged, etc)
    onefetch         # graphical statistics for git repository
    tokei            # repository stats
    # JSON tools
    jql              # select values by path from JSON input for humans
    jen              # generator
    rjo              # generator by key->value
    fblog            # log viewer
    jex              # interactive explorer
    jfmt             # minifier
    jsonfmt          # another json minifier
    ry               # jq for yamls
    yj               # yaml to json converter
    # scan and security tools
    binary-security-check
    checkpwn         # check passwords
    feroxbuster      # agressively website dumper
    loadem           # website load maker
    rustscan         # scanner around nmap
    x8               # websites scan tool
    # simple network tools
    gip              # show my ip
    ipgeo            # fast geoloc by hostname/ip
    #
    miniserve        # directory serving over http
)
CARGO_OPT_PACKAGES=(
    gitui            # terminal UI full featured git tool
    git-branchless
    # system meters, like top, htop, etc
    bandwhich        # network bandwhich meter
    bottom           # btm, another yet htop
    rmesg            # modern dmesg replacement
    # misc tools
    dupe-krill       # replace similar (by hash) files with hardlinks
    fw               # workspaces manager
    multi-tunnel     # serving ssh tunnels from toml config
    # semver tools
    gbump
    vergit
    what-bump
    # command-line helpers
    so               # stack overflow answers in terminal
    hors
    bropages
    #
    choose           # awk for humans
    colorizer        # logs colorizer
    ffsend           # sharing files tool
    hyperfine        # full featured time replacement and benchmark tool
    jira-terminal    # Jira client, really
    logtail          # graphical tail logs in termial
    thwack           # find and run
    # make, build & run systems
    python-launcher
    scriptisto       # powerful tool, convert every source to executable with build instructions in same file
    just             # comfortable system for per project frequently used commands like make test, etc
    # viewers for csv, md, etc
    b0x              # info about input vars
    mandown          # convert markdown to man
    paper-terminal   # another yet Markdown printer, naturally like newpaper
    streampager      # less for streams
    tidy-viewer      # csv prettry printer
    # dns over https tools
    encrypted-dns
    doh-proxy
    doh-client
    # coreutils        # rust reimplementation for GNU tools, unstable
    # other text related tools
    prose            # reformat text to width
    cw               # words, lines, bytes and chars counter
    ff-find          # ff, fd-find interface
    ruplacer         # in file tree replacer
    amber            # in file tree replacer, threaded, mmap
    repgrep          # interactive interface for ripgrep
    #
    atuin            # another yet history manager
    autocshell       # generate completitions for shell
    blockish         # view images in terminal
    broot            # lightweight embeddable file manager
    code-minimap     # terminal code minimap
    connchk          # connection checkers from yaml
    copycat
    dssim            # pictures similar rating
    fclones          # find and clean trash
    fcp              # fast cp with threading
    gitweb           # git open in browser helper
    hunter           # file manager
    hx
    imdl             # torrent-file helper
    investments      # stocks tools
    kras             # colorizer
    limber           # elk import export
    lino
    lms              # threaded rsync for local
    lolcrab
    menyoki          # screencast
    mprober
    ntimes           # ntimes 3 -- echo 'lol'
    parallel-disk-usage
    pingkeeper
    pipecolor        # colorizer
    runscript
    sbyte            # hexeditor
    sheldon
    sic              # pictures swiss knife
    silicon          # render source code to pictures
    songrec          # shazam!
    ssup             # notifications to telegram
    t-rec
    tab              # terminal multiplexer like tmux
    termscp
    tickrs           # realtime ticker
    watchexec-cli    # watchdog for filesystem and runs callback on hit
    xcompress
    zoxide           # fast cd, like wd
)

CARGO_BIN="$CARGO_BINARIES/cargo"

function cargo.init {
    local cache_exe="$CARGO_BINARIES/sccache"

    if [ ! -x "$CARGO_BIN" ]; then
        export RUSTC_WRAPPER=""
        unset RUSTC_WRAPPER

        url='https://sh.rustup.rs'

        $SHELL -c "$HTTP_GET $url" | RUSTUP_HOME="$HOME/.rustup" CARGO_HOME="`fs_dirname $CARGO_BINARIES`" RUSTUP_INIT_SKIP_PATH_CHECK=yes $SHELL -s - --profile minimal --no-modify-path --quiet -y

        if [ ! -x "$CARGO_BIN" ] || [ $? -gt 0 ]; then
            echo " - fatal: cargo \`$CARGO_BIN\` isn't installed"
            return 127
        else
            echo " + info: `$CARGO_BIN --version` in \`$CARGO_BIN\` installed"
        fi
    fi

    export PATH="$CARGO_BINARIES:$PATH"

    if [ ! -x "$cache_exe" ]; then
        $CARGO_BIN install sccache
        if [ ! -x "$cache_exe" ]; then
            echo " - warning: sccache \`$cache_exe\` isn't compiled"
        fi
    fi

    if [ -z "$RUSTC_WRAPPER" ] || [ ! -x "$RUSTC_WRAPPER" ]; then
        if [ -x "$cache_exe" ]; then
            export RUSTC_WRAPPER="$cache_exe"

        elif [ -x "`which sccache`" ]; then
            export RUSTC_WRAPPER="`which sccache`"

        else
            export RUSTC_WRAPPER=""
            unset RUSTC_WRAPPER
            echo " - warning: sccache doesn't exists"
        fi
    fi

    local update_exe="$CARGO_BINARIES/cargo-install-update"
    if [ ! -x "$update_exe" ]; then
        $CARGO_BIN install cargo-update
        if [ ! -x "$update_exe" ]; then
            echo " - warning: cargo-update \`$update_exe\` isn't compiled"
        fi
    fi

    return 0
}

function cargo.add {
    cargo.init || return $?
    if [ ! -x "$CARGO_BIN" ]; then
        echo " - fatal: cargo exe \`$CARGO_BIN\` isn't found!"
        return 1
    fi

    $SHELL -c "`fs.path $CARGO_BINARIES/rustup` update"

    local retval=0
    for pkg in $@; do
        $CARGO_BIN install $pkg
        if [ "$?" -gt 0 ]; then
            local retval=1
        fi
    done
    return "$retval"
}


function cargo.extras {
    cargo_install "$CARGO_REQ_PACKAGES $CARGO_REC_PACKAGES"
    return 0
}


function cargo.list {
    cargo.init || return $?
    if [ ! -x "$CARGO_BIN" ]; then
        echo " - fatal: cargo exe $CARGO_BIN isn't found!"
        return 1
    fi
    echo "$($CARGO_BIN install --list | egrep '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d' ')"
}


function cargo_install {
    cargo.init || return $?
    if [ ! -x "$CARGO_BIN" ]; then
        echo " - fatal: cargo exe $CARGO_BIN isn't found!"
        return 1
    fi

    if [ -n "$*" ]; then
        local selected="$*"
    else
        local selected="$CARGO_REQ_PACKAGES $CARGO_REC_PACKAGES $CARGO_OPT_PACKAGES"
    fi

    local installed_regex="(`cargo.list | sed -z 's:\n: :g' | sed 's/ *$//' | sd '\b +\b' '|'`)"
    local missing_packages="`echo "$selected" | sd '\s+' '\n' | grep -Pv "$installed_regex" | sed -z 's:\n: :g' | sed 's/ *$//' `"
    [ -z "$missing_packages" ] && return 0

    local autoinstall="`echo "$*" | sd '\s+' '\n' | grep -Pv "$installed_regex" | sed -z 's:\n: :g' | sed 's/ *$//' `"
    if [ -n "$autoinstall" ]; then
        local packages="$autoinstall"
    else
        local packages="$($SHELL -c "
            echo "$missing_packages" \
            | sd ' +' '\n' \
            | proximity-sort - \
            | $FZF \
                --multi \
                --nth=2 \
                --tiebreak='index' \
                --layout=reverse-list \
                --prompt='install > ' \
                --preview='chit {1}' \
                --preview-window="left:`get_preview_width`:noborder" \
            | $UNIQUE_SORT | $LINES_TO_LINE
        ")"
    fi

    if [ -n "$packages" ]; then
        run_show "$CARGO_BIN install $packages"
    fi
}


function cargo_uninstall {
    cargo.init || return $?
    if [ ! -x "$CARGO_BIN" ]; then
        echo " - fatal: cargo exe $CARGO_BIN isn't found!"
        return 1
    fi

    local required_regex="(`echo "$CARGO_REQ_PACKAGES" | sed -z 's:\n: :g' | sed 's/ *$//' | sd '\b +\b' '|'`)"

    if [ -n "$*" ]; then
        local selected="$*"
    else
        local selected="$CARGO_REQ_PACKAGES $CARGO_REC_PACKAGES $CARGO_OPT_PACKAGES"
    fi

    local installed_regex="(`cargo.list | sed -z 's:\n: :g' | sed 's/ *$//' | sd '\b +\b' '|'`)"
    local installed_packages="`echo "$selected" | sd '\s+' '\n' | grep -P "$installed_regex" | grep -Pv "$required_regex" | sed -z 's:\n: :g' | sed 's/ *$//' `"
    [ -z "$installed_packages" ] && return 0

    local autoremove="`echo "$*" | sd '\s+' '\n' | grep -P "$installed_regex" | grep -Pv "$required_regex" | sed -z 's:\n: :g' | sed 's/ *$//' `"
    if [ -n "$autoremove" ]; then
        local packages="$autoremove"
    else
        local packages="$($SHELL -c "
            echo "$installed_packages" \
            | sd ' +' '\n' \
            | proximity-sort - \
            | $FZF \
                --multi \
                --nth=2 \
                --tiebreak='index' \
                --layout=reverse-list \
                --prompt='uninstall > ' \
                --preview='chit {1}' \
                --preview-window="left:`get_preview_width`:noborder" \
            | $UNIQUE_SORT | $LINES_TO_LINE
        ")"
    fi

    if [ -n "$packages" ]; then
        run_show "$CARGO_BIN uninstall $packages"
    fi
}


function cargo_recompile {
    local packages="`cargo.list | sed -z 's:\n: :g' | sed 's/ *$//'`"
    if [ -n "$packages" ]; then
        $SHELL -c "$CARGO_BIN install --force $packages"
    fi
}


function cargo.update {
    cargo.init || return $?
    if [ ! -x "$CARGO_BIN" ]; then
        echo " - fatal: cargo exe $CARGO_BIN isn't found!"
        return 1
    fi

    local update_exe="$CARGO_BINARIES/cargo-install-update"
    if [ ! -x "$update_exe" ]; then
        echo " - fatal: cargo-update exe $update_exe isn't found!"
        return 1
    fi

    $SHELL -c "`fs.path $CARGO_BINARIES/rustup` update"
    $CARGO_BIN install-update --all
    return "$?"
}

function cargo.env { eval "cargo.init $@"; return "$?" }
