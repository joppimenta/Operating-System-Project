; -----------------------------------------------------------------------------
; BOOTLOADER
; -----------------------------------------------------------------------------
    bits 16
    org 0x7c00
; -----------------------------------------------------------------------------
; Cabeçalho FAT12
; -----------------------------------------------------------------------------
;
; BIOS Parameter Block (BPB)
;
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
; -----------------------------------------------------------------------------
; Código do boot
; -----------------------------------------------------------------------------
main:
; -----------------------------------------------------------------------------
; Definição dos segmentos de dados...
; -----------------------------------------------------------------------------
    xor ax, ax      ; Registra 0x0000 em AX
    mov ds, ax      ; Segmento de Dados DS=AX=0x0000
    mov es, ax      ; Segmento de Dados ES=AX=0x0000
; -----------------------------------------------------------------------------
; Definição do topo da pilha...
; -----------------------------------------------------------------------------
    mov ss, ax      ; Segmento do endereçamento da pilha: SS=AX=0x0000
    mov sp, 0x7c00  ; Todos os 'push' serão endereçados a partir daqui
; -----------------------------------------------------------------------------
; Limpar a tela...
; -----------------------------------------------------------------------------
clr_screen:
    mov al, 0x03    ; AX=0x0003 = Modo texto VGA 80x25, char 9x16, 16 cores
    int 0x10
; -----------------------------------------------------------------------------
; Imprimir mensagem...
; -----------------------------------------------------------------------------
    mov si, msg         ; {si} recebe endereço da string
    mov cx, msg_len     ; Contador recebe tamanho da string
    call print_str
; -----------------------------------------------------------------------------
; Carga do kernel...
; -----------------------------------------------------------------------------
    ;
    ; Cálculo do início do segmento 3: (BPB_SPFAT x BPB_FATC) + BPB_RSC... - Numero de Setores que ele vai pular ate achar o diretorio raiz
    ;
    mov ax, [BPB_SPFAT] ; Multiplicação de BPB_SPFAT por BPB_FATC. 
    mov bl, [BPB_FATC]  ;
    xor bh, bh          ;
    mul bx              ;
    add ax, [BPB_RSC]   ; AX recebe o LBA do setor do diretório raiz.
    push ax             ; Salva o LBA do diretório raiz na pilha.
    ;
    ; Calcula o tamanho do diretório raiz: (32 bytes/entrada * BPB_DEC) / BPB_BPS
    ;
    mov ax, [BPB_DEC]
    shl ax, 5           ; Deslocar 5 bits à direita é o mesmo que multiplicar por 2**5 (32).
    xor dx, dx          ; Zera DX para o resto.
    div word [BPB_BPS]  ; Executa a divisão e registra o quociente em AX.
                        ;
    test dx, dx         ; Se houver resto, precisa arredondar AX para cima.
    jz read_root_dir    ; Se não houver, salta para a leitura do diretório raiz.
    inc ax              ;

read_root_dir:
    mov cl, al          ; Passa o tamanho do diretório raiz para o contador (CL).
    pop ax              ; Salva o tamanho do diretório (AX) na pilha.
    mov dl, [EBR_DN]    ; Número da unidade de disco.
    mov bx, buffer      ; O endereço do buffer vai para BX.
    call disk_read      ;
    ;
    ; Localizar o nome do arquivo do kernel (KERNEL  BIN)...
    ;
    xor bx, bx          ; BX será o contador das tentativas.
    mov di, buffer      ; DI recebe o endereço do buffer (root dir) para a comparação.
find_kernel:
    mov si, kernel_bin  ; SI recebe o nome do arquivo do kernel (cadeia de bytes a localizar).
    mov cx, 11          ; Tamanho do nome do arquivo no formato FAT12.
    push di             ; Salva o endereço do buffer (root dir) na pilha.
    repe cmpsb          ; Compara sequencialmente cada byte em SI com os bytes com
                        ; os bytes no endereço do buffer (DI) até o valor em CX.
    pop di              ; Restaura DI.
    je kernel_found     ; Se os bytes casarem. o arquivo do kernel foi encontrado.
                        ;
    add di, 32          ; Enquanto não encontrar, repete até o limite de 32 entradas
    inc bx              ; no diretório.
    cmp bx, [BPB_DEC]   ;
    jl find_kernel      ;

