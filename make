#!/bin/bash

mkdir -p build

PS4='• '
set -x


# -----------------------------------------------------------------------------
# Bootloader build
# -----------------------------------------------------------------------------

nasm src/boot/loader.asm -f bin -o build/loader.bin || exit

# -----------------------------------------------------------------------------
# Kernel build
# -----------------------------------------------------------------------------

nasm src/boot/kernel.asm -f bin -o build/kernel.bin || exit

# -----------------------------------------------------------------------------
# Image build
# -----------------------------------------------------------------------------

nasm conta.asm -f bin -o build/conta.bin || exit

# Criar arquivo de 1.44MB...
dd if=/dev/zero of=build/disk.img bs=512 count=2880

# Criar um sistema de arquivos FAT12 vazio...
/sbin/mkfs.fat -F 12 -n "LOST" build/disk.img

# Copiar o bootloader no primeiro setor do disco...
dd if=build/loader.bin of=build/disk.img conv=notrunc

# Copiar arquivo do kernel para o segundo setor sem montar o sistema de arquivos...
mcopy -i build/disk.img build/kernel.bin "::kernel.bin"

mcopy -i build/disk.img build/conta.bin "::conta.bin"

# Listar arquivos da imagem...
mdir -i build/disk.img

read -p "Pressione Enter para sair"

