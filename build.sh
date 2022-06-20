#!/bin/bash

rm -rf build
mkdir -p build
fasm src/main.asm build/main.bin
dd if=/dev/zero of=build/bootloader.img ibs=1k count=1440
dd if=build/main.bin of=build/bootloader.img conv=notrunc
mkisofs -b bootloader.img -v -r -l -o build/cd.iso build