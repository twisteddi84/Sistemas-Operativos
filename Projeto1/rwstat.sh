#!/bin/bash

# This is a function that will write to the terminal the readbytes and writebytes of a process 
declare Comm
declare DataMin
declare DataMax
declare User
declare PidMin
declare PidMax
declare NumProc
declare count=0

function menu_opcoes(){
    echo "-------------------------------------------ARGUMENTOS INVÀLIDOS--------------------------------------------"
    echo "-----------------------------------------------------------------------------------------------------------"
    echo "--------------------------------------OPÇÕES DE ARGUMENTOS VÁLIDOS:----------------------------------------"
    echo "------------------------***ATENÇÃO: Último arg tem de ser um valor de segundos***--------------------------"
    echo " -c : Seleciona os processos com base numa expressão regular---Exemplo: d* (Mostra Comm começados por d)---"
    echo " -s : Seleciona com base numa data mínima ---Exemplo: Jan 10 10:00 ----------------------------------------"
    echo " -e : Seleciona com base numa data máxima ---Exemplo: Jan 10 10:00-----------------------------------------"
    echo " -u : Seleciona com base no nome de utilizador---(\"semnome\") para print sem nome de utilizador-------------"
    echo " -m : Seleciona com base num PID mínimo---Obrigatório valor inteiro depois---------------------------------"
    echo " -M : Seleciona com base num PID máximo---Obrigatório valor inteiro depois---------------------------------"
    echo " -p : Número de processos a visualizar----Obrigatório valor depois-----------------------------------------"
    echo " -r : Ordenar por ordem reversa----------------------------------------------------------------------------"
    echo " -w : Ordenar por ordem decrescente do WRITEB--------------------------------------------------------------"
    echo "-----------------------------------------------------------------------------------------------------------"
}

function inputs() {
    if ! [[ ${@: -1} =~ ^[0-9]+$ ]]; then
		echo "ERRO: O último valor deve ser o argumento de sleep"
        menu_opcoes
		exit
	fi
	while getopts ":c:s:e:u:m:M:p:rw" opt; do
		case $opt in
			c)
				Comm=$OPTARG
			;;
			s)
                DataMin=$OPTARG
			;;
			e)
                DataMax=$OPTARG
			;;
			u)
				User=$OPTARG
			;;
			m)
                if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
					echo "O argumento de -$opt deve ser um número inteiro"
					exit
				fi
				PidMin=$OPTARG
			;;
			M)
                if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
					echo "O argumento de -$opt deve ser um número inteiro"
					exit
				fi
				PidMax=$OPTARG
			;;
			p)
				if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
					echo "O argumento de -$opt deve ser um número inteiro"
					exit
				fi
				NumProc=$OPTARG
			;;
			r)
                exit #por fazer
			;;
			w)
                exit #por fazer
			;;
			:)
				echo "ERRO: A opção -$opt precisa de um argumento"
                exit
			;;
			*)
				echo "ERRO: Opção -$opt não implementada"
                exit
			;;
			\?)
				echo "ERRO: Opção -$opt inválida"
				exit
			;;

		esac
	done
}


function get_pid_stats() {

    local pid=$1

    local sleeptime=$2

    # get the readbytes and writebytes of the process
    local readbytes=$(grep -E 'read_bytes' /proc/$pid/io | awk '{print $2}')
    
    local writebytes=$(grep -E 'write_bytes' -w /proc/$pid/io | awk '{print $2}')

    #sleep for sleeptime
    sleep $sleeptime

    # get the read and write bytes stats again
    local readbytes2=$(grep -E 'read_bytes' /proc/$pid/io | awk '{print $2}')

    local writebytes2=$(grep -E 'write_bytes' -w /proc/$pid/io | awk '{print $2}')

    # calculate the read bytes per second and write bytes per second

    local readbps=$((($readbytes2 - $readbytes) / $sleeptime))

    local writebps=$((($writebytes2 - $writebytes) / $sleeptime))

    #create a variable for the /proc/[pid]/comm file
    local comm=$(cat /proc/$pid/comm)

    #create a variable for the creation date and time without the seconds and year of the process
    local creationdate=$(date -d "$(ps -p $pid -o lstart | tail -1 | awk '{print $1, $2, $3, $4}')" +"%b %d %H:%M")

    #create a variable for the user of the process
    local user=$(ps -p $pid -o user | tail -1)

    #filter comm
    if [[ -n $Comm ]] && [[ $Comm != $comm ]]; then
        return
    fi
    
    #filter dateMin
    dataMin=$(date -d "$DataMin" +"%b %d %H:%M")
    if [[ -n $dataMin ]] && [[ $dataMin > $creationdate ]]; then
        echo "NAO TA A FUNFAR"
        return
    fi

    #filter dateMax
    dataMax=$(date -d "$DataMax" +"%b %d %H:%M")
    if [[ -n $dataMax ]] && [[ $dataMax < $creationdate ]]; then
        return
    fi

    #filter user
    if [[ -n $User ]] && [[ $User != $user ]]; then
        return
    fi

    #filter pidMin
    if [[ -n $PidMin ]] && [[ $PidMin > $pid ]]; then
        return
    fi

    #filter pidMax
    if [[ -n $PidMax ]] && [[ $PidMax < $pid ]]; then
        return
    fi

    #filter numProc
    if [[ -n $NumProc ]] && [[ $count -gt $NumProc ]]; then
        exit
    fi


    #print a table with the process comm, user, pid, readbytes, writebytes, readbps, writebps, creationdate
    printf "\n %-20s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "$comm" "$user" "$pid" "$readbytes" "$writebytes" "$readbps" "$writebps" "$creationdate"

    #count the number of processes
    count=$((count+1))
}

inputs "$@"

printf "\n %-20s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
ps -u $USER -o pid= | while read pid; do
# if the user has permission to read the /proc/[pid]/io file
    if [ -r /proc/$pid/io ]; then
        get_pid_stats $pid ${@: -1}
    fi
done