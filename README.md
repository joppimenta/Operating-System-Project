# Projeto de Sistema Operacional

Este projeto consiste na criação de um sistema operacional minimalista que roda em um disquete no formato **FAT12**. O sistema inclui um **bootloader**, um **kernel** básico, e um **jogo da adivinhação** escrito em Assembly x86. O projeto é compilado e executado usando scripts Bash, e pode ser testado no emulador **QEMU**.

## Estrutura do Projeto

O projeto é composto pelos seguintes componentes:

1. **Bootloader**: Responsável por carregar o sistema operacional a partir do disquete.
2. **Kernel**: O núcleo do sistema operacional, que gerencia a execução de programas básicos.
3. **Jogo da Adivinhação**: Um pequeno jogo escrito em Assembly que permite ao usuário adivinhar um número aleatório.
4. **Scripts de Compilação e Execução**:
   - `make`: Compila o bootloader e o kernel, cria uma imagem de disquete FAT12 e copia os arquivos necessários.
   - `run`: Executa o sistema operacional no emulador QEMU.

## Tecnologias Utilizadas

- **Assembly x86**: Linguagem de baixo nível usada para escrever o bootloader, o kernel e o jogo.
- **NASM**: Assembler usado para compilar o código Assembly.
- **FAT12**: Sistema de arquivos usado para organizar os arquivos no disquete.
- **QEMU**: Emulador usado para executar o sistema operacional.
- **Bash**: Linguagem de script usada para automatizar a compilação e execução do sistema.

## Como Compilar e Executar o Projeto

### Pré-requisitos

- **NASM**: Para compilar o código Assembly.
- **QEMU**: Para emular o sistema operacional.
- **mkfs.fat**: Para criar o sistema de arquivos FAT12.
- **Bash**: Para executar os scripts.

### Passos para Compilar e Executar

1. **Clone o repositório**

## Compile o projeto:
Execute o script make para compilar o bootloader, o kernel e criar a imagem do disquete:

 ```
 bash make
 ```

## Este script faz o seguinte:

- Compila o bootloader `(loader.asm)` e o kernel `(kernel.asm)`.

- Cria uma imagem de disquete FAT12 `(disk.img)`.

- Copia o bootloader, o kernel e outros arquivos para a imagem do disquete.

Execute o sistema no QEMU:
Após a compilação, execute o script `run` para iniciar o sistema operacional no QEMU:

 ```
 bash run
 ```

Este script carrega a imagem do disquete `(disk.img)` no QEMU e inicializa o sistema.

## Estrutura do Código
### Bootloader `(loader.asm)`
O bootloader é responsável por carregar o sistema operacional a partir do disquete. Ele implementa funções para ler setores do disco, converter endereços LBA para CHS, e exibir mensagens na tela.

### Kernel `(kernel.asm)`
O kernel é o núcleo do sistema operacional. Ele gerencia a execução de programas básicos, como o jogo da adivinhação.

### Jogo da Adivinhação `(game.asm)`
Um jogo simples onde o usuário deve adivinhar um número aleatório entre 0 e 15. O jogo fornece feedback se o palpite do usuário é muito alto, muito baixo ou correto.

### Make e Run
make: Automatiza a compilação do bootloader, do kernel, a criação da imagem do disquete e a cópia dos arquivos necessários.

run.: Executa o sistema operacional no emulador QEMU.

## Explicação Detalhada do Código
### Bootloader
O bootloader é escrito em Assembly de 16 bits e é carregado pelo BIOS no endereço `0x7C00`. Ele lê o sistema de arquivos FAT12 para carregar o kernel `(KERNEL.BIN)` na memória e transferir o controle para ele.

### Kernel
O kernel é responsável por inicializar o sistema e executar programas básicos. Ele usa interrupções do BIOS para interagir com o teclado e a tela.

### Jogo da Adivinhação
O jogo gera um número aleatório entre 0 e 15 e solicita que o usuário adivinhe o número. O programa fornece feedback e repete até que o usuário acerte o número.

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
├── conta.asm
├── game.asm         # Código do jogo inicializado pelo kernel
├── make             # Script para compilar e criar imagem de disco
├── run              # Script para executar o sistema no QEMU
├── README.md        # Documentação do projeto
```
