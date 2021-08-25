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


.data
vetor: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text

.global main

#USO DOS REGISTRADORES PARA ENTRADA DE DADOS

# r2 ponteiro para UART0RX
# r3 ponteiro para flag RxReady
# r4 dado recebido na UART0
# r5 flag para saber se o enter foi pressionado
# r6 resultado do inteiro final obtido pela serial
# r7 tamanho do vetor
# r8 auxilar para salvar vetor na memoria
# r9 flag para saber se o valor da serial é o tamanho do vetor
# r10 contador para preencher o vetor

main:
	movia r2, UART0RX # r2 como ponteiro para RxData do UART0
	movia r3, flagUART0 # r3 como ponteiro para flag RxReady
	movia r8, vetor
	
waiting_input:
	# Verificando se há algum dado para ser lido
	ldw r4, 0(r3)
	andi r4, r4, 128 # a flag rxReady ta mapeada no 8 bit menos significativo 
	beq r4, r0, waiting_input
	ldw r4, 0(r2) # Lendo byte recebido

is_enter:
	cmpeqi r5, r4, 10 # Compara a entrada com o 10 (Valor do Enter pela tabela ASCII)
	beq r5, r0, is_not_enter
	beq r9, r0, tamanhoVetor
	subi r10, r10, 1
	stw r6, 0(r8)
	addi r8, r8, 4
	mov r6, r0
	beq r10, r0, inicio
	br waiting_input
	
tamanhoVetor:
	movi r9, 1
	mov r7, r6
	mov r10, r6
	mov r6, r0
	br waiting_input
	
is_not_enter:
	subi r4, r4, 48
	muli r6, r6, 10
	add r6, r6, r4
	br waiting_input

#USO DOS REGISTRADORES PARA O ALGORITMO DE BUBBLESORT
# r2 contador i
# r3 contador j
# r4 auxilar para troca de posicao no vetor
# r5 inicio do vetor
# r6 tamanho do vetor
# r7 posicao atual do vetor
# r8 tamanho do vetor - 1
# r9 = vetor[j]
# r10 = vetor[j+1]

inicio:
	movi r15, 1
	movi r16, 1
	mov r6, r7 #r6 = n
	movia r5, vetor #r5 = &vetor	
	mov r7, r5 # r7 = r5
	mov r2, r0 
	mov r3, r0
	addi r2, r2, 1
	subi r8, r6, 1 # r8 = n-1
	
for1:
	beq r16, r15, mid_for # if (r16 = r15)
	br sending #else
	
mid_for:
	mov r15, r0
for2:
	
	bge r3, r8, end_for2 # if (r3 >= r8)
	#else
	ldw r9, 0(r7)  #r9 = vetor[j]
	ldw r10, 4(r7) #10 = vetor[j+1]
	
	bge r10, r9, true # if (r10 >= r9) 
	#else
	mov r4, r9 # aux = vetor[j]
	stw r10, 0(r7) #vetor[j] = vetor[j + 1]
	stw r4, 4(r7)  #vetor[j+1] = aux
	movi r15,1

true: 
	addi r7, r7, 4 # pecorre o vetor
	addi r3, r3, 1 #j++
	br for2

end_for2:
	addi r2, r2, 1 #i++
	mov r7, r5 #resetar a posicao inicial do vetor
	mov r3, r0 # j = 0
	br for1

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
	mov r12, sp
	mov r2, r0
	
while:
	beq r2, r6, end
	ldw r10, 0(r5) # movendo o resultado da verificação para r10
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
	addi r5, r5, 4
	addi r2, r2, 1
	br while
	
send_enter:
	stw r9, 0(r7)
	ret

end:
	.end
