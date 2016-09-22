#!/bin/sh

work_dir="$PWD"
local="$work_dir/local"
export PKG_CONFIG_PATH=":$local/lib/pkgconfig"
export CPPFLAGS="-DBOOST_SPIRIT_THREADSAFE -DBOOST_NO_CXX11_SCOPED_ENUMS"
export CXXFLAGS="-I$local/include"

cd "$work_dir"
mkdir -p "$local"

run () {
    echo '>' $*
    $* || exit 1
}

clone_compile_install () {
    git_base_url="$1"
    project="$2"
    if [ ! -d "$project" ]; then
        run git clone --recursive "$git_base_url${project}.git"
    fi
    run cd "$project"
    run ./autogen.sh
    run ./configure --prefix="$local"
    run make -j`nproc`
    run make install
    cd ..
}

clone_compile_install https://github.com/kevinkreiser/ prime_server

for project in midgard baldr sif meili skadi mjolnir loki odin thor tyr tools; do
    clone_compile_install https://github.com/valhalla/ "$project"
done
