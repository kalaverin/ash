if [ -z "$ASH_HTTP" ]; then
    if [ -x "`which curl`" ]; then
        export ASH_HTTP="`which curl` -fsSL"
        printf " ++ info ($this): using curl `curl --version | head -n 1 | awk '{print $2}'`: $ASH_HTTP" 1>&2

    elif [ -x "`which wget`" ]; then
        export ASH_HTTP="`which wget` -qO -"
        printf " ++ info ($this): using wget `wget --version | head -n 1 | awk '{print $3}'`: $ASH_HTTP" 1>&2

    elif [ -x "`which fetch`" ]; then
        export ASH_HTTP="`which fetch` -qo - "
        printf " ++ info ($this): using fetch: $ASH_HTTP" 1>&2

    elif [ -x "`which http`" ]; then
        export ASH_HTTP="`which http` -FISb"
        printf " ++ info ($this): using httpie `http --version`: $ASH_HTTP" 1>&2

    else
        unset ASH_HTTP
        printf " ** halt ($this) fatal: install curl, wget, fetch or httpie" 1>&2
    fi
fi


if [ -x "`which zstd`" ]; then
    export ASH_PAQ="`which zstd` -0 -T0"
    export ASH_UPAQ="`which zstd` -qd"

elif [ -x "`which lz4`" ] && [ -x "`which lz4cat`" ]; then
    export ASH_PAQ="`which lz4` -1 - -"
    export ASH_UPAQ="`which lz4` -d - -"

elif [ -x "`which xz`" ] && [ -x "`which xzcat`" ]; then
    export ASH_PAQ="`which xz` -0 -T0"
    export ASH_UPAQ="`which xzcat`"

else
    export ASH_PAQ="`which gzip` -1"
    export ASH_UPAQ="`which zcat`"
fi


#


[ -z "$sourced" ] && declare -aUg sourced=()
local this="$(fs.ash.self "$0" 'boot/init.sh')"


echo '12312312312312123'
echo "`fs.ash.link.is 'zsh'` zsh $?"
echo '12312312312312123'
echo "`fs.ash.link.is '/bin/zsh'` /bin/zsh $?"

echo '12312312312312123'
echo "`fs.ash.link.is 'zsh' 'zsh'` zsh zsh$?"
echo '12312312312312123'
echo "`fs.ash.link.is '/bin/zsh' 'zsh'` /bin/zsh zsh$?"
echo '12312312312312123'


 # || fs.ash.link '/bin/zsh'


if [[ "${sourced[(Ie)$this]}" -eq 0 ]]; then
    sourced+=("$this")

    if [ -n "$(uname | grep -i freebsd)" ]; then
        export ASH_PLATFORM="bsd"
        fs.ash.link '/usr/local/bin/gnuls' 'ls'   >/dev/null
        fs.ash.link '/usr/local/bin/grep'  'grep' >/dev/null


    elif [ -n "$(uname | grep -i darwin)" ]; then
        export ASH_PLATFORM="mac"
        fs.ash.link '/usr/local/bin/gls'   'ls'   >/dev/null
        fs.ash.link '/usr/local/bin/ggrep' 'grep' >/dev/null
        export PATH="$PATH:/Library/Apple/usr/bin"

    else
        if [ -n "$(uname | grep -i linux)" ]; then
            export ASH_PLATFORM="linux"
        else
            echo " - ERROR: unsupported OS!" >&2
            printf " ** warn ($this): generic Linux, `uname -srv`" 1>&2
            export ASH_PLATFORM="unknown"
        fi
    fi

    if [ "$ASH_PLATFORM" = 'bsd' ] || [ "$ASH_PLATFORM" = 'mac' ]; then
        fs.ash.link '/usr/local/bin/gcut'      'cut'      >/dev/null
        fs.ash.link '/usr/local/bin/gfind'     'find'     >/dev/null
        fs.ash.link '/usr/local/bin/ghead'     'head'     >/dev/null
        fs.ash.link '/usr/local/bin/greadlink' 'readlink' >/dev/null
        fs.ash.link '/usr/local/bin/grealpath' 'realpath' >/dev/null
        fs.ash.link '/usr/local/bin/gsed'      'sed'      >/dev/null
        fs.ash.link '/usr/local/bin/gtail'     'tail'     >/dev/null
        fs.ash.link '/usr/local/bin/gtar'      'tar'      >/dev/null
        fs.ash.link '/usr/local/bin/gxargs'    'xargs'    >/dev/null
        export ASH_MD5_PIPE="`which md5`"

    else
        export ASH_MD5_PIPE="`which md5sum` | `which cut` -c -32"
    fi
fi
