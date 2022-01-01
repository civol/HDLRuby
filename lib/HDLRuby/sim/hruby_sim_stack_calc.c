#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include "hruby_sim.h"


/**
 *  The HDLRuby simulation stack calculation engine, to be used with C code
 *  generated by hruby_low2c. 
 **/

/* The stack variables. */
#define STACK_SIZE 0x10000
static Value stack[STACK_SIZE];
static int head = STACK_SIZE;

/** Push a value.
 *  @param val the value to push. */
void push(Value val) {
    if (head > 0) {
        stack[--head] = val;
    } else {
        perror("Computation stack full.\n");
        exit(1);
    }
}

/** Pops a value.
 *  @return the value. */
Value pop() {
    if (head < STACK_SIZE) {
        return stack[head++];
    } else {
        perror("Computation stack empty.\n");
        exit(1);
    }
}

/** Pops multiple values.
 *  @param num the number of values to pop.
 *  @return a pointer on the first value (in heap order!). */
static Value* popn(int num) {
    if (head+num < STACK_SIZE) {
        head += num;
        return &stack[head];
    } else {
        perror("Not enough values in computation stack.\n");
        exit(1);
    }
}


/** Unary calculation.
 *  @param oper the operator function
 *  @return the destination
 **/
Value unary(Value (*oper)(Value,Value)) {
    // printf("unary\n");
    Value dst = get_top_value();
    dst = oper(pop(),dst);
    push(dst);
    return dst;
}

/** Binary calculation.
 *  @param oper the operator function
 *  @return the destination
 **/
Value binary(Value (*oper)(Value,Value,Value)) {
    // printf("binary\n");
    Value dst = get_top_value();
    Value r = pop();
    Value l = pop();
    dst = oper(l,r,dst);
    push(dst);
    return dst;
}

/** Cast calculation.
 *  @param typ the type to cast to.
 *  @return the destination.
 **/
Value cast(Type typ) {
    // printf("cast\n"); 
    Value dst = get_top_value();
    Value src = pop();
    dst = cast_value(src,typ,dst);
    push(dst);
    return dst;
}

/* Concat values.
 * @param num the number of values to concat.
 * @param dir the direction. */
Value sconcat(int num, int dir) {
    // printf("sconcat\n");
    Value dst = get_top_value();
    dst = concat_valueP(num,dir,dst,popn(num));
    return dst;
}

/* Index read calculation.
 * @param typ the data type of the access. */
Value sreadI(Type typ) {
    // printf("sreadI\n");
    Value dst = get_top_value();
    unsigned long long idx = value2integer(pop());
    dst = read_range(pop(),idx,idx,typ,dst);
    return dst;
}

/* Index write calculation.
 * @param typ the data type of the access. */
Value swriteI(Type typ) {
    // printf("swriteI\n");
    Value dst = get_top_value();
    unsigned long long idx = value2integer(pop());
    dst = write_range(pop(),idx,idx,typ,dst);
    return dst;
}

/* Range read calculation.
 * @param typ the data type of the access. */
Value sreadR(Type typ) {
    // printf("sreadR\n");
    Value dst = get_top_value();
    unsigned long long last = value2integer(pop());
    unsigned long long first = value2integer(pop());
    dst = read_range(pop(),first,last,typ,dst);
    return dst;
}

/* Range write calculation.
 * @param typ the data type of the access. */
Value swriteR(Type typ) {
    // printf("swriteR\n");
    Value dst = get_top_value();
    unsigned long long last = value2integer(pop());
    unsigned long long first = value2integer(pop());
    dst = write_range(pop(),first,last,typ,dst);
    return dst;
}

/* Transmit a value to a signal in parallel. 
 * @param sig the signal to transmit to. */
void transmit(SignalI sig) {
    // printf("transmit\n");
    transmit_to_signal(pop(),sig);
}

/* Transmit a value to a signal in sequence.
 * @param sig the signal to transmit to. */
void transmit_seq(SignalI sig) {
    // printf("transmit_seq\n");
    transmit_to_signal_seq(pop(),sig);
}

/* Transmit a value to a range in a signal in parallel. 
 * @param ref the ref to the range of the signal to transmit to. */
void transmitR(RefRangeS ref) {
    // printf("transmitR\n");
    transmit_to_signal_range(pop(),ref);
}

/* Transmit a value to a range in a signal in sequence. 
 * @param ref the ref to the range of the signal to transmit to. */
void transmitR_seq(RefRangeS ref) {
    // printf("transmitR_seq\n");
    transmit_to_signal_range_seq(pop(),ref);
}

