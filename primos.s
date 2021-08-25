# Geração de números primos entre dois valores
# Crystal, José Ricardo, Havallon
# 20/09/17

.equ UART0RX, 0x860 # Endereço da RxData do UART0 na memoria
.equ flagUART0, 0x868 # Endereço de memoria para aonde as flags RxReady e TxReady estão mapeadas
.equ UART0TX, 0x864 # Endereço da TxData do UART0 na memoria


.global main

.macro push reg
	subi sp, sp, 4
	stw \reg, 0(sp)
.endm

.macro pop reg
	ldw \reg, 0(sp)
	addi sp, sp, 4
.endm

.macro resto opA, opB, res
	div \res, \opA, \opB
	mul \res, \res, \opB
	sub \res, \opA, \res
.endm

# USO DOS REGISTRADORES PARA ENTRADA DE DADOS

# r2 ponteiro para UART0RX
# r3 ponteiro para flag RxReady
# r4 dado recebido na UART0
# r5 flag para saber se o enter foi pressionado
# r6 resultado do inteiro final obtido pela serial
# r7 quantidade de entradas
main:
	movia r2, UART0RX # r2 como ponteiro para RxData do UART0
	movia r3, flagUART0 # r3 como ponteiro para flag RxReady
	movi r7, 2
	
waiting_input:
	# Verificando se há algum dado para ser lido
	ldw r4, 0(r3)
	andi r4, r4, 128 # a flag rxReady ta mapeada no 8 bit menos significativo 
	beq r4, r0, waiting_input
	ldw r4, 0(r2) # Lendo byte recebido

is_enter:
	cmpeqi r5, r4, 10 # Compara a entrada com o 10 (Valor do Enter pela tabela ASCII)
	beq r5, r0, is_not_enter
	subi r7, r7, 1
	push r6
	mov r6, r0
	beq r7, r0, inicio
	br waiting_input
	
is_not_enter:
	subi r4, r4, 48
	muli r6, r6, 10
	add r6, r6, r4
	br waiting_input

# USO DOS REGISTRADORES PARA CALCULO DOS NUMEROS PRIMOS
# r2 primeiro valor do intervalo
# r3 ultimo valor do intervalo
# r4 a diferença entre os intervalos
# r5 contador1
# r6 contador2
# r7 flag para detectar o numero primo
# r8 constante 1
inicio:
	pop r3
	pop r2
	sub r4, r3, r2
	movi r5, 0
	movi r6, 2
	movi r7, 0
	movi r8, 1
		
loop1:
	blt r4, r5, end
	cmpeqi r7, r2, 2
	call loop2
	movi r6, 2
	addi r5, r5, 1
	beq r7, r8, sending
	addi r2, r2, 1
	br loop1
	
loop2:
	bge r6, r2, endloop2
	resto r2, r6, r9
	beq r9, r0, else
	movi r7, 1
	addi r6, r6, 1
	br loop2
	
endloop2:
	ret

else:
	movi r7, 0
	ret

	
# USO DOS REGISTRADORES PARA SAIDA DE DADOS
# r7 ponteiro para UART0TX
# r9 auxiliar para dividir por 10
# r10 inteiro a ser transmitido pela serial
# r11 auxiliar para enviar os caracter em ASCII
# r12 valor inicial de sp
# r13 auxilar para flag de comparaçao

sending:
	movia r7, UART0TX # r7 como ponteiro para TxData do UART0
	movi r9, 10
	mov r10, r2 # movendo o resultado da verificação para r10
	mov r12, sp
loop: 
	bge r10, r9, if # While (r10 >= r9)
	push r10
	br send

if:	#Salvando o resto da divasão por 10 na pilha
	div r11, r10, r9
	muli r11, r11, 10
	sub r11, r10, r11
	push r11
	div r10, r10, r9 # r10 = r10/r9
	br loop
	
send: # Enviando os dados salvos na pilha
	pop r10
	addi r10, r10, 48 # Transformando em ASCII
	stw r10, 0(r7)
	cmpeq r13, sp, r12
	beq r13, r0, send
	call send_enter
	addi r2, r2, 1
	br loop1
	
send_enter:
	stw r9, 0(r7)
	ret
	
end:
	.end
