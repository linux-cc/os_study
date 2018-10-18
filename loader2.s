%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR
jmp loader_start

;构建GDT及其内部的描述符
GDT_BASE:
    dd 0
    dd 0
CODE_DESC:
    dd 0xffff
    dd DESC_CODE_HIGH4
DATA_DESC:
    dd 0xffff
    dd DESC_DATA_HIGH4
VIDEO_DESC:
    dd 0x80000007           ;limit=(0xbffff-0xb8000)/4k=0x7
    dd DESC_VIDEO_HIGH4     ;此时dpl=0

    GDT_SIZE equ $ - GDT_BASE
    GDT_LIMIT equ GDT_SIZE - 1
    times 120 dd 0           ;此处预留60个描述符的空位
    SELECTOR_CODE equ (1 << 3) + TI_GDT + RPL0
    SELECTOR_DATA equ (2 << 3) + TI_GDT + RPL0
    SELECTOR_VIDEO equ (3 << 3) + TI_GDT + RPL0

;以下是gdt指针，前2字节是界限，后4字节是起始地址
gdt_ptr:
    dw GDT_LIMIT
    dd GDT_BASE
    loadermsg db '2 loader in real'

loader_start:
;int 0x10 功能号：0x13 功能描述：打印字符串
;输入：
;ah子功能号=0x13
;bh=页码
;bl=属性（若al=0或1）
;cx=字符串长度
;(dh,dl)=坐标（行，列）
;es:bp=字符串地址
;al=显示输出方式
;0：字符串中只含显示字符，其显示属性在bl中，显示后光标位置不变
;1：字符串中只含显示字符，其显示属性在bl中，显示后光标位置改变
;2：字符串中含显示字符和显示属性，显示后光标位置不变
;3：字符串中含显示字符和显示属性，显示后光标位置改变
;无返回值
    mov sp, LOADER_BASE_ADDR
    mov bp, loadermsg       ;es:bp=字符串地址
    mov cx, 17              ;cx=字符串长度
    mov ax, 0x1301          ;ah=0x13,al=0x01
    mov bx, 0x001f          ;ah=0页号为0，bl=0x1f蓝底粉红字
    mov dx, 0x1800
    int 0x10

;准备进入保护模式
;1 打开A20
    in al, 0x92
    or al, 0x02
    out 0x92, al

;2 加载gdt
    lgdt [gdt_ptr]

;3 将cr0pe位置1
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax

    jmp dword SELECTOR_CODE:p_mode_start    ;刷新流水线

[bits 32]
p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax
    mov byte [gs:160], 'P'

    jmp $
