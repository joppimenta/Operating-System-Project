# Projeto de Sistema Operacional

Este projeto consiste na implementação de um sistema operacional minimalista, que inclui um bootloader compatível com o sistema de arquivos FAT12 e um kernel simples. O sistema pode ser executado diretamente em um disquete de 1.44MB e testado em ambientes de emulação como QEMU ou Bochs.

---

## Funcionalidades

- Bootloader compatível com FAT12
- Leitura de arquivos do disquete (FAT12)
- Modo de vídeo 80x25 (modo texto)
- Exibição de mensagens na tela
- Terminal interativo simples
- Reinicialização do sistema via terminal ("r" + Enter)

---

## Estrutura do Projeto

```plaintext
/Projeto-SO
├── build/                 # Diretório onde os binários são gerados
├── src/
│   ├── boot/
│   │   ├── kernel.asm     # Código principal do sistema operacional
│   │   ├── loader.asm     # Bootloader (carrega o kernel)
│   ├── lib/
│   │   ├── dev/
│   │   │   ├── fat12header.asm # Configuração do FAT12 (BPB)
│   │   ├── stdio/
│   │   │   ├── puts.asm        # Função para exibir strings na tela
│   │   ├── utils/
│   │   │   ├── save_and_restore_registers.asm # Macros para salvar e restaurar registradores
├── make             # Script para compilar e criar imagem de disco
├── run              # Script para executar o sistema no QEMU
├── README.md        # Documentação do projeto
```

## Compilação e Execução

### Requisitos

Para compilar e executar o projeto, é necessário ter os seguintes pacotes instalados:

```bash
sudo apt update
sudo apt install nasm mtools qemu-system-x86
```

## Compilação do Bootloader e do Kernel

Para compilar o projeto e gerar a imagem de disco, execute o seguinte comando:

```
bash make
```

Este script realiza as seguintes ações:

* Compila o bootloader e o kernel utilizando NASM.
* Cria uma imagem FAT12 de 1.44MB (disk.img).
* Copia o bootloader para o primeiro setor do disco.
* Adiciona o kernel à imagem FAT12.

Se a compilação for bem-sucedida, a saída será:

```bash
Volume in drive : is LOST
Directory for ::/
KERNEL   BIN     1024  2025-02-19  12:34
```

## Execução do Sistema Operacional no QEMU

Para executar o sistema operacional, utilize o seguinte comando:

```
bash run
```

Este comando verifica a existência de disk.img e inicia o QEMU com a imagem montada como disquete.

## Descrição Técnica

### Bootloader (loader.asm)

O bootloader é carregado pela BIOS no endereço 0x7C00 e é responsável por:

1. Inicializar o modo de vídeo (modo texto 80x25).
2. Ler o diretório raiz do FAT12 para localizar o kernel.
3. Carregar o kernel na memória e executá-lo.
   
## Sistema de Arquivos FAT12
O FAT12 é um sistema de arquivos simples, utilizado em disquetes. O arquivo `fat12header.asm` define o BIOS Parameter Block (BPB), permitindo ao bootloader acessar arquivos armazenados no disco.

## Kernel
O kernel inclui um terminal básico que aceita entrada do usuário. Se o usuário digitar "r" e pressionar Enter, o sistema será reiniciado.

## Macros Auxiliares

* `puts.asm`: Função para imprimir strings na tela.
* `save_and_restore_registers.asm`: Macros para salvar e restaurar registradores.

