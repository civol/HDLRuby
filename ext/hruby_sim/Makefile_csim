SRCS := $(wildcard *.c)
OBJS := $(SRCS:.c=.o)

# CFLAGS ?= -o3 -Wall
CFLAGS ?= -g -Wall
LDFLAGS ?= -pthread

TARGET = hruby_simulator

all : ${TARGET}

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@

clean:
	rm *.o ${TARGET}
