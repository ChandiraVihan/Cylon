# --- Settings ---
CC     = gcc
LEX    = win_flex
YACC   = win_bison
TARGET = cylon

SRC_DIR  = src
TEST_DIR = tests

# --- Build Rules ---
all: $(TARGET)

$(TARGET): $(SRC_DIR)/lex.yy.c $(SRC_DIR)/parser.tab.c
	$(CC) $(SRC_DIR)/lex.yy.c $(SRC_DIR)/parser.tab.c $(SRC_DIR)/frontend.c $(SRC_DIR)/executor.c -o $(SRC_DIR)/$(TARGET)

$(SRC_DIR)/parser.tab.c $(SRC_DIR)/parser.tab.h: $(SRC_DIR)/parser.y
	$(YACC) -d $(SRC_DIR)/parser.y -o $(SRC_DIR)/parser.tab.c

$(SRC_DIR)/lex.yy.c: $(SRC_DIR)/lexer.l $(SRC_DIR)/parser.tab.h
	$(LEX) -o $(SRC_DIR)/lex.yy.c $(SRC_DIR)/lexer.l

# --- Utility Rules ---
clean:
	rm -f $(SRC_DIR)/$(TARGET).exe
	rm -f $(SRC_DIR)/*.tab.c $(SRC_DIR)/*.tab.h $(SRC_DIR)/lex.yy.c
	@echo "Project cleaned."

test: all
	@echo "Running all tests..."
	bash run_tests.sh