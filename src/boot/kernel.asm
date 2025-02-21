bits 16
org 0x0

jmp short main
nop

BPB_OEM     db  'MSWIN4.1'  ; 8 bytes - OEM
BPB_BPS     dw  512         ; 2 bytes - Bytes por setor
BPB_SPC     db  1           ; 1 byte  - Número de setores por cluster
BPB_RSC     dw  1           ; 2 bytes - Número de setores reservados
BPB_FATC    db  2           ; 1 byte  - Contagem da FAT
BPB_DEC     dw  0xe0        ; 2 bytes - Contagem de entradas no diretório raiz
BPB_NTS     dw  2880        ; 2 bytes - Número total de setores (2880 x 512 bytes = 1440 bytes)
BPB_MDT     db  0xf0        ; 1 byte  - Descritor de tipo de mídia (0xf0 = disquete 3½")
BPB_SPFAT   dw  9           ; 2 bytes - Número de setores por FAT
BPB_SPT     dw  18          ; 2 bytes - Setores por trilha
BPB_NH      dw  2           ; 2 bytes - Número de cabeçotes/faces
BPB_HS      dd  0           ; 4 bytes - Número de setores ocultos
BPB_LSC     dd  0           ; 4 bytes - Contagem de grandes setores
;
; BPB estendido (EBR)
;
EBR_DN      db  0               ; 1 byte   - Número do drive (0x00 floppy; 0x80 HDD)
EBR_RES     db  0               ; 1 byte   - Reservado (a menos que fossem flags do Win NT)
EBR_SIG     db  0x29            ; 1 byte   - Assinatura (também poderia ser 0x28)
EBR_VID     dd  0x12345678      ; 4 bytes  - Número de série do volume
EBR_LBL     db  'LEARNING OS'   ; 11 bytes - Rótulo do volume
EBR_SYS     db  'FAT12   '      ; 8 bytes  - Sistema de particionamento

main:

    mov ax, 0x0003  ; Modo de texto 80x25
    int 0x10        ; Chamada de vídeo do BIOS

    ; Configurar segmento de vídeo para o modo de texto
    mov ax, 0xB800  ; Segmento de memória de vídeo no modo de texto
    mov es, ax      ; ES aponta para o segmento de vídeo

    ; Limpar a tela (preencher com espaços em branco)
    xor di, di      ; DI = 0 (início da memória de vídeo)
    mov cx, 80*25   ; Número de caracteres na tela (80 colunas x 25 linhas)
    mov ax, 0x0720  ; AH = 0x07 (cor: cinza claro sobre fundo preto), AL = 0x20 (espaço em branco)
    rep stosw       ; Preenche a tela com espaços em branco

    ; Exibir mensagem de boas-vindas
    mov si, mensagem
    call print_str

    call print_newline

    ;  Carregar GAME.BIN antes de iniciar o terminal
    ;call load_game

    ; Iniciar loop do terminal
    call terminal_loop

    ; Parar a CPU
    cli
    hlt
; ---------------------------------------------------------------------------
;  Função para carregar GAME.BIN
; ---------------------------------------------------------------------------

load_game:
    mov ax, [BPB_SPFAT]  ; Multiplicação de BPB_SPFAT por BPB_FATC. 

    mov bl, [BPB_FATC]   
    xor bh, bh           
    mul bx               
    add ax, [BPB_RSC]    ; AX recebe o LBA do setor do diretório raiz.
    push ax              ; Salva o LBA do diretório raiz na pilha.

    ; Calcula o tamanho do diretório raiz: (32 bytes/entrada * BPB_DEC) / BPB_BPS
    mov ax, [BPB_DEC]
    shl ax, 5           ; Multiplica por 32
    xor dx, dx          ; Zera DX para evitar erros na divisão
    div word [BPB_BPS]  ; Divide pelo tamanho do setor

    test dx, dx         ; Se houver resto, precisa arredondar AX para cima.
    jz read_root_dir    ; Se não houver, salta para a leitura do diretório raiz.
    inc ax              ; Arredonda para cima, se necessário

read_root_dir:
    mov cl, al          ; Passa o tamanho do diretório raiz para o contador (CL).
    pop ax              ; Salva o tamanho do diretório (AX) na pilha.
    mov dl, [EBR_DN]    ; Número da unidade de disco.
    mov bx, buffer_as      ; O endereço do buffer vai para BX.
    call disk_read      ;

    xor bx, bx          ; BX será o contador das tentativas.
    mov di, buffer_as

find_file:
    mov si, game_bin  ; SI recebe o nome do arquivo do kernel (cadeia de bytes a localizar).
    mov cx, 11          ; Tamanho do nome do arquivo no formato FAT12.
    push di             ; Salva o endereço do buffer (root dir) na pilha.

    repe cmpsb          ; Compara sequencialmente cada byte em SI com os bytes com
                        ; os bytes no endereço do buffer (DI) até o valor em CX.
    pop di              ; Restaura DI.
    je file_found     ; Se os bytes casarem. o arquivo do kernel foi encontrado.
               
                     ;
    add di, 32         ; Enquanto não encontrar, repete até o limite de 32 entradas
    inc bx              ; no diretório.
    cmp bx, [BPB_DEC]   ;
    jl find_file      ;

file_not_found:
    mov si, game_nf           ; Se não encontrar o arquivo, imprime mensagem de erro
    call print_str              ;
    jmp halt                    ;
    ;
    ; Determinar o número do cluster do arquivo...
    ;
file_found:
    mov ax, [di + 26]           ; Se encontrar a entrada do arquivo, lê a word no byte 26
    mov [game_cluster], ax    ; e registra o número do primeiro cluster do kernel.
    ;
    ; Escrever a tabela de alocação de arquivos no buffer...
    ;
    mov ax, [BPB_RSC]           ; Passa para AX o setor (LBA) da primeira FAT.
    mov bx, buffer_as             ; 
    mov cl, [BPB_SPFAT]         ; Os 9 setores serão lidos.
    mov dl, [EBR_DN]            ;
    call disk_read              ;


    ;
    ; Escrita do conteúdo do arquivo em outro segmento da memória...
    ;
    mov bx, game_ls           ; Redefine segmento de dados para 0x3000:0x0000,
    mov es, bx                  ; que é onde os bytes do arquivo serão escritos
    mov bx, game_lo           ; na memória (endereço incial: 0x30000).

load_game_loop:
    mov ax, [game_cluster]  ; Obtém cluster atual

    add ax, 31              ; Ajusta para setor correto
    mov cl, 1               ; Lê 1 setor
    mov dl, [EBR_DN]
    call disk_read          ; Lê do disco

    add bx, [BPB_BPS]       ; Avança buffer
    mov ax, [game_cluster]  ; Obtém próximo cluster
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    mov si, buffer_as
    add si, ax
    mov ax, [ds:si]
    
    test dx, dx
    jz game_is_even

is_odd:                         ; Exemplo: 2 * 3 / 2 = 6 / 2 = índice do cluster 3 (resto zero)
    shr ax, 4                   ; Exemplo: 0x0030 >> 4 => próximo cluster é 0x0003
    jmp game_next_cluster

game_is_even:
    and ax, 0x0fff

game_next_cluster:
    cmp ax, 0x0ff8   ; Verifica fim do arquivo
    jae read_end

    mov [game_cluster], ax  ; Continua lendo
    jmp load_game_loop

read_end:                       ; Encontrado o fim do arquivo, passa o endereço do arquivo na memória
    mov dl, [EBR_DN]            ; para o registrador do segmento de dados (DS).
    mov ax, game_ls           ;
    mov ds, ax                  ;
    mov es, ax                  ;
    jmp game_ls:game_lo     ; Salta para o endereço do kernel na memória.

; ---------------------------------------------------------------------------
;  Função para ler setores do disco (disk_read)
; ---------------------------------------------------------------------------

lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [BPB_SPT]  ; AX = LBA / setores por trilha, DX = LBA % setores por trilha
    inc dx              ; Setor = (LBA % setores por trilha) + 1
    mov cx, dx          ; CX = setor

    xor dx, dx
    div word [BPB_NH]   ; AX = cilindro, DX = cabeça
    mov dh, dl          ; DH = cabeça
    mov ch, al          ; CH = cilindro (8 bits baixos)
    shl ah, 6
    or cl, ah           ; CL = [cilindro alto (2 bits) + setor (6 bits)]

    pop ax              ; Passa o número da unidade (DL) para AX.
    mov dl, al          ; Passa o número da unidade de volta para DL.
    ;
    ; Restauração do LBA...
    ; 
    pop ax              ; Devolve LBA para AX (já não será necessário na leitura).
    ret

disk_read:
    pusha               ; Salva registradores temporários

    push cx             ; Salva contagem de setores
    call lba_to_chs     ; Converte LBA para CHS

    pop ax              ; Obtém número de setores a ler (AL)
    mov ah, 0x02        ; Função de leitura de setores
    mov di, 3           ; Número de tentativas

.retry:
    int 0x13            ; Chama a interrupção do BIOS para leitura de disco
    jnc .done           ; Se sucesso (CF=0), termina

    call disk_reset     ; Se falhar, tenta reiniciar a unidade
    dec di              ; Decrementa contador de tentativas
    test di, di         ; Se ainda houver tentativas, tenta de novo
    jnz .retry

    call disk_error

.done:
    popa
    ret
; ---------------------------------------------------------------------------
;  Função para reiniciar unidade de disco (disk_reset)
; ---------------------------------------------------------------------------
disk_reset:
    pusha
    mov ah, 0        ; Função para reiniciar unidade
    int 0x13
    jnc .done       ; Se CF zerar, reset ok...
    call disk_error
.done:
    popa            ; Restaura registradores
    ret

disk_error:
; -----------------------------------------------------------------------------
    mov si, err_disk_read       ; Mensagem de erro
    call print_str

    mov ah, 0           ; Função para ler o teclado
    int 0x16            ; Espera um tecla pressionada
    jmp 0xffff:0000     ; Salta para o inicio do BIOS na memória
; ---------------------------------------------------------------------------
;  Função para converter LBA para CHS (lba_to_chs)
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; Terminal Loop
; ---------------------------------------------------------------------------
terminal_loop:
    mov si, buffer   ; Ponteiro para armazenar entrada
.terminal:
    mov byte [si], 0 ; Zerar buffer
    call read_char   ; Ler caractere do teclado
    cmp al, 0x0D     ; Verificar se é Enter
    je .check_command
    mov [si], al
    inc si
    call print_char
    jmp .terminal

.check_command:
    mov si, buffer
    cmp byte [si], 'r'  
    jne .check_g
    inc si
    cmp byte [si], 0
    jne .continue
    call restart

.check_g:
    mov si, buffer
    cmp byte [si], 'g'  
    jne .continue
    inc si
    cmp byte [si], 0
    jne .continue
    call load_game

.continue:
    call print_newline
    jmp .terminal

; ---------------------------------------------------------------------------
;  Funções auxiliares
; ---------------------------------------------------------------------------
read_char:
    mov ah, 0x00
    int 0x16
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

print_newline:
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char
    ret

halt:
    cli                 ; Limpa a flag de interrupções
    hlt                 ; Para a CPU
; ---------------------------------------------------------------------------
;  Dados necessários para a conversão de valores hexadecimais
; ---------------------------------------------------------------------------

restart:
    mov ax, 0x0000
    mov es, ax
    mov dx, 0x1234
    int 0x19
    ret

print_str:
    mov ah, 0x0E
.print_loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .print_loop
.done:
    ret

; ---------------------------------------------------------------------------
;  Dados
; ---------------------------------------------------------------------------
mensagem db "Bem-vindo ao meu Sistema Operacional", 0
msg_load db "carregando aplicacao", 0
buffer db 2, 0  ; Buffer para entrada do usuário
hex_digits db '0123456789ABCDEF'

err_disk_read       db `Disk error!\r\nPress any key to reboot...`

game_bin            db 'GAME    BIN'   ; Nome do arquivo
game_cluster dw 0           ; Primeiro cluster
game_ls equ 0x4000         ; Segmento de carga
game_lo equ 0x0000             ; Offset de carga
game_nf           db `GAME.BIN not fount!\r\n`

buffer_as: