#!/bin/sh

[ -r ./conf.sh ] && . ./conf.sh

work_dir="$PWD"
local="$work_dir/local"
zmq_git="https://github.com/zeromq/"
export PKG_CONFIG_PATH="$local/lib/pkgconfig:$PKG_CONFIG_PATH"
export CPPFLAGS="$CPPFLAGS -DBOOST_SPIRIT_THREADSAFE -DBOOST_NO_CXX11_SCOPED_ENUMS"
export CXXFLAGS="$CXXFLAGS -I$local/include"
export INSTALL="/usr/bin/install -C"

usage () {
    printf 'Usage: %s [OPTION]...\n' "$0"
    printf 'Clone, compile and install Valhalla.\n\n'
    printf '  -h          print this message and exit\n'
    printf '  -a          skip autogen\n'
    printf '  -c          skip configure\n'
    printf '  -s <regex>  skip projects matching regex\n'
    printf '  -m          update to master\n'
    printf '  -t          skip test\n'
}
skip_autogen=NO
skip_configure=NO
skip_test=NO
skip_project=''
goto_master=NO
while getopts 'hacms:t' option; do
    case "$option" in
        h)
            usage
            exit 0
            ;;
        a)
            echo '+ Will skip autogen'
            skip_autogen=YES
            ;;
        c)
            echo '+ Will skip configure'
            skip_configure=YES
            ;;
        m)
            echo '+ Will update to master'
            goto_master=YES
            ;;
        s)
            skip_project="$OPTARG"
            printf '+ Will skip projects matching %s\n' "$skip_project"
            ;;
        t)
            echo '+ Will skip test'
            skip_test=YES
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

cd "$work_dir"
mkdir -p "$local"

run () {
    printf "compile: Entering directory '%s'\n" "$PWD"
    printf '> %s\n' "$*"
    $* || exit 1
}

is_dirty () {
    git diff-index --quiet HEAD || return 0 # uncommited files in index
    u="$(git ls-files --exclude-standard --others)" || return 0 # ls-files errored
    [ -z "$u" ] || return 0 # there is untracked files
    return 1
}

clone_compile_install () {
    git_base_url="$1"
    project="$2"
    if [ -n "$skip_project" ] && echo "$project" | grep -q "$skip_project"; then
        printf '+ Skipping %s\n' "$project"
        return 0
    fi
    if [ ! -d "$project" ]; then
        run git clone --recursive "$git_base_url${project}.git"
    fi
    cd "$project"
    if [ "$goto_master" = YES ]; then
        if is_dirty; then
            printf '+ %s is dirty, stopping.\n' "$project"
            exit 1
        fi
        run git checkout master
        run git pull --ff-only --recurse-submodules
    fi
    if [ "$skip_autogen" != YES ]; then
        run ./autogen.sh
    fi
    if [ "$skip_configure" != YES ]; then
        run ./configure --prefix="$local" $CONFIGUREFLAGS
    fi
    run make -j`nproc`
    if [ "$skip_test" != YES -a "$git_base_url" != "$zmq_git" ]; then
        run make -j`nproc` test
    fi
    run make install
    cd ..
}

clone_compile_install "$zmq_git" libzmq
clone_compile_install "$zmq_git" czmq
clone_compile_install https://github.com/kevinkreiser/ prime_server

for project in midgard baldr sif skadi mjolnir meili loki odin thor tyr tools; do
    clone_compile_install https://github.com/valhalla/ "$project"
done
