; Jogo da Adivinhação em Assembly x86 (Modo Real)
; Compilar com: nasm -f bin game.asm -o game.bin

BITS 16

section .text
global _start

_start:
    ; Exibir mensagem inicial
    mov si, msg_intro
    call print_string

    ; Gerar número aleatório (simplesmente usando o contador de tempo)
    call get_random
    mov bl, al  ; Guardar número aleatório em BL

guess_loop:
    mov si, msg_input
    call print_string
    call get_number
    mov bh, al  ; Guardar palpite do usuário

    cmp bh, bl
    je win
    jb too_low
    ja too_high

too_low:
    mov si, msg_too_low
    call print_string
    jmp guess_loop

too_high:
    mov si, msg_too_high
    call print_string
    jmp guess_loop

win:
    mov si, msg_win
    call print_string
    ret  ; Retorna para o kernel

; Função para exibir string
print_string:
    lodsb
    or al, al
    jz done
    mov ah, 0x0E
    int 0x10
    jmp print_string

done:
    ret

; Função para capturar número do usuário
get_number:
    mov ah, 0x00
    int 0x16  ; Esperar entrada do teclado
    sub al, '0'  ; Converter ASCII para número
    ret

; Função para gerar número aleatório (usando RTC como fonte)
get_random:
    mov ah, 0x00
    int 0x1A  ; Obter tempo do RTC
    mov al, dl  ; Usar segundos como "aleatório"
    and al, 0x0F  ; Garantir número pequeno (0-15)
    ret

; Mensagens
msg_intro db "Adivinhe um numero entre 0 e 15: ", 0
msg_input db "Digite seu palpite: ", 0
msg_too_low db "Muito baixo! Tente de novo.", 0
msg_too_high db "Muito alto! Tente de novo.", 0
msg_win db "Parabens! Voce acertou!", 0
