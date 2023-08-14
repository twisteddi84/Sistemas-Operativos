#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

typedef struct
{
    int age;
    double height;
    char name[64];
} Person;

void printPersonInfo(Person *p)
{
    printf("Person: %s, %d, %f\n", p->name, p->age, p->height);
}

int main (int argc, char *argv[])
{
    FILE *fp = NULL;
    int i;
    Person p = {35, 1.65, "xpto"};

    /* Validate number of arguments */
    if(argc != 2)
    {
        printf("USAGE: %s fileName\n", argv[0]);
        return EXIT_FAILURE;
    }

    /* Open the file provided as argument */
    errno = 0;
    fp = fopen(argv[1], "wb");
    if(fp == NULL)
    {
        perror ("Error opening file!");
        return EXIT_FAILURE;
    }

    /* Write 10 itens on a file */
    int quant_pessoas;
    printf("Quantidade de pessoas: ");
    scanf("%d",&quant_pessoas);
    for(i = 0 ; i < quant_pessoas ; i++)
    {   
        int idade;
        double altura;
        printf("Nome pessoa %d: ",i+1);
        scanf("%s",&p.name);
        printf("Idade pessoa %d: ",i+1);
        scanf("%d",&idade);
        printf("Altura pessoa %d: ",i+1);
        scanf("%lf",&altura);
        p.age = idade;
        p.height = altura;
        fwrite(&p, sizeof(Person), 1, fp);
    }
    fclose(fp);

    return EXIT_SUCCESS;
}
