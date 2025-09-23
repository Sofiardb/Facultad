#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <syscall.h>
#include <string.h>


int main() {
    printf("PID: %d\n", getpid());
    getchar();
    FILE *file;
    char line[256];
    int lineNumber = 1;
    long positions[100]; // Array para guardar posiciones de líneas impares
    int index = 0;

    file = fopen("archivo2.txt", "r");
    if (file == NULL) {
        perror("Error al abrir el archivo");
        return 1;
    }

    // Primera pasada: Guardar posiciones de líneas impares
    while (fgets(line, sizeof(line), file)) {
        if (lineNumber % 2 == 1) {
            positions[index++] = ftell(file) - strlen(line);
        }
        lineNumber++;
    }

    // Segunda pasada: Leer líneas impares desde las posiciones guardadas
    printf("=== Lineas impares ===\n");
    for (int i = 0; i < index; i++) {
        fseek(file, positions[i], SEEK_SET);
        fgets(line, sizeof(line), file);
        printf("Linea %d: %s", (i * 2) + 1, line);
    }

    fclose(file);
    return 0;
}
