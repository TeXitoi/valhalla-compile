#!/bin/sh

work_dir="$PWD"
local="$work_dir/local"
export PKG_CONFIG_PATH=":$local/lib/pkgconfig"
export CPPFLAGS="-DBOOST_SPIRIT_THREADSAFE -DBOOST_NO_CXX11_SCOPED_ENUMS"
export CXXFLAGS="-I$local/include"
export INSTALL="/usr/bin/install -C"

usage () {
    printf 'Usage: %s [OPTION]...\n' "$0"
    printf 'Clone, compile and install Valhalla.\n\n'
    printf '  -h  print this message and exit\n'
    printf '  -a  skip autogen\n'
    printf '  -c  skip configure\n'
    printf '  -m  update to master\n'
}
skip_autogen=NO
skip_configure=NO
goto_master=NO
while getopts 'hacm' option; do
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
        *)
            usage
            exit 1
            ;;
    esac
done

cd "$work_dir"
mkdir -p "$local"

run () {
    echo '>' $*
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
    if [ ! -d "$project" ]; then
        run git clone --recursive "$git_base_url${project}.git"
    fi
    run cd "$project"
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
        run ./configure --prefix="$local"
    fi
    run make -j`nproc`
    run make install
    cd ..
}

clone_compile_install https://github.com/kevinkreiser/ prime_server

for project in midgard baldr sif meili skadi mjolnir loki odin thor tyr tools; do
    clone_compile_install https://github.com/valhalla/ "$project"
done
