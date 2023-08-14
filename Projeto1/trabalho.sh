#Arrays
declare -A arrayAss=() # Array Associativo: está guardado a informação de cada processo, sendo a 'key' o PID
declare -A argOpt=()   # Array Associativo: está guardada a informação das opções passadas como argumentos na chamada da função
declare -A R1=()
declare -A W1=()

i=0 #iniciação da variável i, usada na condição de verificação de opçoes de ordenac
re='^[0-9]+([.][0-9]+)?$'

#Função para quando argumentos passados são inválidos
function opcoes() {
    echo "************************************************************************************************"
    echo "OPÇÃO INVÁLIDA!"
    echo "    -c          : Seleção de processos a utilizar através de uma expressão regular"
    echo "    -u          : Seleção de processos a visualizar através do nome do utilizador"
    echo "    -r          : Ordenação reversa"
    echo "    -s          : Seleção de processos a visualizar num periodo temporal - data mínima"
    echo "    -e          : Seleção de processos a visualizar num periodo temporal - data máxima"
    echo "    -d          : Ordenação da tabela por RATER (decrescente)"
    echo "    -m          : Ordenação da tabela por MEM (decrescente)" 
    echo "    -t          : Ordenação da tabela por RSS (decrescente)"
    echo "    -w          : Ordenação da tabela pOR RATEW (decrescente)"
    echo "    -p          : Número de processos a visualizar"
    echo "   Nota         : As opções -d,-m,-t,-w não podem ser utilizadas em simultâneo"
    echo "Último argumento: O último argumento passado tem de ser um número"
    echo "************************************************************************************************"
}

#Tratamentos das opçoes passadas como argumentos
while getopts "c:u:rs:e:dmtwp:" option; do

    #Adicionar ao array argOpt as opcoes passadas ao correr o procstat.sh, caso existam adiciona as que são passadas, caso não, adiciona "nada"
    if [[ -z "$OPTARG" ]]; then
        argOpt[$option]="nada"
    else
        argOpt[$option]=${OPTARG}
    fi

    case $option in
    c) #Seleção de processos a utilizar atraves de uma expressão regular
        str=${argOpt['c']}
        if [[ $str == 'nada' || ${str:0:1} == "-" || $str =~ $re ]]; then
            echo "Argumento de '-c' não foi preenchido, foi introduzido argumento inválido ou chamou sem '-' atrás da opção passada." >&2
            opcoes
            exit 1
        fi
        ;;
    s) #Seleção de processos a visualizar num periodo temporal - data mínima
        str=${argOpt['s']}
        regData='^((Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(tember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)) +[0-9]{1,2} +[0-9]{1,2}:[0-9]{1,2}'
        if [[ $str == 'nada' || ${str:0:1} == "-" || $str =~ $re || ! "$str" =~ $regData ]]; then
            echo "Argumento de '-s' não foi preenchido, foi introduzido argumento inválido ou chamou sem '-' atrás da opção passada." >&2
            opcoes
            exit 1
        fi
        ;;
    e) #Seleção de processos a visualizar num periodo temporal - data máxima
        str=${argOpt['e']}
        regData='^((Jan(uary)?|Feb(ruary)?|Mar(ch)?|Apr(il)?|May|Jun(e)?|Jul(y)?|Aug(ust)?|Sep(tember)?|Oct(ober)?|Nov(ember)?|Dec(ember)?)) +[0-9]{1,2} +[0-9]{1,2}:[0-9]{1,2}'
        if [[ $str == 'nada' || ${str:0:1} == "-" || $str =~ $re || ! "$str" =~ $regData ]]; then
            echo "Argumento de '-e' não foi preenchido, foi introduzido argumento inválido ou chamou sem '-' atrás da opção passada." >&2
            opcoes
            exit 1
        fi
        ;;
    u) #Seleção de processos a visualizar através do nome do utilizador
        str=${argOpt['u']}
        if [[ $str == 'nada' || ${str:0:1} == "-" || $str =~ $re ]]; then
            echo "Argumento de '-u' não foi preenchido, foi introduzido argumento inválido ou chamou sem '-' atrás da opção passada." >&2
            opcoes
            opcoes exit 1
        fi
        ;;
    p) #Número de processos a visualizar
        if ! [[ ${argOpt['p']} =~ $re ]]; then
            echo "Argumento de '-p' tem de ser um número ou chamou sem '-' atrás da opção passada." >&2
            opcoes
            exit 1
        fi
        ;;
    r) #Ordenação reversa

        ;;
    m | t | d | w)

        if [[ $i = 1 ]]; then
            #Quando há mais que 1 argumento de ordenacao
            opcoes
            exit 1
        else
            #Se algum argumento for de ordenacao i=1
            i=1
        fi
        ;;

    *) #Passagem de argumentos inválidos
        opcoes
        exit 1
        ;;
    esac

done

