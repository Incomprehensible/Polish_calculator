CFLAGS = -f elf32
LFLAGS= -m elf_i386

NAME = calcurik

SRC = polishcalculator.asm

all: $(NAME)

$(NAME): $(NAME).o
	ld $(LFLAGS) $(NAME).o -o $(NAME)

$(NAME).o: $(SRC)
	nasm $(CFLAGS) $(SRC) -o $(NAME).o

clean:
	rm -f $(NAME).o $(NAME)

.INTERMEDIATE: $(NAME).o
