#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include "hruby_sim.h"


/**
 *  The HDLRuby pool used for quickly getting empty values, to be used 
 *  with C code generated by hruby_low2c. 
 **/

static Value* pool_values = NULL;
static unsigned int pool_cap = 0; /* The capacity of the pool. */
static unsigned int pool_pos = 0; /* The position in the pool. */

/** Get a fresh value. */
Value get_value() {
    if (pool_cap == 0) {
        /* First allocation. */
        pool_cap = 16;
        pool_values = (Value*)malloc(pool_cap*sizeof(Value));
        /* Allocate the new values. */
        ValueS* new_values = (ValueS*)calloc(sizeof(ValueS),pool_cap);
        /* Assign them to the pool. */
        unsigned int i;
        for(i=0; i<pool_cap; ++i) {
            pool_values[i] = &(new_values[i]);
        }
    }
    else if (pool_pos == pool_cap) {
        /* Need to increase the pool capacity. */
        pool_cap = pool_cap * 2;
        pool_values = (Value*)realloc(pool_values,pool_cap*sizeof(Value));
        /* Allocate the new values. */
        /* Note: now pool_pos is the old pool_cap and is also the number
         * of new values to allocate. */
        ValueS* new_values = (ValueS*)calloc(sizeof(ValueS),pool_pos);
        /* Assign them to the pool. */
        unsigned int i;
        for(i=0; i<pool_pos; ++i) {
            pool_values[i+pool_pos] = &(new_values[i]);
        }
    }
    /* Readjust the position in the pool and return the value. */
    return pool_values[pool_pos++];
}

/** Frees the last value of the pool. */
void free_value() {
    if (pool_pos > 0) pool_pos--;
}

/** Gets the current state of the value pool. */
unsigned int get_value_pos() {
    return pool_pos;
}

/** Restores the state of the value pool.
 *  @param pos the new position in the pool */
void set_value_pos(unsigned int pos) {
    pool_pos = pos;
}
