/**
 *  \file semSharedMemWaiter.c (implementation file)
 *
 *  \brief Problem name: Restaurant
 *
 *  Synchronization based on semaphores and shared memory.
 *  Implementation with SVIPC.
 *
 *  Definition of the operations carried out by the waiter:
 *     \li waitForClientOrChef
 *     \li informChef
 *     \li takeFoodToTable
 *     \li receivePayment
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
#include <assert.h>

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

/** \brief waiter waits for next request */
static int waitForClientOrChef ();

/** \brief waiter takes food order to chef */
static void informChef();

/** \brief waiter takes food to table */
static void takeFoodToTable ();

/** \brief waiter receives payment */
static void receivePayment ();

#define FOODREQ   1
#define FOODREADY 2
#define BILL      3


/**
 *  \brief Main program.
 *
 *  Its role is to generate the life cycle of one of intervening entities in the problem: the waiter.
 */
int main (int argc, char *argv[])
{
    int key;                                            /*access key to shared memory and semaphore set */
    char *tinp;                                                       /* numerical parameters test flag */

    /* validation of command line parameters */
    if (argc != 4) { 
        freopen ("error_WT", "a", stderr);
        fprintf (stderr, "Number of parameters is incorrect!\n");
        return EXIT_FAILURE;
    }
    else { 
        freopen (argv[3], "w", stderr);
        setbuf(stderr,NULL);
    }

    strcpy (nFic, argv[1]);
    key = (unsigned int) strtol (argv[2], &tinp, 0);
    if (*tinp != '\0')
    { fprintf (stderr, "Error on the access key communication!\n");
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

    /* simulation of the life cycle of the waiter */
    int req, nReq=0;
    while(nReq<3) {
        req = waitForClientOrChef();
        switch(req) {
            case FOODREQ:
                   informChef();
                   break;
            case FOODREADY:
                   takeFoodToTable();
                   break;
            case BILL:
                   receivePayment();
                   break;
        }
        nReq++;
    }

    /* unmapping the shared region off the process address space */
    if (shmemDettach (sh) == -1) {
        perror ("error on unmapping the shared region off the process address space");
        return EXIT_FAILURE;;
    }

    return EXIT_SUCCESS;
}

/**
 *  \brief waiter waits for next request 
 *
 *  Waiter updates state and waits for request from client or from chef, then reads request.
 *  The internal state should be saved.
 *
 *  \return type of request (FOODREQ, FOODREADY, PAYREQ)
 */
static int waitForClientOrChef()
{
    int ret=0; //Variavel que vai guardar o tipo de açao que o waiter vai executar
    
    if (semDown (semgid, sh->mutex) == -1)  {                                                  /* enter critical region */
        perror ("error on the up operation for semaphore access (WT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    
    sh->fSt.st.waiterStat = WAIT_FOR_REQUEST; //Alterar o estado do waiter para WAIT_FOR_REQUEST(0) pois ele vai esperar por um pedido
    
    saveState(nFic, &(sh->fSt)); //Printa linha no prompt com os estados atualizados

    
    if (semUp (semgid, sh->mutex) == -1)      {                                             /* exit critical region */
        perror ("error on the down operation for semaphore access (WT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    semDown (semgid, sh->waiterRequest); //Waiter espera por um pedido (waiterRequest=0)

    if (semDown (semgid, sh->mutex) == -1)  {                                                  /* enter critical region */
        perror ("error on the up operation for semaphore access (WT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    if (sh->fSt.foodRequest == 1) { //Se o pedido for de comida (alterado pelo cliente)
        
        ret = FOODREQ; //ret=1
        
        sh->fSt.foodRequest = 0; //Volta a por o pedido de comida a 0

    } else if (sh->fSt.foodReady == 1) { //Se a comida já está pronta para levar à mesa (alterado pelo chef)

        ret = FOODREADY; //ret=2

        sh->fSt.foodReady = 0; //Volta a chamada do chef a 0

    } else if (sh->fSt.paymentRequest == 1) { //Se o pedido for de pagamento (alterado pelo cliente)
        
        ret = BILL; //ret=3

        sh->fSt.paymentRequest = 0; //Volta a por o pedido de pagamento a 0
        
    }

    if (semUp (semgid, sh->mutex) == -1) {                                                  /* exit critical region */
     perror ("error on the down operation for semaphore access (WT)");
        exit (EXIT_FAILURE);
    }

    return ret;

}

/**
 *  \brief waiter takes food order to chef 
 *
 *  Waiter updates state and then takes food request to chef.
 *  The internal state should be saved.
 *
 */
static void informChef ()
{
    if (semDown (semgid, sh->mutex) == -1)  {                                                  /* enter critical region */
        perror ("error on the up operation for semaphore access (WT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    sh->fSt.foodOrder = 1; //Flag que indica ao chef que existe um pedido de comida
    
    sh->fSt.st.waiterStat = INFORM_CHEF; //Alterar o estado do waiter para INFORM_CHEF(1) pois ele vai informar o chef do pedido
    
    saveState(nFic, &(sh->fSt)); //Printa linha no prompt com os estados atualizados

    if (semUp (semgid, sh->mutex) == -1)                                                   /* exit critical region */
    { perror ("error on the down operation for semaphore access (WT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    semUp (semgid, sh->requestReceived); //Acorda cliente que realizou o pedido para que ele espere pela comida

    semUp (semgid, sh->waitOrder); //Acorda o chef para que ele pcomece a preparar a comida
}

/**
 *  \brief waiter takes food to table 
 *
 *  Waiter updates its state and takes food to table, allowing the meal to start.
 *  The internal state should be saved.
 *
 */
static void takeFoodToTable ()
{
    if (semDown (semgid, sh->mutex) == -1)  {                                                  /* enter critical region */
        perror ("error on the up operation for semaphore access (WT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    sh->fSt.st.waiterStat = TAKE_TO_TABLE; //Alterar o estado do waiter para TAKE_TO_TABLE(2) pois ele vai levar a comida à mesa
    
    saveState(nFic, &(sh->fSt)); //Printa linha no prompt com os estados atualizados
    
    for (int i = 0; i < sh->fSt.tableClients; i++) { //Para cada cliente na mesa
        semUp (semgid, sh->foodArrived); //Acorda o cliente para que ele comece a comer
    }
    
    if (semUp (semgid, sh->mutex) == -1)  {                                                  /* exit critical region */
     perror ("error on the down operation for semaphore access (WT)");
        exit (EXIT_FAILURE);
    }
}

/**
 *  \brief waiter receives payment 
 *
 *  Waiter updates its state and receives payment from last client.
 *  The internal state should be saved.
 *
 */
static void receivePayment ()
{
    if (semDown (semgid, sh->mutex) == -1)  {                                                  /* enter critical region */
        perror ("error on the up operation for semaphore access (WT)");
        exit (EXIT_FAILURE);
    }

    /* insert your code here */
    sh->fSt.st.waiterStat=RECEIVE_PAYMENT; //Alterar o estado do waiter para RECEIVE_PAYMENT(3) pois ele vai receber o pagamento

    saveState (nFic, &sh->fSt); //Printa linha no prompt com os estados atualizados
    
    semUp (semgid, sh->requestReceived); //Acorda o cliente para que ele saia da mesa pois o pagamento foi recebido

    if (semUp (semgid, sh->mutex) == -1)  {                                                  /* exit critical region */
     perror ("error on the down operation for semaphore access (WT)");
        exit (EXIT_FAILURE);
    }

    
}

