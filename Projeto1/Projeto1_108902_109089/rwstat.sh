#!/bin/bash
 
#Variaveis
declare Comm="NULL"
declare DataMin="NULL"
declare DataMax="NULL"
declare User="NULL"
declare PidMin="NULL"
declare PidMax="NULL"
declare NumProc="NULL"
declare reverse=0
declare wSort=0
declare -A arrayAss=()
declare -A read1=()
declare -A write1=()
declare NumArg=0
declare NumOpt=0


#Funcao que imprime as opções disponiveis
function menu_opcoes(){
    echo "-----------------------------------------------------------------------------------------------------------"
    echo "-------------------------------------------ARGUMENTOS INVÀLIDOS--------------------------------------------"
    echo "-----------------------------------------------------------------------------------------------------------"
    echo "--------------------------------------OPÇÕES DE ARGUMENTOS VÁLIDOS:----------------------------------------"
    echo "------------------------***ATENÇÃO: Último arg tem de ser um valor de segundos***--------------------------"
    echo " -c : Seleciona os processos com base numa expressão regular---Exemplo: d* (Mostra Comm começados por d)---"
    echo " -s : Seleciona com base numa data mínima ---Exemplo: Jan 10 10:00 ----------------------------------------"
    echo " -e : Seleciona com base numa data máxima ---Exemplo: Jan 10 10:00-----------------------------------------"
    echo " -u : Seleciona com base no nome de utilizador-------------------------------------------------------------"
    echo " -m : Seleciona com base num PID mínimo---Obrigatório valor inteiro depois---------------------------------"
    echo " -M : Seleciona com base num PID máximo---Obrigatório valor inteiro depois---------------------------------"
    echo " -p : Número de processos a visualizar----Obrigatório valor depois-----------------------------------------"
    echo " -r : Ordenar por ordem reversa----------------------------------------------------------------------------"
    echo " -w : Ordenar por ordem decrescente do WRITEB--------------------------------------------------------------"
    echo "-----------------------------------------------------------------------------------------------------------"
}

