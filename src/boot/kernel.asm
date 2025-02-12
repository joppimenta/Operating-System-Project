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

    ; Exibir a mensagem "MEU SISTEMA OPERACIONAL"
    mov si, mensagem  ; SI aponta para a mensagem
    mov di, (12 * 80 + 30) * 2  ; Posição centralizada (linha 12, coluna 30)
    mov ah, 0x0E      ; AH = 0x0E (função de imprimir caractere do BIOS)

.print_loop:
    lodsb             ; Carrega o próximo caractere da mensagem em AL
    test al, al       ; Verifica se é o fim da string (AL = 0)
    jz .halt          ; Se for o fim, termina
    stosw             ; Escreve o caractere na memória de vídeo (AL = caractere, AH = atributo)
    jmp .print_loop   ; Repete para o próximo caractere

.halt:
    ; Parar a CPU
    cli
    hlt

; Dados
mensagem db 'MEU SISTEMA OPERACIONAL', 0