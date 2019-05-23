.global draw
.global edgem
.global trim
.global name
.global parsefd
.global zbuffer
.global half
.global data
.global minval
.data
    .align 32
    x: .quad 0
    half: .double .5
    .align 32
    name: .asciz "./image.ppm"
    .align 32
    parsefile: .asciz "./script"
    .align 32
    minval: .double -inf
.bss
    .align 32
    data: .zero 1048576
    zbuffer: .zero 2097152
    .align 32
    edgem: .quad 0
    drawm: .quad 0
    trim: .quad 0
    parsefd: .quad 0
.text
draw:
    lea zbuffer(%rip), %rdi
    mov minval(%rip), %rax
    mov $262144, %rcx
    rep stosq//fill zbuffer with -infinity double

    mov $10, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, edgem(%rip)//make tiny dummy edge matrix

    mov $4096, %rdi
    mov $4, %rsi
    call makematrix
    mov %rax, trim(%rip)//make tiny dummy trimatrix

    mov $4, %rdi
    mov $4, %rsi
    call makematrix
    push %rax
    mov %rax, %rdi
    call identitymatrix//make identity coordinate stack matrix
    mov $16, %rdi
    call malloc@PLT
    mov %rax, cstop(%rip)
    pop %rdi
    mov %rdi, (%rax)

    call init_temps//initialize temporary values

    xor %rax, %rax
    nextop:
    push %rax
    mov $0, %rdx//0th pass
    call handleop
    pop %rax
    inc %rax
    cmp lastop(%rip), %rax
    jl nextop

    xor %rax, %rax
    nextop1:
    push %rax
    mov $1, %rdx//1st pass
    call handleop
    pop %rax
    inc %rax
    cmp lastop(%rip), %rax
    jl nextop1

    mov num_frames(%rip), %rcx
    test %rcx, %rcx
    jz nofrills

    lea basename(%rip), %rdi
    call mstrlen
    movb $0x30, (%rdi, %rax)
    movb $0x30, 1(%rdi, %rax)
    movb $0x2E, 2(%rdi, %rax)
    movb $0x70, 3(%rdi, %rax)
    movb $0x70, 4(%rdi, %rax)
    movb $0x6d, 5(%rdi, %rax)


    xor %rcx, %rcx
    frameloop:
    push %rcx
    call setknobs
    xor %rax, %rax
    nextop2:
    push %rax
    mov $2, %rdx//2nd pass
    call handleop
    pop %rax
    inc %rax
    cmp lastop(%rip), %rax
    jl nextop2
    lea basename(%rip), %rdi
    call mstrlen
    sub $6, %rax
    lea basename(%rip), %rdi
    mov (%rsp), %rcx
    //get first 2 letters from A (0) to P (15), for a pseudo hex format
    mov %rcx, %rdx
    and $0b1111, %rcx
    and $0b11110000, %rdx
    shr $4, %rdx
    addb $0x41, %cl
    addb $0x41, %dl
    //dl is first digit from 0 to 15, cl is second digit
    mov %dl, (%rdi, %rax)
    mov %cl, 1(%rdi, %rax)
    call saveit

    lea zbuffer(%rip), %rdi
    mov minval(%rip), %rax
    mov $262144, %rcx
    rep stosq
    lea data(%rip), %rdi
    xor %rax, %rax
    mov $131072, %rcx
    rep stosq
    
    mov trim(%rip), %rdi
    mov edgem(%rip), %rsi
    movq $0, 24(%rdi)
    movq $0, 24(%rsi)

    mov cstop(%rip), %rdi
    mov (%rdi), %rdi
    call identitymatrix

    pop %rcx
    inc %rcx
    cmp num_frames(%rip), %rcx
    jl frameloop
    jmp endfrills

    nofrills:
    xor %rax, %rax
    nextop2n:
    push %rax
    mov $1, %rdx//0th pass
    call handleop
    pop %rax
    inc %rax
    cmp lastop(%rip), %rax
    jl nextop2n
    endfrills:

    mov edgem(%rip), %rdi
    call freematrix//free edge matrix

    mov trim(%rip), %rdi
    call freematrix//free trimatrix

    csstackstill:
    call cspop//free last item on coordinate stack
    cmpq $0, cstop(%rip)
    jne csstackstill

    call free_temps
    ret
