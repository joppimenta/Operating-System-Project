bits 16
org 0x0

main:
    ; Definir modo de texto 80x25 (16 cores)
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

    mov si, mensagem
    call print_str

    call print_newline

    ; Iniciar loop do terminal
    call terminal_loop

    ; Parar a CPU
    cli
    hlt

print_str:
    mov ah, 0x0E      ; AH = 0x0E (função de imprimir caractere do BIOS)
.print_loop:
    lodsb             ; Carrega o próximo caractere da mensagem em AL
    test al, al       ; Verifica se é o fim da string (AL = 0)
    jz .done          ; Se for o fim, termina
    stosw             ; Escreve o caractere na memória de vídeo (AL = caractere, AH = atributo)
    jmp .print_loop   ; Repete para o próximo caractere
.done:
    ret

terminal_loop:
    ; Loop principal do terminal
.terminal:
    call read_char    ; Ler caractere do teclado
    cmp al, 0x0D      ; Verificar se é o caractere de Enter (0x0D)
    je .new_line      ; Se for Enter, pular para a nova linha
    call print_char   ; Exibir caractere na tela
    jmp .terminal     ; Repetir

.new_line:
    call print_newline; Pular para a nova linha
    jmp .terminal     ; Repetir

read_char:
    ; Ler um caractere do teclado
    mov ah, 0x00      ; Função para ler caractere do teclado
    int 0x16          ; Interrupção de BIOS para leitura do teclado
    ret

print_char:
    ; Exibir o caractere lido na tela
    mov ah, 0x0E      ; Função de imprimir caractere do BIOS
    int 0x10          ; Interrupção de vídeo
    ret

print_newline:
    ; Exibir nova linha na tela
    mov al, 0x0D      ; Caractere de retorno de carro
    call print_char
    mov al, 0x0A      ; Caractere de nova linha
    call print_char
    ret

; Dados
mensagem db "SO", 0
