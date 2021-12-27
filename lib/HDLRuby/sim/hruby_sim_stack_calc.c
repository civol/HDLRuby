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

