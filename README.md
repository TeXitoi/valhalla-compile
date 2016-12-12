# valhalla-compile [![Build Status](https://travis-ci.org/TeXitoi/valhalla-compile.svg?branch=master)](https://travis-ci.org/TeXitoi/valhalla-compile)


A script to compile [Valhalla](https://github.com/valhalla)

## Usage

```
$ ./compile.sh -h
Usage: ./compile.sh [OPTION]...
Clone, compile and install Valhalla.

  -h          print this message and exit
  -a          skip autogen
  -c          skip configure
  -s <regex>  skip projects matching regex
  -m          update to master
  -t          skip test

```

Everything will be cloned in the current directory. You can use the file `conf.sh` in the current directory to tune the compilation process. For example:

```sh
CXXFLAGS='-O2 -g'
```

will do a optimized build with debug info. Everything will be installed in the `local` directory of the current directory.
