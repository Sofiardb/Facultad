#include <stdio.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
int main()
{
    // Creo un proceso con fork
    pid_t p = fork();
    getchar();
    // Si p es menor que cero, no se pudo crear el proceso
    if(p<0){
      perror("fork fail");
      exit(1);
    }else if(p == 0) // Si es igual a 0 entonces es el proceso hijo
    {
      printf("Soy el proceso hijo. Mi pid es: %d \n", getpid());
      getchar();
    }else{ // Si es mayor a 0 entonces es el proceso padre
      printf("Soy el proceso padre. Mi pid es: %d \n", getpid());
      getchar();
    }
    getchar();
    return 0;

    // Fuente https://www.geeksforgeeks.org/fork-system-call/
}