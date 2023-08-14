#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char *argv[]){
    if(argc!=4){
        printf("Numero de argumentos inválido (2) \n");
        return EXIT_FAILURE;
    }
    char *endarg;
    float numero_1 = strtod(argv[1],&endarg);

    if(endarg==argv[1] || *endarg != '\0'){
        printf("Numero 1 invalido.\n");
        return EXIT_FAILURE;
    }


    float numero_2 = strtod(argv[3],&endarg);
    
    if(endarg==argv[3] || *endarg != '\0'){
        printf("Numero 2 invalido.\n");
        return EXIT_FAILURE;
    }

    switch (*argv[2]){
        case 'p':
            printf("%.2f p %.2f = %.2f\n",numero_1,numero_2,pow(numero_1,numero_2));
        break;

        case '+':
            printf("%.2f + %.2f = %.2f\n",numero_1,numero_2,numero_1+numero_2);
        break;
        case '-':
            printf("%.2f - %.2f = %.2f\n",numero_1,numero_2,numero_1-numero_2);
        break;
        case 'x':
            printf("%.2f x %.2f = %.2f\n",numero_1,numero_2,numero_1*numero_2);
        break;
        case '/':
            printf("%.2f / %.2f = %.2f\n",numero_1,numero_2,numero_1/numero_2);
        break;
    }
    return EXIT_SUCCESS;
}