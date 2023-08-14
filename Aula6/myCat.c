#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

/* SUGESTÂO: utilize as páginas do manual para conhecer mais sobre as funções usadas:
 man fopen
 man fgets
*/

#define LINEMAXSIZE 50 /* or other suitable maximum line size */


int main(int argc, char *argv[])
{
    FILE *fp = NULL;
    char line [LINEMAXSIZE]; 
    int primeiro = 0;

    /* Read all the lines of the file */
    int count = 1;
    for(int i = 1; i<argc ; i++){
        errno = 0;
        fp = fopen(argv[i], "r");
        if( fp == NULL )
        {
            perror ("Error opening file!");
            return EXIT_FAILURE;
        }
        while( fgets(line, sizeof(line), fp) != NULL )
        {
            
            int size = strlen(line);
            if(line[size-1]!='\n'){
                if(primeiro == 0){
                    printf("%d -> %s",count,line);
                    primeiro = 1;
                }else{
                    printf("%s",line);
                }
                
            }else{
                if(primeiro == 1){
                    printf("%s",line);
                    primeiro = 0;
                }else{
                    printf("%d -> %s", count++,line); /* not needed to add '\n' to printf because fgets will read the '\n' that ends each line in the file */
                }
                
            }
            
        
        }
        fclose(fp);
    }

    return EXIT_SUCCESS;
}
