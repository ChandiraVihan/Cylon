#include <stdio.h>
#include <stdlib.h>
#include <string.h>
 
#define MAX_TASKS   50
#define BUF         256
#define DSL_SIZE    8192
 

static void strip_newline(char *s) {
    s[strcspn(s, "\n")] = '\0';
}
 
static void prompt(const char *msg, char *out, int size) {
    printf("  %s", msg);
    fgets(out, size, stdin);
    strip_newline(out);
}
 
static void print_banner(void) {
    printf("\n");
    printf(" ██████╗██╗   ██╗██╗      ██████╗ ███╗   ██╗\n");
    printf("██╔════╝╚██╗ ██╔╝██║     ██╔═══██╗████╗  ██║\n");
    printf("██║      ╚████╔╝ ██║     ██║   ██║██╔██╗ ██║\n");
    printf("██║       ╚██╔╝  ██║     ██║   ██║██║╚██╗██║\n");
    printf("╚██████╗   ██║   ███████╗╚██████╔╝██║ ╚████║\n");
    printf(" ╚═════╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝\n\n");
}