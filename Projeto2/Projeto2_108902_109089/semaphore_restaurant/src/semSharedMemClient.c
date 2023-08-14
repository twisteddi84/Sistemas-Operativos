/**
 *  \file semSharedMemClient.c (implementation file)
 *
 *  \brief Problem name: Restaurant
 *
 *  Synchronization based on semaphores and shared memory.
 *  Implementation with SVIPC.
 *
 *  Definition of the operations carried out by the clients:
 *     \li waitFriends
 *     \li orderFood
 *     \li waitFood
 *     \li travel
 *     \li eat
 *     \li waitAndPay
 *
 *  \author Nuno Lau - December 2022
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/types.h>
#include <string.h>
#include <math.h>

#include "probConst.h"
#include "probDataStruct.h"
#include "logging.h"
#include "sharedDataSync.h"
#include "semaphore.h"
#include "sharedMemory.h"

/** \brief logging file name */
static char nFic[51];

/** \brief shared memory block access identifier */
static int shmid;

/** \brief semaphore set access identifier */
static int semgid;

/** \brief pointer to shared memory region */
static SHARED_DATA *sh;

static bool waitFriends (int id);
static void orderFood (int id);
static void waitFood (int id);
static void travel (int id);
static void eat (int id);
static void waitAndPay (int id);

/**
 *  \brief Main program.
 *
 *  Its role is to generate the life cycle of one of intervening entities in the problem: the client.
 */
int main (int argc, char *argv[])
{
    int key;                                         /*access key to shared memory and semaphore set */
    char *tinp;                                                    /* numerical parameters test flag */
    int n;

    /* validation of command line parameters */
    if (argc != 5) { 
        freopen ("error_CT", "a", stderr);
        fprintf (stderr, "Number of parameters is incorrect!\n");
        return EXIT_FAILURE;
    }
    else {
       freopen (argv[4], "w", stderr);
       setbuf(stderr,NULL);
    }

    n = (unsigned int) strtol (argv[1], &tinp, 0);
    if ((*tinp != '\0') || (n >= TABLESIZE)) { 
        fprintf (stderr, "Client process identification is wrong!\n");
        return EXIT_FAILURE;
    }
    strcpy (nFic, argv[2]);
    key = (unsigned int) strtol (argv[3], &tinp, 0);
    if (*tinp != '\0') { 
        fprintf (stderr, "Error on the access key communication!\n");
        return EXIT_FAILURE;
    }

    /* connection to the semaphore set and the shared memory region and mapping the shared region onto the
       process address space */
    if ((semgid = semConnect (key)) == -1) { 
        perror ("error on connecting to the semaphore set");
        return EXIT_FAILURE;
    }
    if ((shmid = shmemConnect (key)) == -1) { 
        perror ("error on connecting to the shared memory region");
        return EXIT_FAILURE;
    }
    if (shmemAttach (shmid, (void **) &sh) == -1) { 
        perror ("error on mapping the shared region on the process address space");
        return EXIT_FAILURE;
    }

    /* initialize random generator */
    srandom ((unsigned int) getpid ());                                                 


    /* simulation of the life cycle of the client */
    travel(n);
    bool first = waitFriends(n);
    if (first) orderFood(n);
    waitFood(n);
    eat(n);
    waitAndPay(n);

    /* unmapping the shared region off the process address space */
    if (shmemDettach (sh) == -1) {
        perror ("error on unmapping the shared region off the process address space");
        return EXIT_FAILURE;;
    }

    return EXIT_SUCCESS;
}

/**
 *  \brief client goes to restaurant
 *
 *  The client takes his time to get to restaurant.
 *
 *  \param id client id
 */
static void travel (int id)
{
    usleep((unsigned int) floor ((1000000 * random ()) / RAND_MAX + 1000));
}

/**
 *  \brief client eats
 *
 *  The client takes his time to eat a pleasant dinner.
 *
 *  \param id client id
 */
