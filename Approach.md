# Cylon — Approach

## 1. DSL Scope
- Task types: scripts, backups, emails, cleanup
- Scheduling: `EVERY DAY AT`, `EVERY WEEK ON`, `AFTER another task`
- Constraints: no duplicate tasks, no circular dependencies, valid time format

## 2. Grammar Design
- Tokens list
- EBNF → then convert to BNF for Yacc
- One sentence = one parse tree 

## 3. Implementation
- Lexer → Parser → Constraints handling

## 4. Testing
- Test cases for every input type
- Valid and invalid outputs
- Shell script for automation



