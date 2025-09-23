#include <stdio.h>
#include <unistd.h>
#include <syscall.h>
#include <time.h>

void main() {
    char buf[256];
    time_t t;

    // Forma 1: Usando wrappers estándar
    printf("PID: %d\n", getpid());
    getchar();
    printf("=== Usando wrappers estándar ===\n");
    char *cwd = getcwd(buf, sizeof(buf));
    printf("Directorio actual (getcwd): %s\n", cwd);

    getchar();

    chdir(".."); // Cambia al directorio padre
    printf("Después de chdir(\"..\"): %s\n", getcwd(NULL, 0));
    
    getchar();

    time(&t);
    printf("Tiempo actual (time): %ld\n", t);

    // Forma 2: Usando syscall()
    printf("\n=== Usando syscall() ===\n");
    syscall(SYS_getcwd, buf, sizeof(buf));
    printf("Directorio actual (syscall): %s\n", buf);
    
    getchar();

    syscall(SYS_chdir, "..");
    syscall(SYS_getcwd, buf, sizeof(buf));
    printf("Después de syscall(SYS_chdir): %s\n", buf);

    getchar();

    t = syscall(SYS_time, NULL);
    printf("Tiempo actual (syscall): %ld\n", t);

    // Pausa para analizar con ps/strace
    printf("\nEjecute 'ps aux | grep %d' y 'strace -p %d' en otra terminal.\n", getpid(), getpid());
    getchar();

}
