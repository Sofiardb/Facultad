// Incluir las librerías necesarias
#include <stdio.h>      // Librería estándar de entrada y salida
#include <stdlib.h>     // Librería estándar para funciones generales
#include <pthread.h>    // Librería para trabajar con hilos
#include <unistd.h>     // Librería para funciones POSIX (como sleep)
#include <sys/types.h>  // Librería para tipos de datos como pid_t
#include <time.h>       // Librería para obtener tiempo y generar aleatorios

// Función que ejecutarán los hilos
void* hilo_funcion(void* arg) {
    // Obtener el ID del hilo actual
    pthread_t id_hilo = pthread_self();
    
    // Mostrar el ID del hilo
    printf("Hilo iniciado. ID del hilo: %lu\n", id_hilo);

    // Generar tiempo aleatorio entre 60 (1 min) y 120 segundos (2 min)
    int tiempo = (rand() % 61) + 60; // 60 a 120 segundos

    // Mostrar cuánto tiempo estará activo el hilo
    printf("Hilo %lu activo durante %d segundos.\n", id_hilo, tiempo);

    // Dormir (pausar) el hilo por el tiempo generado
    sleep(tiempo);

    // Mensaje al terminar la actividad
    printf("Hilo %lu terminado después de %d segundos.\n", id_hilo, tiempo);

    // Finalizar el hilo
    pthread_exit(NULL);
}

int main() {
    // Semilla para generar números aleatorios basada en el tiempo actual
    srand(time(NULL));

    // Variable para guardar el ID del proceso
    pid_t id_proceso = getpid();

    // Mostrar el ID del proceso
    printf("ID del proceso principal: %d\n", id_proceso);

    // Arreglo para guardar los IDs de los hilos
    pthread_t hilos[5];

    // Crear 5 hilos
    for (int i = 0; i < 5; i++) {
        // Crear cada hilo ejecutando la función 'hilo_funcion'
        if (pthread_create(&hilos[i], NULL, hilo_funcion, NULL) != 0) {
            // Mostrar error si no se pudo crear un hilo
            perror("Error al crear el hilo");
            exit(EXIT_FAILURE);
        }
    }

    // Esperar (join) que todos los hilos terminen antes de salir del programa
    for (int i = 0; i < 5; i++) {
        // Unir cada hilo al hilo principal
        pthread_join(hilos[i], NULL);
    }

    // Mensaje final cuando todos los hilos han terminado
    printf("Todos los hilos han terminado. Finalizando el programa.\n");

    return 0; // Terminar el programa correctamente
    //Fuente: chatgpt
}
