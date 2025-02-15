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
    int 0x10
    jmp .print_loop   ; Repete para o próximo caractere
.done:
    ret

terminal_loop:
    mov si, buffer   ; Ponteiro para armazenar entrada
.terminal:
    mov byte [si], 0 ; Zerar buffer
    call read_char   ; Ler caractere do teclado
    cmp al, 0x0D    ; Verificar se é o caractere de Enter (0x0D)
    je .check_command ; Se for Enter, verificar comando
    mov [si], al    ; Armazena caractere no buffer
    inc si          ; Avança ponteiro
    call print_char ; Exibir caractere na tela
    jmp .terminal   ; Repetir

.check_command:
    mov si, buffer   ; Reiniciar ponteiro do buffer
    cmp byte [si], 'r'  ; Verifica se primeiro caractere é 'r'
    jne .continue    ; Se não, continuar
    inc si           ; Avança ponteiro
    cmp byte [si], 0 ; Verifica se buffer contém apenas 'r'
    jne .continue    ; Se houver mais caracteres, continuar
    call restart     ; Se for "r" sozinho, reinicia

.continue:
    call print_newline ; Caso contrário, apenas pula a linha
    jmp .terminal      ; Repetir

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

restart:
    ; Reiniciar o computador
    mov ax, 0x0000    ; Resetar segmento
    mov es, ax
    mov dx, 0x1234    ; Valor arbitrário para evitar otimizações
    int 0x19          ; Interrupção de reinicialização do BIOS
    ret

; Dados
mensagem db "Bem-vindo ao meu Sistema Operacional", 0
buffer db 2, 0  ; Buffer para armazenar entrada
