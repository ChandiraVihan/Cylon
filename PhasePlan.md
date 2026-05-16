# Cylon — Runtime Phase Plan
> Transforming Cylon from a DSL validator into a real working automation language with a Windows daemon.

---

## Vision

A lightweight task automation daemon for Windows where users define workflows in `.cylon` files and the system executes them automatically in the background — no manual intervention required after setup.

```
User writes .cylon file → Cylon daemon picks it up → Tasks run on schedule → Notifications fire
```

---

## Phase 1 — Grammar Extension
> Extend the language to support real scheduling granularity

### New Tokens
- `MINUTE` / `MINUTES`
- `HOUR` / `HOURS`
- `SECOND` / `SECONDS`
- `EVERY` N `MINUTES` / `EVERY` N `HOURS`
- `NOTIFY` command
- `ON_FAILURE` condition (alongside existing `IF SUCCESS` / `IF FAILED`)

### New Grammar Rules
```
ScheduleTime = "EVERY" "DAY" "AT" TIME
             | "EVERY" "WEEK" "ON" DayOfWeek "AT" TIME
             | "EVERY" "MINUTE"
             | "EVERY" NUMBER "MINUTES"
             | "EVERY" "HOUR"
             | "EVERY" NUMBER "HOURS"

NotifyCmd    = "NOTIFY" String

Command      = RunCmd | MoveCmd | GenerateCmd
             | ExportCmd | SendCmd | NotifyCmd
```

### New `.cylon` syntax examples
```
TASK healthCheck {
    RUN "check_system.sh"
    EVERY 5 MINUTES
}

TASK alertUser {
    NOTIFY "System Critical: CPU at 99%"
    AFTER healthCheck
    IF success
}
```

### Deliverables
- [ ] Updated `lexer.l` with new tokens
- [ ] Updated `parser.y` with new grammar rules
- [ ] Updated `cylon.ebnf` and `cylon.bnf`
- [ ] New test cases for new schedule types
- [ ] All existing 17 tests still passing

---

## Phase 2 — Task Executor

### What needs to happen
- Replace `printf("Executing Task...")` with real execution
- Execute RUN scripts using `system()` or `CreateProcess()` on Windows
- Capture exit codes — 0 means success, non-zero means failure
- Use exit codes to evaluate `IF success` and `IF failed` for real
- Execute tasks in dependency order using topological sort

### NOTIFY implementation
```c
void notify(char* message) {
    char cmd[512];
    sprintf(cmd,
        "powershell -Command \""
        "Add-Type -AssemblyName System.Windows.Forms; "
        "[System.Windows.Forms.MessageBox]::Show('%s', 'Cylon Alert')"
        "\"", message);
    system(cmd);
}
```

### Shell scripts to write
- `check_cpu.sh` — reads CPU usage, exits 0 if >= threshold, exits 1 if normal
- `check_ram.sh` — reads RAM usage, exits 0 if >= threshold, exits 1 if normal
- `check_disk.sh` — reads disk usage for C:, exits 0 if >= threshold, exits 1 if normal

### Deliverables
- [ ] `executor.c` — task execution engine
- [ ] `check_cpu.sh`
- [ ] `check_ram.sh`
- [ ] `check_disk.sh`
- [ ] Topological sort for correct execution order
- [ ] Exit code handling for IF conditions

---

## Phase 3 — Scheduler Engine
> Internal clock that fires tasks at the right time

### Core loop
```c
while(1) {
    time_t now = time(NULL);
    for (int i = 0; i < task_count; i++) {
        if (tasks[i].next_run <= now) {
            execute_task(&tasks[i]);
            tasks[i].next_run = calculate_next_run(&tasks[i]);
        }
    }
    sleep(60); // tick every minute
}
```

### Schedule to seconds translation
| Cylon Syntax | Interval |
|---|---|
| `EVERY MINUTE` | 60 seconds |
| `EVERY 5 MINUTES` | 300 seconds |
| `EVERY HOUR` | 3600 seconds |
| `EVERY DAY AT 06:00` | next occurrence of 06:00 |
| `EVERY WEEK ON SUNDAY AT 03:00` | next Sunday at 03:00 |

### File watcher
- Watch the `.cylon` files directory for changes
- When a file is saved, re-parse and reload the schedule
- No daemon restart needed

### Deliverables
- [ ] `scheduler.c` — scheduler engine
- [ ] Schedule translation functions
- [ ] File watcher using `ReadDirectoryChangesW` (Windows API)
- [ ] Reload on file change without losing running state

---

