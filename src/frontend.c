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

void print_banner(void) {
    printf("\n");
    printf(" ██████╗██╗   ██╗██╗      ██████╗ ███╗   ██╗\n");
    printf("██╔════╝╚██╗ ██╔╝██║     ██╔═══██╗████╗  ██║\n");
    printf("██║      ╚████╔╝ ██║     ██║   ██║██╔██╗ ██║\n");
    printf("██║       ╚██╔╝  ██║     ██║   ██║██║╚██╗██║\n");
    printf("╚██████╗   ██║   ███████╗╚██████╔╝██║ ╚████║\n");
    printf(" ╚═════╝   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝\n\n");
}

static void collect_task(char *dsl, int *pos) {
    char name[BUF], cmd_type[BUF], arg1[BUF], arg2[BUF];
    char sched_choice[BUF], day[BUF], time_val[BUF];
    char dep_task[BUF], cond_choice[BUF];
    char task_block[1024];
    char cmd_line[BUF * 2];
    char sched_line[BUF * 2];
    char dep_line[BUF * 2];
    char cond_line[BUF * 2];

    cmd_line[0]   = '\0';
    sched_line[0] = '\0';
    dep_line[0]   = '\0';
    cond_line[0]  = '\0';

    prompt("Task name            : ", name, BUF);

    printf("\n  Command types: RUN | MOVE | SEND | GENERATE | EXPORT\n");
    prompt("Command type         : ", cmd_type, BUF);

    if (strcmp(cmd_type, "RUN") == 0 || strcmp(cmd_type, "run") == 0) {
        prompt("Script (e.g. backup.sh): ", arg1, BUF);
        sprintf(cmd_line, "    RUN \"%s\"", arg1);

    } else if (strcmp(cmd_type, "MOVE") == 0 || strcmp(cmd_type, "move") == 0) {
        prompt("Source file/folder   : ", arg1, BUF);
        prompt("Destination          : ", arg2, BUF);
        sprintf(cmd_line, "    MOVE \"%s\" TO \"%s\"", arg1, arg2);

    } else if (strcmp(cmd_type, "SEND") == 0 || strcmp(cmd_type, "send") == 0) {
        prompt("Message/file to send : ", arg1, BUF);
        prompt("Recipient            : ", arg2, BUF);
        sprintf(cmd_line, "    SEND \"%s\" TO \"%s\"", arg1, arg2);

    } else if (strcmp(cmd_type, "GENERATE") == 0 || strcmp(cmd_type, "generate") == 0) {
        prompt("Output file          : ", arg1, BUF);
        sprintf(cmd_line, "    GENERATE \"%s\"", arg1);

    } else if (strcmp(cmd_type, "EXPORT") == 0 || strcmp(cmd_type, "export") == 0) {
        prompt("Export target        : ", arg1, BUF);
        sprintf(cmd_line, "    EXPORT \"%s\"", arg1);

    } else {
        printf("  Unknown command type - defaulting to RUN\n");
        prompt("Script               : ", arg1, BUF);
        sprintf(cmd_line, "    RUN \"%s\"", arg1);
    }

    printf("\n  Schedule options: EVERY DAY | EVERY WEEK | AFTER | BEFORE | none\n");
    prompt("Schedule type        : ", sched_choice, BUF);

    if (strcmp(sched_choice, "EVERY DAY") == 0 || strcmp(sched_choice, "every day") == 0) {
        prompt("Time (HH:MM)         : ", time_val, BUF);
        sprintf(sched_line, "    EVERY DAY AT %s", time_val);

    } else if (strcmp(sched_choice, "EVERY WEEK") == 0 || strcmp(sched_choice, "every week") == 0) {
        printf("  Days: SUNDAY MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY SATURDAY\n");
        prompt("Day                  : ", day, BUF);
        prompt("Time (HH:MM)         : ", time_val, BUF);
        sprintf(sched_line, "    EVERY WEEK ON %s AT %s", day, time_val);

    } else if (strcmp(sched_choice, "AFTER") == 0 || strcmp(sched_choice, "after") == 0) {
        prompt("Depends on task      : ", dep_task, BUF);
        sprintf(dep_line, "    AFTER %s", dep_task);

    } else if (strcmp(sched_choice, "BEFORE") == 0 || strcmp(sched_choice, "before") == 0) {
        prompt("Must run before task : ", dep_task, BUF);
        sprintf(dep_line, "    BEFORE %s", dep_task);
    }

    printf("\n  Condition options: SUCCESS | FAILED | none\n");
    prompt("Condition            : ", cond_choice, BUF);

    if (strcmp(cond_choice, "SUCCESS") == 0 || strcmp(cond_choice, "success") == 0) {
        sprintf(cond_line, "    IF success");
    } else if (strcmp(cond_choice, "FAILED") == 0 || strcmp(cond_choice, "failed") == 0) {
        sprintf(cond_line, "    IF failed");
    }

    strcpy(task_block, "");
    sprintf(task_block, "TASK %s {\n%s\n", name, cmd_line);

    if (sched_line[0] != '\0') { strcat(task_block, sched_line); strcat(task_block, "\n"); }
    if (dep_line[0]   != '\0') { strcat(task_block, dep_line);   strcat(task_block, "\n"); }
    if (cond_line[0]  != '\0') { strcat(task_block, cond_line);  strcat(task_block, "\n"); }

    strcat(task_block, "}\n\n");
    *pos += sprintf(dsl + *pos, "%s", task_block);
}

void run_interactive(void) {
    char dsl[DSL_SIZE];
    char more[BUF];
    int  pos = 0;
    int  task_num = 1;

    print_banner();
    printf("╔══════════════════════════════════════╗\n");
    printf("║     Cylon Interactive Task Builder   ║\n");
    printf("╚══════════════════════════════════════╝\n\n");

    dsl[0] = '\0';

    do {
        printf("┌─ Task %d ───────────────────────────\n", task_num++);
        collect_task(dsl, &pos);
        printf("└─────────────────────────────────────\n");
        prompt("\nAdd another task? (yes/no): ", more, BUF);
        printf("\n");
    } while (strcmp(more, "yes") == 0 || strcmp(more, "y") == 0);

    printf("╔══════════════════════════════════════╗\n");
    printf("║       Generated Cylon DSL Code       ║\n");
    printf("╚══════════════════════════════════════╝\n\n");
    printf("%s\n", dsl);

    const char *tmp = "temp_input.cylon";
    FILE *f = fopen(tmp, "w");
    if (f == NULL) {
        fprintf(stderr, "ERROR: Could not create temp file.\n");
        exit(1);
    }
    fprintf(f, "%s", dsl);
    fclose(f);

    printf("╔══════════════════════════════════════╗\n");
    printf("║            Parser Output             ║\n");
    printf("╚══════════════════════════════════════╝\n\n");

    
    char cmd[BUF];
    sprintf(cmd, "cylon.exe %s", tmp);
    system(cmd);

    remove(tmp);
}