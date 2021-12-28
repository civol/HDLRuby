#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include "hruby_sim.h"

#ifndef alloca
#define alloca(x)  __builtin_alloca(x)
#endif


/**
 *  The HDLRuby simulation stack calculation engine, to be used with C code
 *  generated by hruby_low2c. 
 **/


/** Unary calculation.
 *  @param src0 the left value
 *  @param oper the operator function
 *  @return the destination
 **/
Value unary(Value src0, Value (*oper)(Value,Value)) {
    Value dst = get_value();
    unsigned int pool_state = get_value_pos();
    dst = oper(src0,dst);
    set_value_pos(pool_state);
    return dst;
}

/** Binary calculation.
 *  @param src0 the left value
 *  @param src1 the right value
 *  @param oper the operator function
 *  @return the destination
 **/
Value binary(Value src0, Value src1, Value (*oper)(Value,Value,Value)) {
    Value dst = get_value();
    unsigned int pool_state = get_value_pos();
    dst = oper(src0,src1,dst);
    set_value_pos(pool_state);
    return dst;
}

/** Cast calculation.
 *  @param src0 the value to cast.
 *  @param typ the type to cast to.
 *  @return the destination.
 **/
Value cast(Value src0, Type typ) {
    Value dst = get_value();
    unsigned int pool_state = get_value_pos();
    dst = cast_value(src0,typ,dst);
    set_value_pos(pool_state);
    return dst;
}

/* Concat values.
 * @param num the number of values to concat.
 * @param dir the direction.
 * @param vals the values to concat. */
Value sconcat(int num, int dir, ...) {
    Value dst = get_value();
    unsigned int pool_state = get_value_pos();
    va_list args;
    va_start(args,dir);
    dst = concat_valueV(num,dir,dst,args);
    va_end(args);
    set_value_pos(pool_state);
    return dst;
}

/* Read access calculation.
 * @param src0  the value to access in.
 * @param first the start index.
 * @param last  the end index.
 * @param typ   the data type of the access. */
Value sread(Value src0, unsigned long long first,
                         unsigned long long last, Type typ) {
    Value dst = get_value();
    unsigned int pool_state = get_value_pos();
    dst = read_range(src0,first,last,typ,dst);
    set_value_pos(pool_state);
    return dst;
}

/* Write access calculation.
 * @param src0  the value to access in.
 * @param first the start index.
 * @param last  the end index.
 * @param typ   the data type of the access. */
Value swrite(Value src0, unsigned long long first,
                         unsigned long long last, Type typ) {
    Value dst = get_value();
    unsigned int pool_state = get_value_pos();
    dst = write_range(src0,first,last,typ,dst);
    set_value_pos(pool_state);
    return dst;
}