#Funçao que valida os argumentos
function inputs() {

    #Verifica se o número de argumentos é válido
    if [[ $# == 0 ]]; then
        echo "ERRO: Tem de passar no mínimo um argumento (segundos)."
        menu_opcoes
        exit 1
    fi

    #Verifica se o último argumento passado é um numero
    if ! [[ ${@: -1} =~ ^[0-9]+$ ]]; then
		echo "ERRO: O último valor deve ser o argumento de sleep"
        menu_opcoes
		exit 1
	fi

	while getopts ":c:s:e:u:m:M:p:rw" opt; do
		case $opt in
			c)  #Verifica se a opção -c já foi utilizada
                if [[ $Comm != "NULL" ]]; then
                    echo "ERRO: A opção -c já foi utilizada."
                    menu_opcoes
                    exit 1
                fi

                #Verifica se o argumento não começa por "-" e não é o ultimo
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    Comm=$OPTARG
                    NumOpt=$(($NumOpt+1))
                    NumArg=$(($NumArg+1))
                else
                    echo "ERRO: O argumento -c tem de ser seguido de uma expressão regular"
                    menu_opcoes
                    exit 1
                fi
			;;
			s)  #Verifica se a opção -s já foi utilizada
                if [[ $DataMin != "NULL" ]]; then
                    echo "ERRO: A opção -s já foi utilizada."
                    menu_opcoes
                    exit 1
                fi
                #Verifica se o argumento não começa por "-", não é o ultimo e se é uma data válida
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    if date -d "$OPTARG" &> /dev/null; then
                        DataMin=$OPTARG
                        NumOpt=$(($NumOpt+1))
                        NumArg=$(($NumArg+1))
                    else
                        echo "ERRO: O argumento -s tem de ser seguido de uma data válida"
                        menu_opcoes
                        exit 1
                    fi    
                else
                    echo "ERRO: O argumento -s tem de ser seguido de uma data"
                    menu_opcoes
                    exit 1
                fi
			;;
			e)  #Verifica se a opção -e já foi utilizada
                if [[ $DataMax != "NULL" ]]; then
                    echo "ERRO: A opção -e já foi utilizada."
                    menu_opcoes
                    exit 1
                fi
                #Verifica se o argumento não começa por "-", não é o ultimo e se é uma data válida
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    if date -d "$OPTARG" &> /dev/null; then
                        DataMax=$OPTARG
                        NumOpt=$(($NumOpt+1))
                        NumArg=$(($NumArg+1))
                    else
                        echo "ERRO: O argumento -e tem de ser seguido de uma data válida"
                        menu_opcoes
                        exit 1
                    fi    
                else
                    echo "ERRO: O argumento -e tem de ser seguido de uma data"
                    menu_opcoes
                    exit 1
                fi
			;;
			u)  #Verifica se a opção -u já foi utilizada
                if [[ $User != "NULL" ]]; then
                    echo "ERRO: A opção -u já foi utilizada."
                    menu_opcoes
                    exit 1
                fi
                #Verifica se o argumento não começa por "-", não é o ultimo e se é um nome de utilizador válido
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    #Verificar se o User existe
                    if ! [[ $(cat /etc/passwd | cut -d ":" -f 1 | grep -w "$OPTARG") ]]; then
                        echo "ERRO: User Inválido."
                        menu_opcoes
                        exit 1
                    fi
				    User=$OPTARG
                    NumOpt=$(($NumOpt+1))
                    NumArg=$(($NumArg+1))
                else
                    echo "ERRO: O argumento -$opt tem de ser seguido de um nome de utilizador"
                    menu_opcoes
                    exit 1
                fi
			;;
			m)  #Verifica se a opção -m já foi utilizada
                if [[ $PidMin != "NULL" ]]; then
                    echo "ERRO: A opção -m já foi utilizada."
                    menu_opcoes
                    exit 1
                fi
                #Verifica se o argumento não começa por "-", não é o ultimo e se é um número inteiro
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
					    echo "ERRO: O argumento de -$opt tem de ser seguido de um número inteiro e que não seja o sleep"
                        menu_opcoes
					    exit 1
				    fi
				    PidMin=$OPTARG
                    NumOpt=$(($NumOpt+1))
                    NumArg=$(($NumArg+1))
                else
                    echo "ERRO: O argumento de -$opt tem de ser seguido de um número inteiro que não seja o sleep"
                    menu_opcoes
                    exit 1
                fi
			;;
			M)  #Verifica se a opção -M já foi utilizada
                if [[ $PidMax != "NULL" ]]; then
                    echo "ERRO: A opção -M já foi utilizada."
                    menu_opcoes
                    exit 1
                fi
                #Verifica se o argumento não começa por "-", não é o ultimo e se é um número inteiro
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                        echo "ERRO: O argumento de -$opt tem de ser seguido de um número inteiro que não seja o sleep"
                        menu_opcoes
                        exit 1
                    fi
                    PidMax=$OPTARG
                    NumOpt=$(($NumOpt+1))
                    NumArg=$(($NumArg+1))
                else
                    echo "ERRO: O argumento de -$opt tem de ser seguido de um número inteiro que não seja o sleep"
                    menu_opcoes
                    exit 1
                fi
			;;
			p)  #Verifica se a opção -p já foi utilizada
                if [[ $NumProc != "NULL" ]]; then
                    echo "ERRO: A opção -p já foi utilizada."
                    menu_opcoes
                    exit 1
                fi
                #Verifica se o argumento não começa por "-", não é o ultimo e se é um numero inteiro
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                        echo "ERRO: O argumento de -$opt tem de ser seguido de um número inteiro que não seja o sleep"
                        menu_opcoes
                        exit 1
                    fi
                    NumProc=$OPTARG
                    NumOpt=$(($NumOpt+1))
                    NumArg=$(($NumArg+1))
                else
                    echo "ERRO: O argumento de -$opt tem de ser seguido de um número inteiro que não seja o sleep"
                    menu_opcoes
                    exit 1
                fi
			;;
			r)
                #Argumento seguinte só pode começar por "-" ou ser o último
                if [[ $# == $(($OPTIND)) ]]; then
                    reverse=1
                    NumOpt=$(($NumOpt+1))    
                else
                    if ! [[ ${@: $OPTIND:1} =~ ^-[a-zA-Z] ]]; then
                        echo "ERRO: O argumento -$opt não pode ser seguido de outro argumento"
                        menu_opcoes
                        exit 1
                    else
                        reverse=1
                        NumOpt=$(($NumOpt+1))
                    fi
                fi
			;;
			w)
                #Argumento seguinte só pode começar por "-" ou ser o último
                if [[ $# == $(($OPTIND)) ]]; then
                
                    wSort=1
                    NumOpt=$(($NumOpt+1))
                    
                else
                    if ! [[ ${@: $OPTIND:1} =~ ^-[a-zA-Z] ]]; then
                        echo "ERRO: O argumento -$opt não pode ser seguido de outro argumento"
                        menu_opcoes
                        exit 1
                    else
                        wSort=1
                        NumOpt=$(($NumOpt+1))
                    fi
                fi
			;;
			:)
				echo "ERRO: A opção -$opt precisa de um argumento"
                menu_opcoes
                exit 1
			;;
			*)
				echo "ERRO: Opção não implementada"
                menu_opcoes
                exit 1
			;;
			\?)
				echo "ERRO: Opção -$opt inválida"
                menu_opcoes
				exit 1
			;;

		esac
	done

    #Verificar se o número de argumentos é válido
    if [[ $# != $(($NumOpt+$NumArg+1)) ]]; then
        echo "ERRO: Número de argumentos inválido"
        menu_opcoes
        exit 1
    fi
}

#Funçao principal do script
function proc_info() {

    sleeptime=$1 # variavel que guarda o intervalo de tempo 

    #Cabeçalho
    printf "\n %-35s %-20s %+6s %+15s %+15s %+15s %+15s %+15s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
    

    for pid in $(ps -e -o pid=); do #percorre a lista de todos os pids de processos em execução

        if [[ -r /proc/$pid/io ]] && [[ -r /proc/$pid/status ]]; then #Verifica se o ficheiro status do processo é legível

            read1[$pid]=$(cat /proc/$pid/io | grep rchar | awk '{print $2}' | tr -dc '0-9') #guarda o valor inicial de rchar do processo            
            
            write1[$pid]=$(cat /proc/$pid/io | grep wchar | awk '{print $2}') #guarda o valor inicial de wchar do processo
        fi
    done

    sleep $sleeptime #tempo de espera

    for pid in $(ps -e -o pid=); do #percorre a lista de todos os pids de processos em execução

        if [[ -r /proc/$pid/io ]] && [[ -r /proc/$pid/status ]]; then #verifica se o ficheiro status do processo é legível

            if [[ ! ${!read1[*]} =~ "${pid}" ]]; then  #verifica se o processo não está na lista de processos lidos anteriormente
                continue 
            fi
            
            readbytes2=$(cat /proc/$pid/io | grep rchar | awk '{print $2}') #guarda o valor final de rchar do processo

            writebytes2=$(cat /proc/$pid/io | grep wchar | awk '{print $2}') #guarda o valor final de wchar do processo

            readdiff=$((readbytes2-read1[$pid])) #calcula a diferença entre o valor final e o inicial de rchar

            readbps=$((readdiff/sleeptime)) #calcula a taxa de leitura em bytes por segundo
            
            writediff=$((writebytes2-write1[$pid])) #calcula a diferença entre o valor final e o inicial de wchar

            writebps=$((writediff/sleeptime)) #calcula a taxa de escrita em bytes por segundo

            comm=$(cat /proc/$pid/comm | tr -d ' ' | cut -c -35) #guarda o nome do processo sem espaços e com no máximo 35 caracteres
            
            creationdate=$(date -d "$(ps -p $pid -o lstart | tail -1 | awk '{print $1, $2, $3, $4}')" +"%b %d %H:%M") #guarda a data de criação do processo com formato "Mês Dia Hora:Minuto"

            user=$(ps -p $pid -o user | tail -1) #guarda o nome do utilizador que criou o processo
            
            # Filtração de processos

            # Filtração por nome do processo
            if [[ $Comm != "NULL" ]]; then # verifica se o nome do processo foi atribuido
                if [[ -n $Comm ]] && ! [[ $comm =~ ^$Comm+$ ]]; then # verifica se o nome do processo não contém a expressão regular dada pelo utilizador
                    continue # se não contiver, passa para o próximo processo
                fi
            fi
            
            # Filtração por data minima de criação do processo
            if [[ $DataMin != "NULL" ]]; then # verifica se a data minima de criação do processo foi atribuida
                dataMin=$(date -d "$DataMin" +"%b %d %H:%M") # converte a data minima de criação do processo para o formato "Mês Dia Hora:Minuto"
                if [[ -n $dataMin ]] && [[ $creationdate < $dataMin ]]; then # verifica se a data de criação do processo é mais antiga que a data minima atribuida
                    continue # se for, passa para o próximo processo
                fi
            fi

            # Filtração por data máxima de criação do processo
            if [[ $DataMax != "NULL" ]]; then # verifica se a data máxima de criação do processo foi atribuida
                dataMax=$(date -d "$DataMax" +"%b %d %H:%M") # converte a data máxima de criação do processo para o formato "Mês Dia Hora:Minuto"
                if [[ -n $dataMax ]] && [[ $creationdate > $dataMax ]]; then # verifica se a data de criação do processo é mais recente que a data máxima atribuida
                    continue # se for, passa para o próximo processo
                fi
            fi

            # Filtração por utilizador
            if [[ $User != "NULL" ]]; then # verifica se o nome do utilizador foi atribuido
                if [[ -n $User ]] && [[ $user != $User ]]; then # verifica se o nome do utilizador é diferente do nome do utilizador atribuido
                    continue # se for, passa para o próximo processo
                fi
            fi



            # Filtração por pid mínimo 
            if [[ $PidMin != "NULL" ]]; then # verifica se o pid minimo foi atribuido
                if [[ -n $PidMin ]] && [[ $pid -lt $PidMin ]]; then # verifica se o pid do processo é menor que o pid minimo atribuido
                    continue # se for, passa para o próximo processo
                fi
            fi



            # Filtração por pid máximo
            if [[ $PidMax != "NULL" ]]; then # verifica se o pid máximo foi atribuido
                if [[ -n $PidMax ]] && [[ $pid -gt $PidMax ]]; then # verifica se o pid do processo é maior que o pid máximo atribuido
                    continue # se for, passa para o próximo processo
                fi
            fi

            #Array com os valores a imprimir
            arrayAss[$pid]=$(printf "\n %-35s %-20s %+6s %+15s %+15s %+15s %+15s %+15s \n" "$comm" "$user" "$pid" "$readdiff" "$writediff" "$readbps" "$writebps" "$creationdate") # guarda as informações do processo num array associativo
        fi
    done
}


function sortedPrint() {
    if [[ $reverse == 1 ]]; then #reverse é 1 quando o utilizador dá o argumento -r para ordenar por ordem reversa
        if [[ $NumProc != "NULL" ]]; then #NumProc é NULL quando o utilizador não dá o arg -p para selecionar o número de processos a imprimir
            NumProc=$(($NumProc+1)) #incrementa o número de processos a imprimir pois ao fazer reverse o primeiro processo é uma linha em branco
        fi
        sort_ordem="-n" #ordem de ordenação: -n é ordem crescente (default) 
    else
        sort_ordem="-n -r" #ordem de ordenação: -n -r é ordem decrescente(ordenar por ordem reversa da default)
    fi

    if [[ $wSort == 1 ]]; then #wSort é 1 quando o utilizador dá o argumento -w para ordenar por os valores do rateW
        coluna="-k7" #Coluna a ordenar é a 7
    else
        coluna="-k6" #Coluna a ordenar é a 6
    fi


    if [[ $NumProc != "NULL" ]]; then 
        printf '%s' "${arrayAss[@]}" | sort $coluna $sort_ordem | head -n $NumProc #Imprime o array ordenado pela variável sort_ordem e cortado pelo número de processos a imprimir
    else
        printf '%s' "${arrayAss[@]}" | sort $coluna $sort_ordem #Imprime o array ordenado pela variável sort_ordem
    fi

}


inputs "$@" #Inicia a função inputs com os argumentos passados pelo utilizador

proc_info ${@: -1} #Inicia a funçao com o ultimo argumento sendo o primeiro argumento da funçao

sortedPrint #Chamada da função que imprime a tabela ordenada


