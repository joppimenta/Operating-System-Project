section .bss
    count resb 1  ; Reserva 1 byte para o contador

section .text
start:
    ; Loop de leitura de caracteres
    mov ah, 01h  ; Lê um caractere do teclado
    int 21h
    cmp al, 0Dh  ; Verifica se é Enter (0Dh)
    je show_count
    inc byte [count]  ; Incrementa o contador
    jmp start

show_count:
    mov ah, 09h  ; Exibe mensagem
    mov dx, msg
    int 21h

    mov al, [count]  ; Obtém o valor do contador
    aam              ; Converte para ASCII (divide por 10)
    add ax, 3030h    ; Ajusta para valores ASCII
    mov bx, ax

    mov dl, bh  ; Mostra primeira casa decimal (se houver)
    cmp dl, '0'
    je skip_first
    mov ah, 02h
    int 21h
skip_first:
    mov dl, bl  ; Mostra segunda casa decimal
    mov ah, 02h
    int 21h

    ; Pula linha após exibir o total
    mov dl, 0Ah  ; Código ASCII para quebra de linha (LF)
    mov ah, 02h
    int 21h
    mov dl, 0Dh  ; Código ASCII para retorno de carro (CR)
    mov ah, 02h
    int 21h
    
    ; Zera o contador após imprimir o total
    mov byte [count], 0  ; Zera o contador

    ; Continua o loop
    jmp start

    mov ah, 4Ch  ; Finaliza o programa
    int 21h

section .data
msg db 10, 13, "Total de caracteres: $"

