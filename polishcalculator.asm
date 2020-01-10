global _start

section .rodata
	error_msg: db "Invalid operand or operator", 0xA, 0x0

section .data
	stack_size: dd 0
	stack: times 256 dd 0

_push:
	enter 0,0
	push eax
	push edx
	mov eax, [stack_size]
	mov edx, [ebp + 8]
	mov [stack + eax * 4], edx
	inc dword [stack_size]
	pop edx
	pop eax
	leave
	ret

_pop:
	enter 0,0
	dec dword [stack_size]
	mov eax, [stack_size]
	mov eax, [stack + eax * 4]
	leave
	ret

_pow_10:
	enter 0,0
	mov ecx, [ebp + 8]
	mov eax, 1
_pow_10_loop:
	cmp ecx, 0
	je _pow_10_loop_end
	imul eax, 10
	sub ecx, 1
	jmp _pow_10_loop
_pow_10_loop_end:
	leave
	ret

_mod:
	enter 0,0
	push ebx
	mov edx, 0
	mov eax, [ebp + 8]
	mov ebx, [ebp + 12]
	idiv ebx
	mov eax, edx
	pop ebx
	leave
	ret

_putc:
	enter 0,0
	mov edx, 1
	mov eax, 0x04
	lea ecx, [ebp + 8]
	mov ebx, 1
	int 0x80
	leave
	ret

%define MAX_DIGITS 10

_print_result:
	enter 1,0
	push ebx
	push edi
	push esi
	mov eax, [ebp + 8]
	cmp eax, 0
	jge _print_result_negate_end
	push eax
	push 0x2d
	call _putc
	add esp, 4
	pop eax
	neg eax
_print_result_negate_end:
	mov byte [ebp - 4], 0
	mov ecx, MAX_DIGITS
_print_result_loop_on:
	cmp ecx, 0
	je _print_result_loop_off
	push eax
	push ecx
	sub ecx, 1
	push ecx
	call _pow_10
	mov edx, eax
	add esp, 4
	pop ecx
	pop eax
	mov ebx, edx
	imul ebx, 10
	push eax
	push ecx
	push edx
	push ebx
	push eax
	call _mod
	mov ebx, eax
	add esp, 8
	pop edx
	pop ecx
	pop eax
	push esi
	mov esi, edx
	mov edx, 0
	push eax
	mov eax, ebx
	idiv esi
	mov ebx, eax
	pop eax
	pop esi
	cmp ebx, 0
	jne _print_result_trail_zero_chck_end
	cmp byte [ebp - 4], 0
	jne _print_result_trail_zero_chck_end
	jmp _print_result_loop_forward
_print_result_trail_zero_chck_end:
	mov byte [ebp - 4], 1
	add ebx, 0x30
	push eax
	push ecx
	push edx
	push ebx
	call _putc
	add esp, 4
	pop edx
	pop ecx
	pop eax
_print_result_loop_forward:
	sub ecx, 1
	jmp _print_result_loop_on
_print_result_loop_off:
	pop esi
	pop edi
	pop ebx
	leave
	ret

_strlen:
	enter 0,0
	mov eax, 0x0
	mov ecx, [ebp + 8]

_strlen_is_null:
	cmp byte [ecx], 0x0
	je _strlen_loop_end

	inc eax
	add ecx, 0x01
	jmp _strlen_is_null

_strlen_loop_end:
	leave
	ret

_print_msg:
	enter 0,0
	mov eax, 0x04
	mov ebx, 0x1
	mov ecx, [ebp + 8]
	push eax
	push ecx
	push dword [ebp + 8]
	call _strlen

	mov edx, eax
	add esp, 4
	pop ecx
	pop eax

	int 0x80
	leave
	ret

_start:
	mov esi, [esp + 8]
	push esi
	call _strlen
	mov ebx, eax
	add esp, 4
	mov ecx, 0
_main_loop_on:
	cmp ecx, ebx
	jge _main_loop_off
	mov edx, 0
	mov dl, [esi + ecx]
	cmp edx, '0'
	jl _check_op
	cmp edx, '9'
	jg _op_error
	sub edx, '0'
	mov eax, edx
	jmp _push_eax
_check_op:
	push ecx
	push ebx
	call _pop
	mov edi, eax
	call _pop
	pop ebx
	pop ecx
	cmp edx, '+'
	jne _subtract
	add eax, edi
	jmp _push_eax
_subtract:
	cmp edx, '-'
	jne _multiply
	sub eax, edi
	jmp _push_eax
_multiply:
	cmp edx, '*'
	jne _divide
	imul eax, edi
	jmp _push_eax
_divide:
	cmp edx, '/'
	jne _op_error
	push edx
	mov edx, 0
	idiv edi
	pop edx
_push_eax:
	push eax
	push ecx
	push edx
 	push eax
	call _push
	add esp, 4
	pop edx
	pop ecx
	pop eax
	inc ecx
	jmp _main_loop_on
_main_loop_off:
	cmp byte [stack_size], 1
	jne _op_error
	mov eax, [stack]
	push eax
	call _print_result
	push 0xA
	call _putc
	mov eax, 0x01
	mov ebx, 0
	int 0x80
_op_error:
	push error_msg
	call _print_msg
	mov eax, 0x01
	mov ebx, 1
	int 0x80

