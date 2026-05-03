---
id: cylon
title: TaskLang++ DSL
sidebar_label: cylon
---

# Cylon DSL

## Introduction

TaskLang++ is a domain-specific language for defining automated workflows with:

- Task execution
- Scheduling
- Dependencies
- Conditional logic

---

## Quick Start

### Example

```
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

```
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
```

## Commands

 - RUN: RUN "script.sh"

 - MOVE: MOVE "source" TO "destination"

 - SEND: SEND "message" TO "user"

 - GENERATE: GENERATE "file.pdf"

 - EXPORT: EXPORT "data.csv"


## Scheduling

 - Daily: EVERY DAY AT 02:00

 - Weekly: EVERY WEEK ON SUNDAY AT 03:00


## Dependencies & Conditions

 - Dependencies: AFTER taskName or BEFORE taskName

 - Conditions: IF SUCCESS or IF FAILED


## Lexical Rules

 - Identifier: [a-zA-Z][a-zA-Z0-9]*

 - String: "any text"

 - Time: HH:MM


## Execution Model

 1. Parse all tasks

 2. Store task definitions

 3. Validate:

   - Duplicate task names

   - Undefined dependencies

   - Circular dependencies

 4. Execute tasks


## Errors

 - Duplicate Task: Duplicate task name

 - Undefined Dependency: Task depends on undefined task

 -Circular Dependency: Circular dependency detected


## Limitations
 - No parallel execution

 - No retries

 - Basic condition support only