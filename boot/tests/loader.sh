#!/bin/zsh

function separate() {
    local msg="$*"
    if [ -n "$msg" ]; then
        let offset="$COLUMNS - ${#msg} - 7"
        local ends="`head -c $offset < /dev/zero | tr '\0' '-'`"
        printf "\n\n ---- $msg $ends\n"
    else
        local ends="`head -c $COLUMNS < /dev/zero | tr '\0' '-'`"
        printf "\n\n$ends"
    fi
}

cmd="`$(which ps) -p\$\$ -ocomm=`"

if [ ! "$cmd" = 'zsh' ]; then
    printf " ** fatal ($0): I was made for zsh, not for $cmd\n" >&2

elif [ -n "${(M)zsh_eval_context:#file}" ]; then
    printf " ** fatal ($0): do not source me, just run me\n" >&2

elif [ -z "`which sudo`" ]; then
    printf " ** fatal ($0): sudo required"

else
    SHELLS=(
        sh
        ksh
        csh
        tcsh
        fish
        bash
        zsh
    )

    sudo="`which sudo`"
    cmd="$sudo -Hi -u $USER sh -c"
    dir=$(realpath "`dirname "$0"`/../")

    for name in $SHELLS; do
        local exe="$commands[$name]"

        [ ! -x "$exe" ] && continue

        command="$cmd \"$exe $dir/loader.sh\""
        separate "with $name: $command"
        zsh -c "$command"

        command="$cmd \"cat $dir/loader.sh | $exe\""
        separate "pipe to $name: $command"
        zsh -c "$command"
    done
fi