kernel_not_found:
    mov si, kernel_nf           ; Se não encontrar o arquivo, imprime mensagem de erro
    mov cx, kernel_nf_len       ; e termina a execução do boot.
    call print_str              ;
    jmp halt                    ;
    ;
    ; Determinar o número do cluster do arquivo...
    ;
kernel_found:
    mov ax, [di + 26]           ; Se encontrar a entrada do arquivo, lê a word no byte 26
    mov [kernel_cluster], ax    ; e registra o número do primeiro cluster do kernel.
    ;
    ; Escrever a tabela de alocação de arquivos no buffer...
    ;
    mov ax, [BPB_RSC]           ; Passa para AX o setor (LBA) da primeira FAT.
    mov bx, buffer              ; 
    mov cl, [BPB_SPFAT]         ; Os 9 setores serão lidos.
    mov dl, [EBR_DN]            ;
    call disk_read              ;
    ;
    ; Escrita do conteúdo do arquivo em outro segmento da memória...
    ;
    mov bx, kernel_ls           ; Redefine segmento de dados para 0x2000:0x0000,
    mov es, bx                  ; que é onde os bytes do arquivo serão escritos
    mov bx, kernel_lo           ; na memória (endereço incial: 0x20000).

load_kernel_loop:
    mov ax, [kernel_cluster]    ; O número do primeiro cluster do arquivo é passado para AX.
    add ax, 31                  ; A primeira entrada do primeiro cluster do arquivo (2) na FAT refere-se
                                ; ao setor físico 33 do disco (início do segmento de dados)!
    mov cl, 1                   ; Lê um setor da região de dados do disco.
    mov dl, [EBR_DN]            ; Unidade de disco.
    call disk_read              ;

    add bx, [BPB_BPS]           ; Incrementa o destino (ES:BX) em 512 bytes (1 setor).

    mov ax, [kernel_cluster]    ; Restaura o número do cluster inicial em AX. 
    mov cx, 3                   ; O cluster seguinte estará 1,5 bytes adiante na FAT,
    mul cx                      ; por isso multiplicamos o número do cluster por 3
    mov cx, 2                   ; e dividimos por 2.
    div cx                      ; AX receberá a parte inteira do número do cluster seguinte.

    mov si, buffer              ; Passa o endereço da FAT na memória (buffer) para SI.
    add si, ax                  ; Soma o número do próximo cluster ao endereço do buffer.
    mov ax, [ds:si]             ; Passa para AX o conteúdo dos 2 bytes no endereço da FAT.
    test dx, dx                 ; Verifica se a divisão teve um resto.
    jz is_even                  ; Se o resto foi zero, o índice do próximo cluster é par.

                                ; FAT
                                ; 0          1         2         3         4         5
                                ; | 0x?  0x? | 0x?|0x? | 0x? 0x? | 0x0|0x0 | 0x3|0x0 | 0x0 0x4 |
                                ; | RES.          | RES.         |<--- CLUSTER 3 --->|
                                ;                                          |<--- CLUSTER 4 --->|
                                   
is_odd:                         ; Exemplo: 2 * 3 / 2 = 6 / 2 = índice do cluster 3 (resto zero)
    shr ax, 4                   ; Exemplo: 0x0030 >> 4 => próximo cluster é 0x0003
    jmp next_cluster

is_even:                        ; Exemplo: 3 * 3 / 2 = 9 / 2 = índice do cluster 4 (resto 1)
    and ax, 0x0fff              ; Exemplo: 0x3004 & 0x0fff => próximo cluster é 0x0004

