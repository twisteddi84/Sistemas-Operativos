#include <stdio.h>
#include <stdlib.h>

/* SUGESTÂO: utilize as páginas do manual para conhecer mais sobre as funções usadas:
 man qsort
*/

int compareInts(const void *px1, const void *px2)
{
    int x1 = *((int *)px1);
    int x2 = *((int *)px2);
    return(x1 < x2 ? -1 : x1 == x2 ? 0 : 1);
}

int main(int argc, char *argv[])
{
    #define LINEMAXSIZE 100
    int i, numSize;
    int *numbers;
    char line [LINEMAXSIZE];

    FILE *fp = NULL;
    fp = fopen(argv[i], "r");
    int count = 0;
    for(int i = 1; i<argc ; i++){
        fp = fopen(argv[i], "r");
        if( fp == NULL )
        {
            perror ("Error opening file!");
            return EXIT_FAILURE;
        }
        while( fgets(line, sizeof(line), fp) != NULL )
        {
            printf("%s",line); /* not needed to add '\n' to printf because fgets will read the '\n' that ends each line in the file */
            count += 1;
        }
        fclose(fp);
    }

    numSize = count;

    /* Memory allocation for all the numbers in the arguments */
    numbers = (int *) malloc(sizeof(int) * numSize);

    /* Storing the arguments in the "array" numbers */
    for(int i = 1; i<argc ; i++){
        fp = fopen(argv[i], "r");
        
        while( fgets(line, sizeof(line), fp) != NULL )
        {
            numbers[i] = atoi(line);
        }
        fclose(fp);
    }

    /* void qsort(void *base, size_t nmemb, size_t size, int (*compar)(const void *, const void *)); 
         The qsort() function sorts an array with nmemb elements of size size.*/
    qsort(numbers, numSize, sizeof(int), compareInts);

    /* Printing the sorted numbers */
    printf("Sorted numbers: \n");
    for(i = 0 ; i < numSize ; i++)
    {
        printf("%d\n", numbers[i]);
    }

    return EXIT_SUCCESS;
}
