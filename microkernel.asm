[BITS 16]
[ORG 0x1000]  ; Localização de carregamento

start:
    mov si, msg
    call print_string
    cli
    hlt

print_string:
    mov ah, 0x0E
.print_char:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .print_char
.done:
    ret

msg db "Kernel started.", 0