next_cluster:
    cmp ax, 0x0ff8              ; Cluster máximo: indicado na FAT quando não há mais um cluster seguinte.
    jae read_end                ; Quando chegar aqui, para de ler.

    mov [kernel_cluster], ax    ; Enquanto não encontrar 0xff8, atualiza o cluster corrente, lê o setor
    jmp load_kernel_loop        ; correspondente no disco, escreve no segmento da memória e continua o loop.
   ;
   ; Executar o conteúdo do arquivo do kernel...
   ;
read_end:                       ; Encontrado o fim do arquivo, passa o endereço do arquivo na memória 
    mov dl, [EBR_DN]            ; para o registrador do segmento de dados (DS).
    mov ax, kernel_ls           ;
    mov ds, ax                  ;
    mov es, ax                  ;
    jmp kernel_ls:kernel_lo     ; Salta para o endereço do kernel na memória.
; -----------------------------------------------------------------------------
; Parada da CPU...
; -----------------------------------------------------------------------------
halt:
    cli                 ; Limpa a flag de interrupções
    hlt                 ; Para a CPU
; -----------------------------------------------------------------------------
; SUBS
; -----------------------------------------------------------------------------
print_str:
; -----------------------------------------------------------------------------
; Imprimir strings em {si} com tamanho em {cx}...
; -----------------------------------------------------------------------------
    pusha
    mov ah, 0x0e        ; Escrever caractere no TTY
.char_loop:
    lodsb               ; Carrega byte corrente em {al} e incrementa o endereço
    int 0x10
    loop .char_loop     ; Repete e decrementa o contador
    popa
    ret
; -----------------------------------------------------------------------------
lba_to_chs:
; -----------------------------------------------------------------------------
; Converte endereço LBA para CHS
;
; Parâmetro:
;   AX - Endereço LBA
; Retorno:
;   CX - Bits 0 a 5 : número do setor (6 bits)
;   CX - Bits 6 a 15: número do cilindro (10 bits)
;   DH - Cabeçote
;
; S = (LBA % número de setores por trilha) + 1
; H = (LBA / número de setores por trilha) % número de cabeçotes
; C = (LBA / número de setores por trilha) / número de cabeçotes
; -----------------------------------------------------------------------------
    push ax             ; Salva LBA original na pilha.
    push dx             ; Salva o número da unidade (em DL) na pilha.
    
    xor dx, dx          ; Zera DX para receber o resto da divisão.
    div word [BPB_SPT]  ; Divide LBA pela quantidade de setores por trilha (BPB_SPT - 2 bytes).
                        ; AX recebe (LBA / BPB_SPT)
                        ; DX recebe (LBA % BPB_SPT)
    ;
    ; Cálculo do setor...
    ;
    inc dx              ; DX recebe o número do setor: (LBA % BPB_SPT) + 1
    mov cx, dx          ; Passa o número do setor para CX.
    ;
    ; Cálculo do cilindro...
    ;
    xor dx, dx          ; Zera DX novamente.
    div word [BPB_NH]   ; Divide AX (LBA / BPB_SPT) pelo número de cabeças (BPB_NH).
                        ; AX recebe o número do cilindro: (LBA / BPB_SPT) / BPB_NH
                        ; DX recebe o número da cabeça: (LBA / BPB_SPT) % BPB_NH
    ;
    ; Registro do número da cabeça...
    ;
    mov dh, dl          ; Move o número da cabeça para a parte alta de DX (DH).
    ;
    ; Ajuste do conteúdo de CX (setor e cilindro)...
    ;
    mov ch, al          ; Passa os 8 bits mais baixos do número do cilindro para CH.
    shl ah, 6           ; Desloca a parte alta de AX 6 bits à esqerda.
    or cl, ah           ; Inclui os 2 bits mais altos do número do cilindro nos bits
                        ; 7 e 6 de CX, que já contém o setor nos bits de 5 a 0.
    ;
    ; Restauração do número da unidade (DL)...
    ; 
    pop ax              ; Passa o número da unidade (DL) para AX.
    mov dl, al          ; Passa o número da unidade de volta para DL.
    ;
    ; Restauração do LBA...
    ; 
    pop ax              ; Devolve LBA para AX (já não será necessário na leitura).
    ret