## Phase 4 — Windows Daemon
> Run Cylon silently in the background from Windows startup

### Option A — Windows Service (recommended)
- Register as a proper Windows Service via `sc create`
- Shows up in `services.msc`
- Starts automatically on boot
- Can be started/stopped/restarted without rebooting

```bash
# Install
sc create CylonDaemon binPath= "C:\Cylon\cylon-daemon.exe" start= auto

# Start
sc start CylonDaemon

# Stop
sc stop CylonDaemon

# Uninstall
sc delete CylonDaemon
```

### Option B — Windows Task Scheduler 
- Register `cylon-daemon.exe` to run at user login
- Uses existing Windows infrastructure
- No service code needed

### Daemon config file
```
# cylon.conf
watch_dir = C:\Users\User\CylonTasks
log_file  = C:\Cylon\logs\cylon.log
log_level = INFO
tick_interval = 60
```

### Deliverables
- [ ] `daemon.c` — Windows service entry point
- [ ] `cylon.conf` — configuration file
- [ ] `install.bat` — one-click install script
- [ ] `uninstall.bat` — clean removal script
- [ ] Logging to file with timestamps

---

## Phase 5 — Cylon CLI
> Control the daemon from the command line

### Commands
```bash
cylon install          # register as Windows service
cylon uninstall        # remove service
cylon start            # start the daemon
cylon stop             # stop the daemon
cylon status           # show running tasks and next scheduled runs
cylon reload           # reload .cylon files without restarting
cylon run task.cylon   # one-shot file execution (existing behaviour)
cylon validate task.cylon  # validate syntax only, no execution
cylon list             # list all loaded tasks and their schedules
cylon logs             # tail the daemon log
```

### Deliverables
- [ ] `cli.c` — command dispatcher
- [ ] Status output showing next run times
- [ ] Log tailing command

---

## Phase 6 — Documentation & Packaging
> Make it installable and usable by others

### MkDocs updates
- New pages: Daemon Setup, CLI Reference, Real Workflows, Windows Service Guide
- Deploy to GitHub Pages

### Packaging
- Single `.exe` installer using NSIS or Inno Setup
- Bundles `cylon-daemon.exe`, `cylon.conf`, install scripts
- Adds `cylon` to Windows PATH automatically

### Deliverables
- [ ] Updated MkDocs documentation
- [ ] GitHub Pages deployment
- [ ] Windows installer
- [ ] GitHub release with versioned binaries

---

## Updated Project Structure
```
Cylon/
├── src/
│   ├── lexer.l           # Extended lexer
│   ├── parser.y          # Extended parser
│   ├── frontend.c        # Interactive builder
│   ├── executor.c        # Task execution engine      [NEW]
│   ├── scheduler.c       # Scheduler engine           [NEW]
│   ├── daemon.c          # Windows service entry      [NEW]
│   ├── cli.c             # CLI command dispatcher     [NEW]
│   └── notify.c          # Windows notification       [NEW]
├── scripts/
│   ├── check_cpu.sh      # CPU health check           [NEW]
│   ├── check_ram.sh      # RAM health check           [NEW]
│   └── check_disk.sh     # Disk health check          [NEW]
├── grammar/
│   ├── cylon.ebnf        # Updated EBNF
│   └── cylon.bnf         # Updated BNF
├── tests/
│   ├── valid/            # Extended test cases
│   ├── invalid/          # Extended invalid cases
│   └── expected/         # Expected outputs
├── docs/                 # MkDocs source
├── installer/            # Windows installer files    [NEW]
├── cylon.conf            # Daemon configuration       [NEW]
├── install.bat           # One-click install          [NEW]
├── uninstall.bat         # Clean removal              [NEW]
├── Makefile              # Updated build
├── run_tests.sh          # Test automation
└── README.md             # Updated overview
```

---

## Implementation Order
1. **Phase 1** — Grammar extension (you already know how to do this)
2. **Phase 2** — Write the shell scripts and test them standalone first
3. **Phase 2** — Build executor.c and test it runs scripts correctly
4. **Phase 3** — Build scheduler.c with the while loop
5. **Phase 3** — Add file watcher
6. **Phase 4** — Wrap in Windows service
7. **Phase 5** — Add CLI commands
8. **Phase 6** — Package and document

---

## First Task Right Now
Start with Phase 2 — write `check_cpu.sh`, `check_ram.sh`, `check_disk.sh`.
These are pure bash with no Cylon changes needed and will prove the health check
logic works before you touch the runtime.

---

*Last updated: May 2026*