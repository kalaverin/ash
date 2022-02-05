if [ -z "$ZSH_VERSION" ]; then
    cmd="`$(which ps) -p\$\$ -ocomm=`"

    if [ ! -x "`which zsh`" ]; then
        printf " ** halt ($0): I was made for zsh, not for $cmd; please, install zsh\n" >&2
    else
        printf " ** halt ($0): I was made for zsh, not for $cmd; please change default shell: \"sudo chsh -s `which zsh` $USER\" and run again\n" >&2
    fi

elif [ -z "${(M)zsh_eval_context:#file}" ]; then
    printf " ** halt ($0): do not call me, just include\n" >&2

    function compat.compatibility() {
        echo '123'
        # source $ASH/boot/setup/compat.sh && compat.check && return $?
    }


else
    printf " ** halt ($0): do not call me, just include2\n" >&2

fi
