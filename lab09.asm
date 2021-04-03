.org 0x0000 ; As primeiras posicoes da memoria referem-se a interrupcoes. Dessa forma, na primeira posicao e criado um rotulo para que o programa possa ser direcionado para o laco principal
jmp main ; Sai do primeiro endereco e e direcionado para o laco principal
    
.org 0x0004 ; Essa posicao da memoria e onde esta a interrupcao int1. Assim, cria um rotulo para que, nessa posicao, o programa seja direcionado para as instrucoes da interrupcao
jmp interrupcao ; Sai do endereco 0x04 e vai para onde estao localizadas as instrucoes da interrupcao
    
.org 0x0034 ; No primeiro endereco livre, localiza a instrucao main
main: ; Configura os registradores usados no programa
cli ; desabilita as interrupcoes

eor r31, r31 ; eor e um ou exclusivo. Dessa forma, as operacoes abaixo zeram os registradores para que eles possam ser usados posteriormente
eor r29, r29
eor r28, r28
eor r27, r27
; As operacoes a seguir salvam o ultimo endereco de memoria I/O no stack pointer, marcando o inicio da pilha. O stackpointer e formado por dois registradores: SPL e SPH. O ultimo endereco e 0x08FF
; Como os registradores estao na memoria I/O, e usada a instrucao out, que armazena o valor de um registrador na memoria I/O. A instrucao ldi carrega o valor desejado, que contem o endereco, no registrador r16 para que, posteriormente, possa ser usada a instrucao out    
ldi r16, 0xFF 
out SPL,r16
ldi r16, 0x08
out SPH, r16

sbi 0x04,5 ; Configura o pino 13 (led incorporado) como saida. A instrucao sbi seta como um o bit indicado do registrador: sbi registrador, bit
cbi 0x0A,3 ; configura o pino 3 (onde ocorre a interrupcao int1, logo onde o botao sera conectado) como entrada. A instrucao cbi reseta o bit indicado do registrador: cbi registrador, bit
sbi PORTD,3 ; Como o pino 3 esta configurado como saida, setar o bit 3 de PORTD ativa o resistor de pull up
cbi 0x05,5 ; apaga o LED inicialmente

in r16, MCUCR ; Carrega o registrador auxiliar r16 com o valor contido em MCUCR
andi r16, 0b11101111 ; Mascara garante que apenas o bit 4 seja resetado
out MCUCR, r16 ; Transfere para o registrador MCUCR, localizado na memoria I/O, o valor do registrador r16, com o bit 4 resetado. Esse bit corresponde ao Pull Up Disable. Quando setado como 1, desativa os resistores de pull up. Como desejamos habilitar o pull up para o funcionamento do botao, o bit e resetado
ldi r16, 0b00001000 ; Carrega o registrador com o valor 10 nos bits 3 e 2, respectivamente
sts EICRA, r16 ; Com os bits 3 e 2 setados, ativa-se a interrupcao externa para bordas de descida. Como o botao tem nivel logico alto quando nao esta pressionado, uma borda de descida indica que ele foi pressionado e agora tem nivel logico zero.
ldi r16, 0b00000010 ; Seta o bit 1 do r16
out EIMSK, r16 ; Com o bit 1 setado, habilita-se a interrupcao int1
    
sei ; habilita as interrupcoes
    
loop: ; Contem as instrucoes do looping
sbi 0x05,5 ; Liga o led
call delay1seg ; Chama uma subrotina que tem por objetivo executar instrucoes por tempo suficiente para que o led fique aceso por 1 segundo
eor r28, r28 ; Limpa o registrador auxiliar r28, utilizado durante o delay
cbi 0x05,5 ; Apaga o led
call delay1seg ; Subrotina de delay
eor r28, r28 ; Limpa o registrador
jmp loop ; Ao fim da rotina, o programa e direcionado novamente para o inicio do looping
    
; Funcionamento do delay:
; Primeiramente, tem-se a subrotina delay. O registrador r31 e incrementado a cada vez que essa instrucao ocorre. Posteriormente, seu valor e passado para o registrador r30. O valor deste ultimo e comparado com 255. Se nao forem iguais, o programa desvia para o inicio da subrotina e ela ocorre novamente.
; Apos 255 ocorrencias, o conteudo de r30 e igual a 255. Assim, o programa chama a subrotina delay_1
; Na subrotina delay_1, acontece um processo semelhante, utilizando o registrador r29 como auxiliar. No entando, apos a comparacao de valores, caso sejam diferentes, o programa desvia para a subrotina delay. 
; Dessa forma, delay ocorre novamente por mais 255 vezes, ate chamar novamente a subrotina delay_1, incrementando r29 e o processo se repete sucessivamente ate que a subrotina delay_1 tenha ocorrido 255 vezes.
; Entao, o valor em r29 e zerado e o programa retorna para a rotina anterior, que e a delay. Esta, por sua vez, tambem retorna para a instrucao na qual foi chamada.
; A quantidade de ciclos em cada subrotina esta listada.
; No MPLAB, foi utilizada a funcao stopwatch para mapear quantos ciclos e quantos segundos essa concatenação de rotinas permitia. O valor 255 foi utilizado em ambos os registradores por ser o maior possivel
; Foi obtido o valor de 328196 ciclos e 20.51225 ms. 
; Para se obter o valor de 1 segundo, portanto, seria necessario relizar essa concatenacao mais 1/0.02051225 = 48.75 vezes
; Assim, foi criada a rotina delay1segundo, que funciona de maneira semelhante as anteriores, mas comparando-se o valor de r28 com 48, para que o ciclo de delays se repetisse mais 48 vezes, resultando em um valor próximo de 1 segundo. 
; Nessa rotina, ela se inicia chamando a funcao delay, fazendo com que a concatenacao delay e delay_1 ocorra a cada execucao de delay1seg. Em seguida, r28 e incrementado e comparado com 48. Se os resultados forem diferendes, o programa desvia para o inicio da subrotina, chamando novamente delay e assim sucessivamente ate que esse ciclo ocorra 48 vezes. Em seguida, o programa retorna para o ponto de chamada, que e o looping.
; Porém, como a rotina não tem apenas uma instrucao, o valor nao e exatamente de 1 segundo. 
; Analogamente, para um delay de 0.1 segundos, foi utilizada a subrotina delay01segundos. Essa subrotina faz com que a concatenacao de delays seja executada mais 5 vezes, obtendo um valor proximo de 0.1 segundo (5*0.020 = 0.1).
delay:
    
