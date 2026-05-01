# --- Settings ---
CC = gcc
LEX = flex
YACC = bison
# Output executable name
TARGET = cylon

# Directories
SRC_DIR = src
TEST_DIR = tests

# --- Build Rules ---

# Default target: builds the compiler
all: $(TARGET)

$(TARGET): $(SRC_DIR)/lex.yy.c $(SRC_DIR)/cylon.tab.c
	$(CC) $(SRC_DIR)/cylon.tab.c $(SRC_DIR)/lex.yy.c -o $(TARGET)

# Generate Parser files (Bison)
$(SRC_DIR)/cylon.tab.c $(SRC_DIR)/cylon.tab.h: $(SRC_DIR)/cylon.y
	$(YACC) -d $(SRC_DIR)/cylon.y -o $(SRC_DIR)/cylon.tab.c

# Generate Lexer file (Flex)
$(SRC_DIR)/lex.yy.c: $(SRC_DIR)/cylon.l $(SRC_DIR)/cylon.tab.h
	$(LEX) -o $(SRC_DIR)/lex.yy.c $(SRC_DIR)/cylon.l

# --- Utility Rules ---

# Clean up all generated files
clean:
	rm -f $(TARGET)
	rm -f $(SRC_DIR)/*.tab.c $(SRC_DIR)/*.tab.h $(SRC_DIR)/lex.yy.c
	@echo "Project cleaned."

# Shortcut to run your test workflow
test: all
	@echo "Running valid test case..."
	./$(TARGET) < $(TEST_DIR)/valid/test_workflow.cylon

# Shortcut to run an error test case
test-error: all
	@echo "Running duplicate task test case..."
	./$(TARGET) < $(TEST_DIR)/invalid/error_duplicate_task.cylon