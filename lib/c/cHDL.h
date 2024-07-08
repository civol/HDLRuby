/**
 *  Interface for C program with HDLRuby hardware.
 **/

/** The wrapper for getting an interface port for C software. */
extern void* c_get_port(const char* name);

/** The wrapper for getting a value from a port. */
extern unsigned long long c_read_port(void* port);

/** The wrapper for setting a value to a port. */
extern unsigned long long c_write_port(void* port, unsigned long long val);