inc r31 ; 1 ciclo
mov r30, r31 ; 1 ciclo
cpi r30, 255 ; 1 ciclo
brne delay ; 1 ciclo falso e 2 ciclos verdadeiro
eor r31, r31 ; 1 ciclo
call delay_1 ; 4 ciclos
ret ; 4 ciclos
    
delay_1:
    
inc r29 ; 1 ciclo
cpi r29, 255 ; 1 ciclo
brne delay ; 1 ciclo falso e 2 ciclos verdadeiro
eor r29, r29 ; 1 ciclo
ret ; 4 ciclos

delay1seg:
    
call delay ; 4 ciclos
inc r28 ; 1 ciclo
cpi r28, 48 ; 1 ciclo
brne delay1seg ; 1 ciclo falso e 2 ciclos verdadeiro
ret ; 4 ciclos

interrupcao: ; Rotina de interrupcao
push r16 ; Salva o ultimo valor armazenado em r16 para que esse valor nao seja perdido ao fim da rotina
in r15, PORTB ; Armazena em r15 o conteudo do endereco 0x05. Esse endereco contem o registrador PORTB, que indica em qual estado estava o led antes da interrupcao
push r15 ; Salva na pilha o conteudo de r15
in r16, SREG ;  Armazena em r16 o valor do registrador de estado SREG antes da interrupcao
push r16 ; Armazena na pilha o estado de SREG

in r16, PIND ; Armazena em r16 o estado do botao, mapeado no bit 3 de PIND
andi r16, 0b00001000 ; Mascara que identifica o valor contido no bit 3 de r16. Caso resulte em 1, significa que o botao nao esta pressionado. Do contrario, esta pressionado
breq pisca_led ; breq desvia para pisca_led caso a flag z esteja setada, ou seja, a operacao resulte em zero. Se a operacao resulta em zero, significa que o botao esta pressionado, apresentando nivel logico zero
jmp fim ; Caso o botao nao esteja pressionado, o programa desvia para o fim da interrupcao

    
pisca_led:
; O led deve piscar 4 vezes, começando e terminando com ele apagado.
; Assim, cbi desliga e sbi liga o led. Entre cada mudanca de estado, e chamada a subrotina delay01seg para que o led permaneca no estado por 0.1 segundos. Alem disso, o registrador auxiliar r27 e zerado.
cbi 0x05,5
call delay01seg
eor r27, r27
sbi 0x05,5
call delay01seg
eor r27, r27
cbi 0x05,5
call delay01seg
eor r27, r27
sbi 0x05,5
call delay01seg
eor r27, r27
cbi 0x05,5
call delay01seg
eor r27, r27
sbi 0x05,5
call delay01seg
eor r27, r27
cbi 0x05,5
call delay01seg
eor r27, r27
    
fim:
    pop r16 ; retira da pilha o ultimo valor armazenado, ou seja, o conteudo de SREG armazenado em r16
    out SREG, r16 ; transfere para o SREG o seu ultimo estado antes da interrupcao
    pop r15 ; retira da pilha o valor de 0x05
    out PORTB, r15 ; transfere para 0x05 o seu ultimo valor antes da interrupcao
    pop r16 ; retira o primeiro valor armazenado, o conteudo de r16
    ldi r16, 0x02 ; seta o bit 1 de r16
    out EIFR, r16 ; transfere para EIFR o valor de r16, setando o bit 1. Com o bit 1 setado, a flag e limpa, de modo a minimizar a ocorrencia do efeito bounce. Sempre que uma interrupcao ocorre, esta flag e setada como 1. Assim, garante-se que a interrupcao nao sera chamada novamente caso esteja ocorrendo uma mudanca no nivel logico do botao por efeito bounce
    reti ; retorna da rotina de interrupcao
 
delay01seg:
  
call delay ; 4 ciclos
inc r27 ; 1 ciclo
cpi r27,5 ; 1 ciclo
brne delay01seg ; 1 ciclo falso e 2 ciclos verdadeiro
ret ; 4 ciclos
    