#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
    char valor_min = argv[1][0]; //Valor inicial vai ser o primeiro caracter do arg 1
    char *sortedArray[argc - 1]; //Array para guardar as strings ordenadas
    int index_valor_min = 1;
    for(int j = 1; j<argc;j++){
        valor_min = argv[j][0];
        for (int i = 1; i<argc;i++){
            if(argv[i]=='0'){

                continue;
            }
            if(valor_min>argv[i][0]){
                valor_min = argv[i][0];
                index_valor_min = i;
            }
        
        sortedArray[j-1] = argv[index_valor_min];
        printf("Valor min: %s\n",sortedArray[j-1]);
        argv[index_valor_min] = '0';
    }
    return EXIT_SUCCESS;
}
}