if [[ $# == 0 ]]; then
    echo "Tem de passar no mínimo um argumento (segundos)."
    opcoes
    exit 1
fi

# Verificação se o último argumento passado é um numero

if ! [[ ${@: -1} =~ $re ]]; then
    echo "Último argumento tem de ser um número."
    opcoes
    exit 1
fi

#Tratamento dos dados lidos
function listarProcessos() {

    #Cabeçalho
    printf "%-27s %-16s %15s %12s %12s %15s %15s %16s\n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
    for entry in /proc/[[:digit:]]*; do
        if [[ -r $entry/status && -r $entry/io ]]; then
            PID=$(cat $entry/status | grep -w Pid | tr -dc '0-9') # ir buscar o PID
            rchar1=$(cat $entry/io | grep rchar | tr -dc '0-9')   # rchar inicial
            wchar1=$(cat $entry/io | grep wchar | tr -dc '0-9')   # wchar inicial

            if [[ $rchar1 == 0 && $wchar == 0 ]]; then
                continue
            else
                R1[$PID]=$(printf "%12d\n" "$rchar1")
                W1[$PID]=$(printf "%12d\n" "$wchar1")
            fi
        fi

    done

    sleep $1 # tempo em espera

    for entry in /proc/[[:digit:]]*; do

        if [[ -r $entry/status && -r $entry/io ]]; then

            PID=$(cat $entry/status | grep -w Pid | tr -dc '0-9') # ir buscar o PID
            user=$(ps -o user= -p $PID)                           # ir buscar o user do PID

            comm=$(cat $entry/comm | tr " " "_") # ir buscar o comm,e retirar os espaços e substituir por '_' nos comm's com 2 nomes

            if [[ -v argOpt[u] && ! ${argOpt['u']} == $user ]]; then
                continue
            fi

            #Seleção de processos a utilizar atraves de uma expressão regular
            if [[ -v argOpt[c] && ! $comm =~ ${argOpt['c']} ]]; then
                continue
            fi

            LANG=en_us_8859_1
            startDate=$(ps -o lstart= -p $PID) # data de início do processo atraves do PID
            startDate=$(date +"%b %d %H:%M" -d "$startDate")
            dateSeg=$(date -d "$startDate" +"%b %d %H:%M"+%s | awk -F '[+]' '{print $2}') # data do processo em segundos

            if [[ -v argOpt[s] ]]; then                                                         #Para a opção -s
                start=$(date -d "${argOpt['s']}" +"%b %d %H:%M"+%s | awk -F '[+]' '{print $2}') # data mínima

                if [[ "$dateSeg" -lt "$start" ]]; then
                    continue
                fi
            fi

            if [[ -v argOpt[e] ]]; then                                                       #Para a opção -e
                end=$(date -d "${argOpt['e']}" +"%b %d %H:%M"+%s | awk -F '[+]' '{print $2}') # data máxima

                if [[ "$dateSeg" -gt "$end" ]]; then
                    continue
                fi
            fi

            rchar2=$(cat $entry/io | grep rchar | tr -dc '0-9') # rchar apos s segundos
            wchar2=$(cat $entry/io | grep wchar | tr -dc '0-9') # wchar apos s segundos
            subr=$rchar2-${R1[$PID]}
            subw=$wchar2-${W1[$PID]}
            rateR=$(echo "scale=2; $subr/$1" | bc -l) # calculo do rateR
            rateW=$(echo "scale=2; $subw/$1" | bc -l) # calculo do rateW

            arrayAss[$PID]=$(printf "%-27s %-16s %15d %12d %12d %15s %15s %16s\n" "$comm" "$user" "$PID" "${R1[$PID]}" "${W1[$PID]}" "$rateR" "$rateW" "$startDate")
        fi
    done

    prints
}

function prints() {

    if ! [[ -v argOpt[r] ]]; then
        ordem="-rn"
    else
        ordem="-n"
    fi

    #Se não dermos nenhum valor ao -p, fica com o valor do tamanho do array
    #Ou seja printa todos
    if ! [[ -v argOpt[p] ]]; then
        p=${#arrayAss[@]}
    #Nº de processos que queremos ver
    else
        p=${argOpt['p']}
    fi

    if [[ -v argOpt[m] ]]; then
        #Ordenação da tabela pelo MEM
        printf '%s \n' "${arrayAss[@]}" | sort $ordem -k4 | head -n $p

    elif [[ -v argOpt[t] ]]; then
        #Ordenação da tabela pelo RSS
        printf '%s \n' "${arrayAss[@]}" | sort $ordem -k5 | head -n $p

    elif [[ -v argOpt[d] ]]; then
        #Ordenação da tabela pelo RATER
        printf '%s \n' "${arrayAss[@]}" | sort $ordem -k8 | head -n $p

    elif [[ -v argOpt[w] ]]; then
        #Ordenação da tabela pelo RATEW
        printf '%s \n' "${arrayAss[@]}" | sort $ordem -k9 | head -n $p

    else
        #Ordenação default da tabela, ordem alfabética dos processos
        ordem="-n" #Como é por ordem alfabética temos de mudar a ordem para '-n'

        printf '%s \n' "${arrayAss[@]}" | sort $ordem -k1 | head -n $p

    fi

}

listarProcessos ${@: -1} #este agumento passado, é para os segundos, visto que é passado em todas as opções, e é sempre o último