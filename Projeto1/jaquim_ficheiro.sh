#!/bin/bash


declare -A arrayAss=()
declare -A read1=()
declare -A write1=()

declare Comm="NULL"
declare DataMin="NULL"
declare DataMax="NULL"
declare User="NULL"
declare PidMin="NULL"
declare PidMax="NULL"
declare NumProc="NULL"

declare reverse=0
declare wSort=0
declare NumArg=0
declare NumOpt=0




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

function inputs() {

    if [[ $# == 0 ]]; then
        echo "ERRO: Tem de passar no mínimo um argumento (segundos)."
        menu_opcoes
        exit 1
    fi

    if ! [[ ${@: -1} =~ ^[0-9]+$ ]]; then
		echo "ERRO: O último valor deve ser o argumento de sleep"
        menu_opcoes
		exit 1
	fi

	while getopts ":c:s:e:u:m:M:p:rw" opt; do
		case $opt in
			c) 
                #Verificar se próximo argumento não começa por "-" e não é o ultimo
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
			s)  
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
			e)
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
			u)  if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    #Validar se o user existe
                    if ! [[ $(cat /etc/passwd | cut -d ":" -f 1 | grep -w "$OPTARG") ]]; then
                        echo "ERRO: User Inválido."
                        menu_opcoes
                        exit 1
                    fi
				    User=$OPTARG #adicionar opções e validação
                    NumOpt=$(($NumOpt+1))
                    NumArg=$(($NumArg+1))
                else
                    echo "ERRO: O argumento -$opt tem de ser seguido de um nome de utilizador"
                    menu_opcoes
                    exit 1
                fi
			;;
			m)
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
					    echo "ERRO: O argumento de -$opt tem de ser seguido de um número inteiro e que não seja o sleep"
                        menu_opcoes
                        #adicionar opções
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
			M)
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                        echo "ERRO: O argumento de -$opt tem de ser seguido de um número inteiro que não seja o sleep"
                        menu_opcoes
                        #adicionar opções
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
			p)
                #Proximo argumento nao pode ser o ultimo e nao pode começar por "-"
                if [[ $# != $(($OPTIND-1)) ]] && ! [[ $OPTARG =~ ^-[a-zA-Z] ]]; then
                    if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                        echo "ERRO: O argumento de -$opt tem de ser seguido de um número inteiro que não seja o sleep"
                        menu_opcoes
                        #adicionar opções
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
                #adicionar opções
                exit 1
			;;
			*)
				echo "ERRO: Opção não implementada"
                menu_opcoes
                #adicionar opções
                exit 1
			;;
			\?)
				echo "ERRO: Opção -$opt inválida"
                menu_opcoes
                #adicionar opções
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


function get_pid_stats() {

    local sleeptime=$1

    printf "\n %-35s %-20s %+6s %+15s %+15s %+15s %+15s %+15s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
    
    for pid in $(ps -e -o pid=); do
        # if the user has permission to read the /proc/[pid]/io file
        if [[ -r /proc/$pid/status ]]; then
            # get the readbytes and writebytes of the process
            read1[$pid]=$(sudo cat /proc/$pid/io | grep rchar | awk '{print $2}')
            
            write1[$pid]=$(sudo cat /proc/$pid/io | grep wchar | awk '{print $2}')



        fi
    done

    sleep $sleeptime

    for pid in $(ps -e -o pid=); do
    # if the user has permission to read the /proc/[pid]/io file
        if [[ -r /proc/$pid/status ]]; then
            
            readbytes2=$(sudo cat /proc/$pid/io | grep rchar | awk '{print $2}')


            writebytes2=$(sudo cat /proc/$pid/io | grep wchar | awk '{print $2}')

            #Calculate the difference between the absolute values of the read1 and read2
            readdiff=$((readbytes2-read1[$pid]))

            readbps=$((readdiff/sleeptime))

            readdiff=$((readbytes2-read1[$pid]))
            
            writediff=$((writebytes2-write1[$pid]))

            writebps=$((writediff/sleeptime))

            

            #create a variable for the /proc/[pid]/comm file and trim spaces and not exceed 35 characters

            local comm=$(sudo cat /proc/$pid/comm | tr -d ' ' | cut -c -35)
            
            #create a variable for the creation date and time without the seconds and year of the process
            local creationdate=$(date -d "$(ps -p $pid -o lstart | tail -1 | awk '{print $1, $2, $3, $4}')" +"%b %d %H:%M")

            #create a variable for the user of the process
            local user=$(ps -p $pid -o user | tail -1)

            #filter comm (é preciso ponto?)
            if [[ $Comm != "NULL" ]]; then
                if [[ -n $Comm ]] && ! [[ $comm =~ $Comm ]]; then
                    continue
                fi
            fi
            
            #filter dateMin (parece tudo bem)
            if [[ $DataMin != "NULL" ]]; then
                dataMin=$(date -d "$DataMin" +"%b %d %H:%M")
                if [[ -n $dataMin ]] && [[ $creationdate < $dataMin ]]; then
                    continue
                fi
            fi

            #filter dateMax (parece tudo bem)
            if [[ $DataMax != "NULL" ]]; then
                dataMax=$(date -d "$DataMax" +"%b %d %H:%M")
                if [[ -n $dataMax ]] && [[ $creationdate > $dataMax ]]; then
                    continue
                fi
            fi

            #filter user (é preciso ponto?)
            if [[ $User != "NULL" ]]; then
                if [[ -n $User ]] && [[ $user != $User ]]; then
                    continue
                fi
            fi

            #filter pidMin (funciona mas TEM FALHAS)
            if [[ $PidMin != "NULL" ]]; then
                if [[ -n $PidMin ]] && [[ $pid < $PidMin ]]; then
                    continue
                fi
            fi

            #filter pidMax (funciona mas TEM FALHAS)
            if [[ $PidMax != "NULL" ]]; then
                if [[ -n $PidMax ]] && [[ $pid > $PidMax ]]; then
                    continue
                fi
            fi
            
            arrayAss[$pid]=$(printf "\n %-35s %-20s %+6s %+15s %+15s %+15s %+15s %+15s \n" "$comm" "$user" "$pid" "$readdiff" "$writediff" "$readbps" "$writebps" "$creationdate")
        fi
    done
}


function sortedPrint() {
    if [[ $reverse == 1 ]]; then
        if [[ $NumProc != "NULL" ]]; then
            NumProc=$(($NumProc+1))
        fi
        sort_ordem="-n"
    else
        sort_ordem="-n -r"
    fi

    if [[ $wSort == 1 ]]; then
        coluna="-k7"
    else
        coluna="-k6"
    fi
    if [[ $NumProc != "NULL" ]]; then
        printf '%s' "${arrayAss[@]}" | sort $coluna $sort_ordem | head -n $NumProc
    else
        printf '%s' "${arrayAss[@]}" | sort $coluna $sort_ordem
    fi
}


inputs "$@"

get_pid_stats ${@: -1}

sortedPrint