static void eat (int id)
{
    usleep((unsigned int) floor ((MAXEAT * random ()) / RAND_MAX + 1000));
}

/**
 *  \brief client waits until table is complete 
 *
 *  Client should udpate state, first and last clients should register their values in shared data,
 *  last client should, in addition, inform the others that the table is complete.
 *  Client must wait in this function until the table is complete.
 *  The internal state should be saved.
 *
 *  \param id client id
 *
 *  \return true if first client, false otherwise
 */
static bool waitFriends(int id)
{
    bool first = false; //Variável de controlo para saber se o cliente é o primeiro

    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    sh->fSt.tableClients = sh->fSt.tableClients + 1; //Incrementa o número de clientes na mesa

    if(sh->fSt.tableClients == 1){ //Se só houver um cliente na mesa, então é o primeiro
        
        first = true; //Variável passa a true pois é o primeiro cliente

        sh->fSt.tableFirst = id; //
    }
    
    if(sh->fSt.tableClients == TABLESIZE){ //Se o número de clientes na mesa for igual ao tamanho da mesa, então é o último
        
        sh->fSt.tableLast = id; //Guarda o id do último cliente na mesa
        
        sh->fSt.st.clientStat[id] = WAIT_FOR_FOOD; //Altera o estado do último cliente para WAIT_FOR_FOOD(4)
        
        saveState(nFic, &(sh->fSt)); //Printa uma linha no prompt
        
        for(int i = 1; i < TABLESIZE; i++){ //Para cada cliente na mesa, exceto o último
            semUp(semgid, sh->friendsArrived); //Acorda o processo do cliente
        }
    }
    
    if (sh->fSt.tableClients != TABLESIZE){ //Se o número de clientes na mesa for diferente do tamanho da mesa, então não é o último
        
        sh->fSt.st.clientStat[id] = WAIT_FOR_FRIENDS; //Altera o estado do cliente para WAIT_FOR_FRIENDS(2)
        
        saveState(nFic, &(sh->fSt)); //Printa uma linha no prompt
    }
       /* insert your code here */


    if (semUp (semgid, sh->mutex) == -1)                                                      /* exit critical region */
    { perror ("error on the up operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    if (sh->fSt.tableClients != TABLESIZE){
        
        semDown(semgid, sh->friendsArrived); //O cliente fica à espera que os outros clientes cheguem à mesa
    }
    
    return first;
}

/**
 *  \brief first client orders food.
 *
 *  This function is used only by the first client.
 *  The first client should update its state, request food to the waiter and 
 *  wait for the waiter to receive the request.
 *  
 *  The internal state should be saved.
 *
 *  \param id client id
 */
static void orderFood (int id)
{
    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    sh->fSt.foodRequest = 1; //Flag que indica ao waiter que existe um pedido
    
    semUp(semgid, sh->waiterRequest); //Acorda o waiter pois existe um pedido (waiterRequest = 1)
    
    sh->fSt.st.clientStat[id] = FOOD_REQUEST; //Altera o estado do cliente para FOOD_REQUEST(3)
    
    saveState(nFic, &(sh->fSt)); //Printa linha no prompt com os estados atualizados

    if (semUp (semgid, sh->mutex) == -1)                                                      /* exit critical region */
    { perror ("error on the up operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    semDown(semgid, sh->requestReceived); //O cliente fica à espera que o pedido seja recebido pelo waiter
}

/**
 *  \brief client waits for food.
 *
 *  The client updates its state, and waits until food arrives. 
 *  It should also update state after food arrives.
 *  The internal state should be saved twice.
 *
 *  \param id client id
 */
static void waitFood (int id)
{

    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    
    sh->fSt.st.clientStat[id] = WAIT_FOR_FOOD; //Altera o estado do cliente para WAIT_FOR_FOOD(4)
    
    saveState(nFic, &(sh->fSt));//Printa uma linha no prompt

    if (semUp (semgid, sh->mutex) == -1) {                                                  /* exit critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */

    semDown(semgid, sh->foodArrived); //O cliente fica à espera que a comida seja entregue pelo waiter

    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */

    sh->fSt.st.clientStat[id] = EAT; //Altera o estado do cliente para EAT(5) pois a comida foi entregue
    
    saveState(nFic, &(sh->fSt)); //Printa uma linha no prompt

    if (semUp (semgid, sh->mutex) == -1) {                                                  /* exit critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }
}

/**
 *  \brief client waits for others to finish meal, last client to arrive pays the bill. 
 *
 *  The client updates state and waits for others to finish meal before leaving and update its state. 
 *  Last client to finish meal should inform others that everybody finished.
 *  Last client to arrive at table should pay the bill by contacting waiter and waiting for waiter to arrive.
 *  The internal state should be saved twice.
 *
 *  \param id client id
 */
static void waitAndPay (int id)
{
    bool last=false; //Variável que indica se o cliente é o último a chegar à mesa

    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }
    
    
    /* insert your code here */
    if(id == sh->fSt.tableLast){ //Se o cliente for o último a chegar à mesa
        
        last = true; //Variável para true pois o id atual foi o último a chegar à mesa
    
    }
    
    sh->fSt.st.clientStat[id] = WAIT_FOR_OTHERS; //Altera o estado do cliente para WAIT_FOR_OTHERS(6)
    
    saveState(nFic, &(sh->fSt)); //Printa linha no prompt com os estados atualizados

    sh->fSt.tableFinishEat = sh->fSt.tableFinishEat + 1; //Incrementa o número de clientes que terminaram de comer
    
    if (sh->fSt.tableFinishEat == TABLESIZE){ //Se o número de clientes que terminaram de comer for igual ao número de clientes à mesa
        
        for (int i = 0; i < TABLESIZE; i++){ //Para cada cliente à mesa
            semUp (semgid, sh->allFinished); //Acorda o cliente                      
        }
    }
    

    if (semUp (semgid, sh->mutex) == -1) {                                                  /* exit critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    semDown (semgid, sh->allFinished); //O cliente fica à espera que todos os outros clientes terminem de comer

    if(last == true) { //Se o cliente atual foi o último a chegar à mesa
        if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
           perror ("error on the down operation for semaphore access (CT)");
           exit (EXIT_FAILURE);
        }

        /* insert your code here */
        sh->fSt.st.clientStat[id] = WAIT_FOR_BILL; /*Altera o estado do cliente para WAIT_FOR_BILL(7) 
        pois o ultimo cliente a chegar à mesa está à espera da conta*/
        
        saveState(nFic, &sh->fSt); //Printa linha no prompt com os estados atualizados
        
        sh->fSt.paymentRequest = 1; //Indica ao waiter que o cliente está à espera da conta

        semUp (semgid, sh->waiterRequest); //Acorda o waiter pois o cliente está à espera da conta
        
        if (semUp (semgid, sh->mutex) == -1) {                                                  /* exit critical region */
            perror ("error on the down operation for semaphore access (CT)");
            exit (EXIT_FAILURE);
        }

        /* insert your code here */
        semDown(semgid, sh->requestReceived); //O cliente fica à espera que o waiter receba o pedido de conta

    }

    if (semDown (semgid, sh->mutex) == -1) {                                                  /* enter critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    sh->fSt.st.clientStat[id] = FINISHED;//Altera o estado do cliente para FINISHED(8) pois vai abandonar o restaurante
    
    saveState(nFic, &(sh->fSt)); //Printa linha no prompt com os estados atualizados

    if (semUp (semgid, sh->mutex) == -1) {                                                  /* exit critical region */
        perror ("error on the down operation for semaphore access (CT)");
        exit (EXIT_FAILURE);
    }
}   

