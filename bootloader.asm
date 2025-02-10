BITS 16
ORG 0x7C00

start:
    cli ; Limpa a flag de interrupcoes - Impede que interrupcoes afetem o processo de boot
    cld ; Limpa flag de direcao

    ; Definicao dos segmentos de dados
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Definicao do topo da pilha
    mov ss, ax
    mov sp, 0x7C00

    mov byte [boot_drive], 0x80 ; Indica dispositivo de boot

    ; Mensagem de depuração ao iniciar o bootloader
    mov si, msg1
    call print_string

    ; Verificar o drive
    mov dl, [boot_drive]
    cmp dl, 0x80
    jne error

    ; Mensagem antes de carregar o kernel
    mov si, msg_prepare_kernel
    call print_string

    ; Configurar para carregar o kernel
    mov bx, 0x1000
    mov dh, 0
    mov dl, [boot_drive]
    mov cx, 2

    ; Mensagem de depuração antes de carregar o kernel
    mov si, msg_loading_kernel
    call print_string

    ; Ler setores do disco
    call read_sectors

    ; Mensagem de depuração após carregar o kernel
    mov si, msg_loaded_kernel
    call print_string

    ; Imprimir conteúdo da memória em 0x1000
    call print_memory

    ; Mensagem de depuração antes de saltar para o kernel
    mov si, msg_before_jump
    call print_string

    ; Saltar para o kernel
    jmp 0x1000

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

read_sectors:
    pusha ; Salva o valor atual dos registradores
    xor ax, ax ; Zera o registrador AX
    cld ;Limpa flag de direcao
    mov ah, 0x02 ; Leitura de disco
    mov al, 1 ; Numero de segmentos lidos
    mov ch, 0 ; Cilindro 0
    mov cl, 3 ; Numero do segmento a ser lido (3 segmento)
    mov dh, 0 ; Cabeca de leitura 0
    mov dl, [boot_drive] ; 0x80 - Ler um HD
    xor bx, bx ; Zera BX
    mov es, bx ; Segmento: 0x0000
    mov bx, 0x1000 ; Offset: 0x1000 (Vai armazenar no endereco fisico 0x1000)
    int 0x13 ; Chamada de interrupcao

    popa ; Volta com o valor original dos registradores
    ret

sector_error:
    mov si, msg_sector_error
    call print_string
    jmp error

error:
    mov si, msg_error
    call print_string
    hlt
    jmp error

print_memory:
    mov bx, 0x1000
    mov cx, 64
.print_loop:
    mov al, [bx]
    call print_byte
    inc bx
    loop .print_loop
    ret

print_byte:
    mov ah, 0x0E
    mov dl, al
    shr al, 4
    call print_hex_digit
    mov al, dl
    and al, 0x0F
    call print_hex_digit
    mov al, ' '
    int 0x10
    ret

print_hex_digit:
    add al, '0'
    cmp al, '9'
    jle .print_char
    add al, 7
.print_char:
    int 0x10
    ret

msg1 db "Bootloader started.", 0
msg_prepare_kernel db "Preparing to load kernel...", 0
msg_loading_kernel db "Loading kernel to 0x1000...", 0
msg_read_sector db "Reading sector...", 0
msg_read_success db "Sector read successfully.", 0
msg_sector_error db "Sector read error!", 0
msg_loaded_kernel db "Kernel loaded to 0x1000.", 0
msg_before_jump db "Jumping to kernel at 0x1000.", 0
msg_error db "Error loading kernel!", 0

boot_drive db 0

times 510-($-$$) db 0
dw 0xAA55