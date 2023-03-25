#!/usr/bin/env bash

set -e

name=${1%.asm}

nasm -felf64 $1 -o "$name.o"

ld -o $name "$name.o"

chmod +x "./$name"

"./$name"
