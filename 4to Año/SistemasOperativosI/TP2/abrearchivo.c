#include <stdio.h>
#include <unistd.h>
#include <syscall.h>
#include <stdlib.h>

int main() {
    printf("PID: %d\n", getpid());
    getchar();
    FILE *archivo;
    char linea[256];  // Buffer para leer cada línea

    // Abrir el archivo en modo lectura
    archivo = fopen("archivo.txt", "r");

    // Verificar si se pudo abrir el archivo
    if (archivo == NULL) {
        perror("No se pudo abrir el archivo");
        return 1;
    }

    printf("Contenido del archivo:\n");

    // Leer y mostrar línea por línea
    while (fgets(linea, sizeof(linea), archivo)) {
        printf("%s", linea);
    }

    // Cerrar el archivo
    fclose(archivo);

    return 0;
}