; -----------------------------------------------------------------------------
disk_read:
; -----------------------------------------------------------------------------
; Lê setores de um disco
;
; Parâmetros:
;   AX    - Endereço LBA (precisa converter para CHS)
;   CL    - Número de setores que serão lidos (deve passar para AL antes da interrupção)
;   DL    - Número da unidade de disco (DH receberá o número do cabeçote após a conversão)
;   ES:BX - Endereço da memória onde os dados serão escritos
;
; Retorno:
;   AX    - Código de erro se CF=1 (0x00 = sucesso)
; -----------------------------------------------------------------------------
    pusha               ; Salva todos os registradores de propósito geral na pilha.

    push cx             ; Independente de CX já estar na pilha, a contagem de setores a ler
                        ; será colocada no topo da pilha por conta da conversão LBA/CHS.
    call lba_to_chs     ; Chama a rotina de conversão LBA/CHS:
                        ; - AX recebe LBA
                        ; - CX recebe Cilindro e Setor
                        ; - DH recebe Cabeça
                        ; - DL continua com o número da unidade
    ;
    ; Serviço INT 0x13 AH=0x02...
    ;
    pop ax              ; Passa a quantidade de setores a ler (antes em CL) para AX (AL).
    mov ah, 0x02        ; Função de leitura de setores
    mov di, 3           ; Registra a contagem máxima de tentativas em DI.

.retry:
    ; stc                 ; Sobe a CF.
    int 0x13            ; Invoca a interrupção 0x013.
    jnc .done           ; Se a CF zerar (sucesso), salta para o fim da rotina.

    call disk_reset     ; Reinicia o controlador da unidade de disco.
    dec di              ; Decrementa DI
    test di, di         ; Enquanto não zerar, tenta novamente
    jnz .retry          ; Se zerar, parar de tentar
    ;
    ; Nunca chegará aqui se passar numa das 3 tentativas...
    ;
    call disk_error
    ;
    ; Nuca chegará aqui se der erro...
    ;
.done:
    popa                ; Restaura registradores salvos no início da rotina.
    ret
; -----------------------------------------------------------------------------
disk_reset:
; -----------------------------------------------------------------------------
; Reinicia unidade de disco
;
; Parâmetro:
;   DL - Número da unidade
; -----------------------------------------------------------------------------
    pusha           ; Salva registradores.
    mov ah, 0       ; Função para reiniciar o controlador da unidade.
    ; stc             ; Sobe a CF.
    int 0x13        ; Executa o serviço.
    jnc .done       ; Se CF zerar, reset ok...
    call disk_error ; Caso contrário, termina o bootloader com erro.
.done:
    popa            ; Restaura registradores
    ret
; -----------------------------------------------------------------------------
disk_error:
; -----------------------------------------------------------------------------
    mov si, err_disk_read       ; Mensagem de erro
    mov cx, err_disk_read_len   ; Tamanho da mensagem de erro
    call print_str

    mov ah, 0           ; Função para ler o teclado
    int 0x16            ; Espera um tecla pressionada
    jmp 0xffff:0000     ; Salta para o inicio do BIOS na memória
; -----------------------------------------------------------------------------
; DATA
; -----------------------------------------------------------------------------
msg                 db `Loading OS...\r\n`
msg_len             equ $ - msg

err_disk_read       db `Disk error!\r\nPress any key to reboot...`
err_disk_read_len   equ $ - err_disk_read

kernel_bin          db 'KERNEL  BIN'  ; nome do arquivo do kernel
kernel_cluster      dw 0              ; 2 bytes iniciados com zeros
kernel_ls           equ 0x2000        ; Load segmement
kernel_lo           equ 0             ; load offset

kernel_nf           db `KERNEL.BIN not fount!\r\n`
kernel_nf_len       equ $ - kernel_nf
; -----------------------------------------------------------------------------
times 510-($-$$) db 0
dw 0xaa55

buffer: