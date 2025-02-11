#!/bin/bash
set -x  # Habilitar modo de debug para mostrar comandos e saídas

clear

# Compilação dos arquivos de bootloader e kernel
nasm -f bin -o bootloader.bin bootloader.asm
nasm -f bin -o kernel.bin microkernel.asm

# Verificação do conteúdo do kernel


# Criação da imagem de disco com 100MB
dd if=/dev/zero of=disk.img bs=512 count=20480

# Particionar a imagem do disco
parted disk.img --script -- mklabel msdos
parted disk.img --script -- mkpart primary 1MiB 9MiB
parted disk.img --script -- set 1 boot on

# Verificação com parted

# Formatar a partição diretamente
mkfs.fat -F 12 -n "myOS" disk.img

# Determinar o setor inicial da partição

#fdisk -l disk.img
#parted disk.img print

# Copiar o kernel diretamente para a partição no offset correto
dd if=kernel.bin of=disk.img bs=512 seek=2 conv=notrunc


# Copiar o bootloader para o setor de inicialização do MBR sem sobrescrever a tabela de partições
dd if=bootloader.bin of=disk.img bs=446 count=1 conv=notrunc
parted disk.img set 1 boot on

# Verificação com fdisk e parted
# Executar no QEMU especificando o formato raw
qemu-system-x86_64 -drive format=raw,file=disk.img
