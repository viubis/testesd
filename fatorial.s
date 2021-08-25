# Calculo fatorial recursivo
# Crystal, José Ricardo, Havallon
# 19/09/17

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

# USO DOS REGISTRADORES PARA ENTRADA DE DADOS

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

# USO DOS REGISTRADORES PARA O CALCULO DO FATORIAL
# r2 valor a ser calculado
# r3 constante 2
# r4 resultado do fatorial

inicio:
	mov r2, r6
	movi r3, 2
	call fatorial
	br sending # Enviando o dado para UART
	
fatorial:
	blt r2, r3, menor2 #Condição de parada
	
	#salvando os dados necessarios para a recursão
	push ra
	push r2
	subi r2, r2, 1 # r2--;
	call fatorial # recursão
	
	#recuperando o dados após o retorno da função
	pop r2
	pop ra
	mul r4, r2, r4 # r4 = r2 * fatorial(r2-1);
	ret


menor2:
	movi r4, 1
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
	br end

send_enter:
	ldw r4, 0(r8)
	andi r4, r4, 61
	beq r4,r0, send
	stw r9, 0(r7)
	ret

end:
	.end
