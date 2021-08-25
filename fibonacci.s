#Algoritmo Fibonacci Recursivo
# Crystal & Havallon
# 30/09/2017

.equ UART0RX, 0x860 # Endereço da RxData do UART0 na memoria
.equ flagUART0, 0x868 # Endereço de memoria para aonde as flags RxReady e TxReady estão mapeadas
.equ UART0TX, 0x864 # Endereço da TxData do UART0 na memoria


# Inserindo dado na pilha
.macro push reg
	subi sp, sp, 4
	stw \reg, 0(sp)
.endm

# Recuperando dado da pilha
.macro pop reg
	ldw \reg, 0(sp)
	addi sp, sp, 4
.endm


.global main

.global main

#USO DOS REGISTRADORES PARA ENTRADA DE DADOS

# r2 ponteiro para UART0RX
# r3 ponteiro para flag RxReady
# r4 dado recebido na UART0
# r5 flag para saber se o enter foi pressionado
# r6 resultado do inteiro final obtido pela serial

main:
	movia r2, UART0RX # r2 como ponteiro para RxData do UART0
	movia r3, flagUART0 # r3 como ponteiro para flag RxReady

waiting_input:
	# Verificando se há algum dado para ser lido
	ldw r4, 0(r3)
	andi r4, r4, 128 # a flag rxReady ta mapeada no 8 bit menos significativo 
	beq r4, r0, waiting_input
	ldw r4, 0(r2) # Lendo byte recebido

is_enter:
	cmpeqi r5, r4, 10 # Compara a entrada com o 10 (Valor do Enter pela tabela ASCII)
	beq r5, r0, is_not_enter
	br inicio
	
is_not_enter:
	subi r4, r4, 48
	muli r6, r6, 10
	add r6, r6, r4
	br waiting_input

# USO DOS REGISTRADORES PARA FIBONACCI
# r2 quantidade da sequencia
# r8 contador i
# r3 Constante 1
# r4 Resultado fibonacci
# r5 Parametro de entrada do fibonacci
# r6 auxilar para calculo do fibonacci

inicio:
	mov r8, r0
	addi r8, r8, 1
	mov r2, r6

while:
	bge r2, r8, start
	br end

start:
	movi r3, 1
	mov r4, r0
	push r8
	call fibonacci
	call sending
	addi r8, r8, 1
	br while
	
fibonacci:
	pop r5
	bgt r5, r3, do
	add r4, r4, r5
	ret

do:
	push ra
	subi r6, r5, 1
	push r6
	subi r6, r6, 1
	push r6
	call fibonacci
	call fibonacci
	pop ra
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
	mov r10, r4 # movendo o resultado da verificação para r10
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
	push ra
	call send_enter
	pop ra
	ret
	
send_enter:
	stw r9, 0(r7)
	ret

end:
	.end
