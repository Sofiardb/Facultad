#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <syscall.h>
#include <fcntl.h>

void main() {
    printf("PID: %d\n", getpid());
    getchar();
    int fd = open("archivo2.txt", O_RDONLY);
    if (fd == -1) {
        perror("Error al abrir el archivo");
        exit(1);
    }

    char buffer[6]; // 5 caracteres + '\0'
    ssize_t bytes_leidos;

    printf("Leyendo 5 caracteres, saltando 10:\n");

    while (1) {
        // Leer 5 caracteres
        bytes_leidos = read(fd, buffer, 5);
        if (bytes_leidos <= 0) break; // Fin del archivo o error
        buffer[bytes_leidos] = '\0';
        printf("%s", buffer);

        // Saltar 10 caracteres
        if (lseek(fd, 10, SEEK_CUR) == -1) {
            perror("Error al saltar");
            break;
        }
    }

    close(fd);
    exit (7);
}
