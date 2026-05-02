---
id: cylon
title: TaskLang++ DSL
sidebar_label: TaskLang++
---

# TaskLang++ DSL

## Introduction

TaskLang++ is a domain-specific language for defining automated workflows with:

- Task execution
- Scheduling
- Dependencies
- Conditional logic

---

## Quick Start

### Example

```text
TASK backupDB {
    RUN "backup.sh"
    EVERY DAY AT 02:00
}

TASK sendReport {
    RUN "report.py"
    AFTER backupDB
    IF SUCCESS
}

TASK cleanup {
    RUN "cleanup.sh"
    EVERY WEEK ON SUNDAY AT 03:00
}
```

## Behavior

- backupDB runs daily at 02:00

- sendReport runs after backupDB if it succeeds

- cleanup runs weekly on Sunday


## Syntax (EBNF)

<TASK> ::= "TASK" <Identifier> "{" <Command> <TaskBodyOpt> "}"

<Command> ::= <RunCmd> | <MoveCmd> | <SendCmd> | <GenerateCmd> | <ExportCmd>

<RunCmd> ::= "RUN" <String>
<MoveCmd> ::= "MOVE" <String> "TO" <String>
<SendCmd> ::= "SEND" <String> "TO" <String>
<GenerateCmd> ::= "GENERATE" <String>
<ExportCmd> ::= "EXPORT" <String>

<Dependency> ::= "AFTER" <Identifier> | "BEFORE" <Identifier>
<Condition> ::= "IF" ("SUCCESS" | "FAILED")

<ScheduleStmt> ::= ("EVERY DAY" | "EVERY WEEK ON" <Day>) "AT" <TIME>

