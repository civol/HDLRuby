#ifdef RCSIM

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#include <ruby.h>
#include "extconf.h"

#include "hruby_sim.h"

/**
 *  The C-Ruby hybrid HDLRuby simulation builder.
 **/


/*#### Creating the VALUE wrapper of C simulation objects. */

// #define rcsim_wrapper(TYPE) \
//     static const rb_data_type_t TYPE ## _ruby = { \
//        #TYPE ,\
//        {0, free_dbm, memsize_dbm,},\
//        0, 0,\
//        RUBY_TYPED_FREE_IMMEDIATELY, }
// 
// #define rcsim_to_value(TYPE, POINTER, VALUE) \
//         (VALUE) = TypedData_Make_Struct(klass, TYPE , &( TYPE ## _ruby ), (POINTER) )
// 
// #define value_to_rcsim(VALUE, TYPE, POINTER) \
//         TypedData_Get_Struct((VALUE), TYPE , &( TYPE ## _ruby ), (POINTER) );
// 
// rcsim_wrapper(Type);
// rcsim_wrapper(SystemT);
// rcsim_wrapper(Scope);
// rcsim_wrapper(Behavior);
// rcsim_wrapper(Event);
// rcsim_wrapper(SignalI);
// rcsim_wrapper(SystemI);
// rcsim_wrapper(Statement);
// rcsim_wrapper(Transmit);
// rcsim_wrapper(Print);
// rcsim_wrapper(TimeWait);
// rcsim_wrapper(TimeTerminate);
// rcsim_wrapper(HIf);
// rcsim_wrapper(HCase);
// rcsim_wrapper(Block);
// rcsim_wrapper(Value);
// rcsim_wrapper(Expression);
// rcsim_wrapper(Cast);
// rcsim_wrapper(Unary);
// rcsim_wrapper(Binary);
// rcsim_wrapper(Select);
// rcsim_wrapper(Concat);
// rcsim_wrapper(Reference);
// rcsim_wrapper(RefConcat);
// rcsim_wrapper(RefIndex);
// rcsim_wrapper(RefRange);

static VALUE RCSimPointer;

#define rcsim_to_value(TYPE,POINTER,VALUE) \
    (VALUE) = Data_Wrap_Struct(RCSimPointer, 0, 0, (POINTER))
    // (VALUE) = Data_Wrap_Struct(RCSimPointer, 0, free, (POINTER))
    // (VALUE) = ULL2NUM((unsigned long long)(POINTER))

#define value_to_rcsim(TYPE,VALUE,POINTER) \
    Data_Get_Struct((VALUE),TYPE,(POINTER))
    // (POINTER) = (TYPE*)NUM2ULL((VALUE))

/*#### Generates the list of ID coressponding to the HDLRuby symbols. ####*/

static ID id_ANYEDGE;
static ID id_POSEDGE;
static ID id_NEGEDGE;
static ID id_PAR;
static ID id_SEQ;
// static ID id_NOT;
// static ID id_NEG;
// static ID id_ADD;
// static ID id_SUB;
// static ID id_MUL;
// static ID id_DIV;
// static ID id_MOD;
// static ID id_POW;
// static ID id_AND;
// static ID id_OR ;
// static ID id_XOR;
// static ID id_SHL;
// static ID id_SHR;
// static ID id_EQ;
// static ID id_NE;
// static ID id_LT;
// static ID id_LE;
// static ID id_GT;
// static ID id_GE;
 
void make_sym_IDs() {
    id_ANYEDGE = rb_intern("anyedge");
    id_POSEDGE = rb_intern("posedge");
    id_NEGEDGE = rb_intern("negedge");
    id_PAR     = rb_intern("par");
    id_SEQ     = rb_intern("seq");
//     id_NOT     = rb_intern("~");
//     id_NEG     = rb_intern("-@");
//     id_ADD     = rb_intern("+");
//     id_SUB     = rb_intern("-");
//     id_MUL     = rb_intern("*");
//     id_DIV     = rb_intern("/");
//     id_MOD     = rb_intern("%");
//     id_POW     = rb_intern("**");
//     id_AND     = rb_intern("&");
//     id_OR      = rb_intern("|");
//     id_XOR     = rb_intern("^");
//     id_SHL     = rb_intern("<<");
//     id_SHR     = rb_intern(">>");
//     id_EQ      = rb_intern("==");
//     id_NE      = rb_intern("!=");
//     id_LT      = rb_intern("<");
//     id_LE      = rb_intern("<=");
//     id_GT      = rb_intern(">");
//     id_GE      = rb_intern(">=");
}

/** Converts a symbol to a char value. 
 *  NOTE: only works for one or two ASCII characters symbols. */
static unsigned char sym_to_char(VALUE sym) {
    const char* sym_ptr = rb_id2name(SYM2ID(sym)); 
    // printf("sym_ptr=%s char=%i\n",sym_ptr,(unsigned char)(sym_ptr[0]+sym_ptr[1]*2));
    return (unsigned char)(sym_ptr[0]+sym_ptr[1]*2);
}


/*#### Getting the C simulation type objects. ####*/

/* Get the bit type. */
VALUE rcsim_get_type_bit(VALUE mod) {
    VALUE res;
    rcsim_to_value(TypeS,get_type_bit(),res);
    return res;
}

/* Get the signed type. */
VALUE rcsim_get_type_signed(VALUE mod) {
    VALUE res;
    rcsim_to_value(TypeS,get_type_signed(),res);
    return res;
}

/* Get a vector type. */
VALUE rcsim_get_type_vector(VALUE mod, VALUE baseV, VALUE numV) {
    /* Get the base type. */
    Type base;
    value_to_rcsim(TypeS,baseV,base);
    /* Get the number of elements. */
    unsigned long long num = NUM2LL(numV);
    /* Get the type. */
    Type type = get_type_vector(base,num);
    /* Return it as a Ruby VALUE. */
    VALUE res;
    rcsim_to_value(TypeS,type,res);
    return res;
}


/*#### Creating the C simulation objects. ####*/

/* Creating a systemT C object. */
VALUE rcsim_make_systemT(VALUE mod, VALUE name) {
    /* Allocates the systemT. */
    SystemT systemT = (SystemT)malloc(sizeof(SystemTS));
    /* Set it up. */
    systemT->kind = SYSTEMT;
    systemT->owner = NULL;
    systemT->name = strdup(StringValueCStr(name));
    systemT->num_inputs = 0;
    systemT->inputs = NULL;
    systemT->num_outputs = 0;
    systemT->outputs = NULL;
    systemT->num_inouts = 0;
    systemT->inouts = NULL;
    systemT->scope = NULL;
    // printf("Created systemT with kind=%d and name=%s\n",systemT->kind,systemT->name);
    /* Returns the C systemT embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(SystemTS,systemT,res);
    return res;
}


/* Creating a scope C object. */
VALUE rcsim_make_scope(VALUE mod, VALUE name) {
    /* Allocates the scope. */
    Scope scope = (Scope)malloc(sizeof(ScopeS));
    /* Set it up. */
    scope->kind = SCOPE;
    scope->owner = NULL;
    scope->name = strdup(StringValueCStr(name));
    scope->num_systemIs = 0;
    scope->systemIs = NULL;
    scope->num_inners = 0;
    scope->inners = NULL;
    scope->num_scopes = 0;
    scope->scopes = NULL;
    scope->num_behaviors = 0;
    scope->behaviors = NULL;
    scope->num_codes = 0;
    scope->codes = NULL;
    /* Returns the C scope embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(ScopeS,scope,res);
    return res;
}


/* Creating a behavior C object. */
VALUE rcsim_make_behavior(VALUE mod, VALUE timed) {
    /* Allocates the behavior. */
    Behavior behavior = (Behavior)malloc(sizeof(BehaviorS));
    // printf("new behavior=%p\n",behavior);
    /* Set it up. */
    behavior->kind = BEHAVIOR;
    behavior->owner = NULL;
    behavior->num_events = 0;
    behavior->events = NULL;
    behavior->enabled = 0;
    behavior->activated = 0;
    if (TYPE(timed) == T_TRUE) {
        /* The behavior is timed, set it up and register it. */
        behavior->timed = 1;
        register_timed_behavior(behavior);
    } else {
        /* The behavior is not timed. */
        behavior->timed = 0;
    }
    behavior->active_time = 0;
    /* Returns the C behavior embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(BehaviorS,behavior,res);
    return res;
}


/* Creating an event C object. */
VALUE rcsim_make_event(VALUE mod, VALUE typeV, VALUE sigV) {
    /* Allocates the event. */
    Event event = (Event)malloc(sizeof(EventS));
    /* Set it up. */
    event->kind = EVENT;
    event->owner = NULL;
    /* Its type. */
    ID id_edge = SYM2ID(typeV);
    if      (id_edge == id_POSEDGE) { event->edge = POSEDGE; }
    else if (id_edge == id_NEGEDGE) { event->edge = NEGEDGE; }
    else if (id_edge == id_ANYEDGE) { event->edge = ANYEDGE; }
    else  { perror("Invalid edge type."); }
    /* Its signal. */
    value_to_rcsim(SignalIS,sigV,event->signal);
    /* Returns the C event embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(EventS,event,res);
    return res;
}


/* Creating a signal C object. */
VALUE rcsim_make_signal(VALUE mod, VALUE name, VALUE type) {
    /* Allocates the signal. */
    SignalI signal = (SignalI)malloc(sizeof(SignalIS));
    /* Set it up. */
    signal->kind = SIGNALI;
    signal->owner = NULL;
    signal->name = strdup(StringValueCStr(name));
    // printf("Creating signal named=%s\n",signal->name);
    value_to_rcsim(TypeS,type,signal->type);
    // printf("type width=%llu\n",type_width(signal->type));
    signal->c_value = make_value(signal->type,0);
    signal->c_value->signal = signal;
    // printf("c_value=%p type=%p\n",signal->c_value,signal->c_value->type);
    // printf("c_value type width=%llu\n",type_width(signal->c_value->type));
    signal->f_value = make_value(signal->type,0);
    signal->f_value->signal = signal;
    signal->fading = 1; /* Initially the signal can be overwritten by anything.*/
    signal->num_any = 0;
    signal->any = NULL;
    signal->num_pos = 0;
    signal->pos = NULL;
    signal->num_neg = 0;
    signal->neg = NULL;
    /* Register the signal. */
    register_signal(signal);
    /* Returns the C signal embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(SignalIS,signal,res);
    return res;
}


/* Creating a system instance C object. */
VALUE rcsim_make_systemI(VALUE mod, VALUE name, VALUE systemT) {
    /* Allocates the system instance. */
    SystemI systemI = (SystemI)malloc(sizeof(SystemIS));
    /* Set it up. */
    systemI->kind = SYSTEMI;
    systemI->owner = NULL;
    systemI->name = strdup(StringValueCStr(name));
    // /* Name is made empty since redundant with Eigen system. */
    // systemI->name = "";
    value_to_rcsim(SystemTS,systemT,systemI->system);
    systemI->num_systems = 1;
    systemI->systems = (SystemT*)malloc(sizeof(SystemT));
    systemI->systems[0] = systemI->system;
    /* Configure the systemI to execute the default systemT. */
    configure(systemI,0);
    /* Returns the C system instance embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(SystemIS,systemI,res);
    return res;
}


/* Creating a transmit C object. */
VALUE rcsim_make_transmit(VALUE mod, VALUE left, VALUE right) {
    /* Allocates the transmit. */
    Transmit transmit = (Transmit)malloc(sizeof(TransmitS));
    /* Set it up. */
    transmit->kind = TRANSMIT;
    value_to_rcsim(ReferenceS,left,transmit->left);
    value_to_rcsim(ExpressionS,right,transmit->right);
    /* Returns the C transmit embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(TransmitS,transmit,res);
    return res;
}


/* Creating a print C object. */
VALUE rcsim_make_print(VALUE mod) {
    /* Allocates the print. */
    Print print = (Print)malloc(sizeof(PrintS));
    /* Set it up. */
    print->kind = PRINT;
    print->num_args = 0;
    /* Returns the C print embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(PrintS,print,res);
    return res;
}


/* Creating a time wait C object. */
VALUE rcsim_make_timeWait(VALUE mod, VALUE unitV, VALUE delayV) {
    /* Allocates the time wait. */
    TimeWait timeWait = (TimeWait)malloc(sizeof(TimeWaitS));
    /* Set it up. */
    timeWait->kind = TIME_WAIT;
    /* Compute the delay. */
    unsigned long long delay;
    delay = NUM2LL(delayV);
    /* Adjust the delay depending on the unit. */
    const char* unit = rb_id2name(SYM2ID(unitV));
    switch(unit[0]) {
        case 'p': /* Ok as is. */         break;
        case 'n': delay *= 1000;          break;
        case 'u': delay *= 1000000;       break;
        case 'm': delay *= 1000000000;    break;
        case 's': delay *= 1000000000000; break;
        default:
                  perror("Invalid delay unit.");
    }
    timeWait->delay = delay;
    /* Returns the C time wait embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(TimeWaitS,timeWait,res);
    return res;
}


/* Creating a time terminate C object. */
VALUE rcsim_make_timeTerminate(VALUE mod) {
    /* Allocates the time terminate. */
    TimeTerminate timeTerminate = (TimeTerminate)malloc(sizeof(TimeTerminateS));
    /* Set it up. */
    timeTerminate->kind = TIME_TERMINATE;
    /* Returns the C time terminate embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(TimeTerminateS,timeTerminate,res);
    return res;
}


/* Creating a hardware if C object. */
VALUE rcsim_make_hif(VALUE mod, VALUE condition, VALUE yes, VALUE no) {
    /* Allocates the hardware if. */
    HIf hif = (HIf)malloc(sizeof(HIfS));
    /* Set it up. */
    hif->kind = HIF;
    value_to_rcsim(ExpressionS,condition,hif->condition);
    value_to_rcsim(StatementS,yes,hif->yes);
    if (TYPE(no) == T_NIL)
        hif->no = NULL;
    else
        value_to_rcsim(StatementS,no,hif->no);
    hif->num_noifs = 0;
    hif->noconds = NULL;
    hif->nostmnts = NULL;
    /* Returns the C hardware if embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(HIfS,hif,res);
    return res;
}


/* Creating a hardware case C object. */
VALUE rcsim_make_hcase(VALUE mod, VALUE value, VALUE defolt) {
    /* Allocates the hardware case. */
    HCase hcase = (HCase)malloc(sizeof(HCaseS));
    /* Set it up. */
    hcase->kind = HCASE;
    value_to_rcsim(ExpressionS,value,hcase->value);
    hcase->num_whens = 0;
    hcase->matches = NULL;
    hcase->stmnts = NULL;
    if (TYPE(defolt) == T_NIL)
        hcase->defolt = NULL;
    else
        value_to_rcsim(StatementS,defolt,hcase->defolt);
    /* Returns the C hardware case embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(HCaseS,hcase,res);
    return res;
}


/* Creating a block C object. */
VALUE rcsim_make_block(VALUE mod, VALUE mode) {
    /* Allocates the block. */
    Block block = (Block)malloc(sizeof(BlockS));
    /* Set it up. */
    block->kind = BLOCK;
    block->owner = NULL;
    block->name = NULL;
    block->num_inners = 0;
    block->inners = NULL;
    block->num_stmnts = 0;
    block->stmnts = NULL;
    block->mode = SYM2ID(mode) == id_PAR ? PAR : SEQ;
    /* Returns the C block embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(BlockS,block,res);
    return res;
}


/* Creating a numeric value C object. */
VALUE rcsim_make_value_numeric(VALUE mod, VALUE typeV, VALUE contentV) {
    // /* Allocates the value. */
    // Value value = get_value();
    // /* Sets its type. */
    // value_to_rcsim(TypeS,typeV,value->type);
    /* Get the type. */
    Type type;
    value_to_rcsim(TypeS,typeV,type);
    /* Create the value. */
    Value value = make_value(type,0);
    /* Set it to numeric. */
    value->numeric = 1;
    value->capacity = 0;
    value->data_str = NULL;
    value->data_int = NUM2LL(contentV);
    /* Returns the C value embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(ValueS,value,res);
    return res;
}


/* Creating a bitstring value C object. */
VALUE rcsim_make_value_bitstring(VALUE mod, VALUE typeV, VALUE contentV) {
    // /* Allocates the value. */
    // Value value = get_value();
    // /* Sets its type. */
    // value_to_rcsim(TypeS,type,value->type);
    /* Get the type. */
    Type type;
    value_to_rcsim(TypeS,typeV,type);
    /* Create the value. */
    Value value = make_value(type,0);
    // printf("Created from bitstring value=%p with type=%p\n",value,value->type);
    // printf("and width=%llu\n",type_width(value->type));
    /* Set it to bitstring. */
    value->numeric = 0;
    /* Generate the string of the content. */
    char* str = StringValueCStr(contentV);
    value->capacity = strlen(str)+1;
    value->data_str = calloc(sizeof(char),value->capacity);
    strcpy(value->data_str,str);
    /* Returns the C value embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(ValueS,value,res);
    return res;
}


/* Creating a cast C object. */
VALUE rcsim_make_cast(VALUE mod, VALUE type, VALUE child) {
    /* Allocates the cast. */
    Cast cast = (Cast)malloc(sizeof(CastS));
    /* Set it up. */
    cast->kind = CAST;
    value_to_rcsim(TypeS,type,cast->type);
    value_to_rcsim(ExpressionS,child,cast->child);
    /* Returns the C cast embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(CastS,cast,res);
    return res;
}

/* Creating a unary value C object. */
VALUE rcsim_make_unary(VALUE mod, VALUE type, VALUE operator, VALUE child) {
    /* Allocates the unary. */
    Unary unary= (Unary)malloc(sizeof(UnaryS));
    /* Set it up. */
    unary->kind = UNARY;
    value_to_rcsim(TypeS,type,unary->type);
    switch(sym_to_char(operator)) {
        case (unsigned char)'~':         unary->oper = not_value; break;
        case (unsigned char)('-'+'@'*2): unary->oper = neg_value; break;
        default: perror("Invalid operator for unary.");
    }
    value_to_rcsim(ExpressionS,child,unary->child);
    /* Returns the C unary embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(UnaryS,unary,res);
    return res;
}

/* Creating a binary value C object. */
VALUE rcsim_make_binary(VALUE mod, VALUE type, VALUE operator, VALUE left, VALUE right) {
    /* Allocates the binary. */
    Binary binary = (Binary)malloc(sizeof(BinaryS));
    /* Set it up. */
    binary->kind = BINARY;
    value_to_rcsim(TypeS,type,binary->type);
    switch(sym_to_char(operator)) {
        case (unsigned char)'+':         binary->oper = add_value; break;
        case (unsigned char)'-':         binary->oper = sub_value; break;
        case (unsigned char)'*':         binary->oper = mul_value; break;
        case (unsigned char)'/':         binary->oper = div_value; break;
        case (unsigned char)'%':         binary->oper = mod_value; break;
        case (unsigned char)'&':         binary->oper = and_value; break;
        case (unsigned char)'|':         binary->oper = or_value; break;
        case (unsigned char)'^':         binary->oper = xor_value; break;
        case (unsigned char)('<'+'<'*2): binary->oper = shift_left_value; break;
        case (unsigned char)('>'+'>'*2): binary->oper = shift_right_value; break;
        case (unsigned char)('='+'='*2): binary->oper = equal_value_c; break;
        case (unsigned char)('!'+'='*2): binary->oper = not_equal_value_c; break;
        case (unsigned char)'<':         binary->oper = lesser_value; break;
        case (unsigned char)('<'+'='*2): binary->oper = lesser_equal_value; break;
        case (unsigned char)'>':         binary->oper = greater_value; break;
        case (unsigned char)('>'+'='*2): binary->oper = greater_equal_value; break;
        default: perror("Invalid operator for binary.");
    }
    value_to_rcsim(ExpressionS,left,binary->left);
    value_to_rcsim(ExpressionS,right,binary->right);
    /* Returns the C binary embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(BinaryS,binary,res);
    return res;
}

/* Creating a select C object. */
VALUE rcsim_make_select(VALUE mod, VALUE type, VALUE sel) {
    /* Allocates the select. */
    Select select = (Select)malloc(sizeof(SelectS));
    /* Set it up. */
    select->kind = SELECT;
    value_to_rcsim(TypeS,type,select->type);
    value_to_rcsim(ExpressionS,sel,select->select);
    select->num_choices = 0;
    select->choices = NULL;
    /* Returns the C select embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(SelectS,select,res);
    return res;
}

/* Creating a concat C object. */
VALUE rcsim_make_concat(VALUE mod, VALUE type, VALUE dirV) {
    /* Allocates the concat. */
    Concat concat = (Concat)malloc(sizeof(ConcatS));
    /* Set it up. */
    concat->kind = CONCAT;
    value_to_rcsim(TypeS,type,concat->type);
    concat->num_exprs = 0;
    concat->exprs = NULL;
    concat->dir = rb_id2name(SYM2ID(dirV))[0]=='l' ? 1 : 0;
    /* Returns the C concat embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(ConcatS,concat,res);
    return res;
}

/* Creating a ref concat C object. */
VALUE rcsim_make_refConcat(VALUE mod, VALUE type, VALUE dirV) {
    /* Allocates the ref concat. */
    RefConcat refConcat = (RefConcat)malloc(sizeof(RefConcatS));
    /* Set it up. */
    refConcat->kind = REF_CONCAT;
    value_to_rcsim(TypeS,type,refConcat->type);
    refConcat->num_refs = 0;
    refConcat->refs = NULL;
    refConcat->dir = rb_id2name(SYM2ID(dirV))[0]=='l' ? 0 : 1;
    /* Returns the C ref concat embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(RefConcatS,refConcat,res);
    return res;
}

/* Creating a ref index C object. */
VALUE rcsim_make_refIndex(VALUE mod, VALUE type, VALUE index, VALUE ref) {
    /* Allocates the ref index. */
    RefIndex refIndex = (RefIndex)malloc(sizeof(RefIndexS));
    /* Set it up. */
    refIndex->kind = REF_INDEX;
    value_to_rcsim(TypeS,type,refIndex->type);
    value_to_rcsim(ExpressionS,index,refIndex->index);
    value_to_rcsim(ReferenceS,ref,refIndex->ref);
    /* Returns the C ref index embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(RefIndexS,refIndex,res);
    return res;
}

/* Creating a ref range C object. */
VALUE rcsim_make_refRange(VALUE mod, VALUE type, VALUE first, VALUE last, VALUE ref) {
    /* Allocates the ref range. */
    RefRangeE refRange = (RefRangeE)malloc(sizeof(RefRangeES));
    /* Set it up. */
    refRange->kind = REF_RANGE;
    value_to_rcsim(TypeS,type,refRange->type);
    value_to_rcsim(ExpressionS,first,refRange->first);
    value_to_rcsim(ExpressionS,last,refRange->last);
    value_to_rcsim(ReferenceS,ref,refRange->ref);
    /* Returns the C ref range embedded into a ruby VALUE. */
    VALUE res;
    rcsim_to_value(RefRangeES,refRange,res);
    return res;
}

/*#### Adding elements to C simulation objects. ####*/

/* Adds inputs to a C systemT. */
VALUE rcsim_add_systemT_inputs(VALUE mod, VALUE systemTV, VALUE sigVs) {
    /* Get the C systemT from the Ruby value. */
    SystemT systemT;
    value_to_rcsim(SystemTS,systemTV,systemT);
    // printf("Adding to systemT with kind=%d and name=%s\n",systemT->kind, systemT->name);
    /* Prepare the size for the inputs. */
    long num = RARRAY_LEN(sigVs);
    long old_num = systemT->num_inputs;
    systemT->num_inputs += num;
    systemT->inputs=realloc(systemT->inputs,sizeof(SignalI)*systemT->num_inputs);
    // printf("size=%d num=%i\n",malloc_size(systemT->inputs),systemT->num_inputs);
    // printf("required size=%lu\n",sizeof(SignalI)*systemT->num_inputs);
    /* Get and add the signals from the Ruby value. */
    for(int i=0; i< num; ++i) {
        SignalI sig;
        value_to_rcsim(SignalIS,rb_ary_entry(sigVs,i),sig);
        // printf("old_num+i=%ld\n",old_num+i);
        systemT->inputs[old_num + i] = sig;
    }
    return systemTV;
}

/* Adds outputs to a C systemT. */
VALUE rcsim_add_systemT_outputs(VALUE mod, VALUE systemTV, VALUE sigVs) {
    /* Get the C systemT from the Ruby value. */
    SystemT systemT;
    value_to_rcsim(SystemTS,systemTV,systemT);
    /* Prepare the size for the outputs. */
    long num = RARRAY_LEN(sigVs);
    long old_num = systemT->num_outputs;
    systemT->num_outputs += num;
    systemT->outputs =realloc(systemT->outputs,sizeof(SignalI)*systemT->num_outputs);
    /* Get and add the signals from the Ruby value. */
    for(int i=0; i< num; ++i) {
        SignalI sig;
        value_to_rcsim(SignalIS,rb_ary_entry(sigVs,i),sig);
        systemT->outputs[old_num + i] = sig;
    }
    return systemTV;
}

/* Adds inouts to a C systemT. */
VALUE rcsim_add_systemT_inouts(VALUE mod, VALUE systemTV, VALUE sigVs) {
    /* Get the C systemT from the Ruby value. */
    SystemT systemT;
    value_to_rcsim(SystemTS,systemTV,systemT);
    /* Prepare the size for the inouts. */
    long num = RARRAY_LEN(sigVs);
    long old_num = systemT->num_inouts;
    systemT->num_inouts += num;
    systemT->inouts =realloc(systemT->inouts,sizeof(SignalI)*systemT->num_inouts);
    /* Get and add the signals from the Ruby value. */
    for(int i=0; i< num; ++i) {
        SignalI sig;
        value_to_rcsim(SignalIS,rb_ary_entry(sigVs,i),sig);
        systemT->inouts[old_num + i] = sig;
    }
    return systemTV;
}

/* Adds inners to a C scope. */
VALUE rcsim_add_scope_inners(VALUE mod, VALUE scopeV, VALUE sigVs) {
    /* Get the C scope from the Ruby value. */
    Scope scope;
    value_to_rcsim(ScopeS,scopeV,scope);
    /* Prepare the size for the inners. */
    long num = RARRAY_LEN(sigVs);
    long old_num = scope->num_inners;
    scope->num_inners += num;
    scope->inners = realloc(scope->inners,sizeof(SignalI)*scope->num_inners);
    /* Get and add the signals from the Ruby value. */
    for(int i=0; i< num; ++i) {
        SignalI sig;
        value_to_rcsim(SignalIS,rb_ary_entry(sigVs,i),sig);
        scope->inners[old_num + i] = sig;
    }
    return scopeV;
}

/* Adds behaviors to a C scope. */
VALUE rcsim_add_scope_behaviors(VALUE mod, VALUE scopeV, VALUE behVs) {
    /* Get the C scope from the Ruby value. */
    Scope scope;
    value_to_rcsim(ScopeS,scopeV,scope);
    /* Prepare the size for the behaviors. */
    long num = RARRAY_LEN(behVs);
    long old_num = scope->num_behaviors;
    scope->num_behaviors += num;
    scope->behaviors = realloc(scope->behaviors,
                               sizeof(Behavior)*scope->num_behaviors);
    /* Get and add the behaviors from the Ruby value. */
    for(int i=0; i< num; ++i) {
        Behavior beh;
        value_to_rcsim(BehaviorS,rb_ary_entry(behVs,i),beh);
        scope->behaviors[old_num + i] = beh;
    }
    return scopeV;
}

/* Adds system instances to a C scope. */
VALUE rcsim_add_scope_systemIs(VALUE mod, VALUE scopeV, VALUE sysVs) {
    /* Get the C scope from the Ruby value. */
    Scope scope;
    value_to_rcsim(ScopeS,scopeV,scope);
    /* Prepare the size for the system instances. */
    long num = RARRAY_LEN(sysVs);
    long old_num = scope->num_systemIs;
    scope->num_systemIs += num;
    scope->systemIs = realloc(scope->systemIs,
                               sizeof(SystemI)*scope->num_systemIs);
    /* Get and add the system instances from the Ruby value. */
    for(int i=0; i< num; ++i) {
        SystemI sys;
        value_to_rcsim(SystemIS,rb_ary_entry(sysVs,i),sys);
        scope->systemIs[old_num + i] = sys;
    }
    return scopeV;
}

/* Adds sub scopes to a C scope. */
VALUE rcsim_add_scope_scopes(VALUE mod, VALUE scopeV, VALUE scpVs) {
    /* Get the C scope from the Ruby value. */
    Scope scope;
    value_to_rcsim(ScopeS,scopeV,scope);
    /* Prepare the size for the sub scopes. */
    long num = RARRAY_LEN(scpVs);
    long old_num = scope->num_scopes;
    scope->num_scopes += num;
    scope->scopes = realloc(scope->scopes,
                            sizeof(Scope)*scope->num_scopes);
    /* Get and add the sub scopes from the Ruby value. */
    for(int i=0; i< num; ++i) {
        Scope scp;
        value_to_rcsim(ScopeS,rb_ary_entry(scpVs,i),scp);
        scope->scopes[old_num + i] = scp;
    }
    return scopeV;
}

/* Adds events to a C behavior. */
VALUE rcsim_add_behavior_events(VALUE mod, VALUE behaviorV, VALUE eventVs) {
    /* Get the C behavior from the Ruby value. */
    Behavior behavior;
    value_to_rcsim(BehaviorS,behaviorV,behavior);
    /* Prepare the size for the events. */
    long num = RARRAY_LEN(eventVs);
    long old_num = behavior->num_events;
    behavior->num_events += num;
    behavior->events = realloc(behavior->events,
                               sizeof(Event)*behavior->num_events);
    /* Get and add the events from the Ruby value. */
    for(int i=0; i< num; ++i) {
        Event event;
        value_to_rcsim(EventS,rb_ary_entry(eventVs,i),event);
        behavior->events[old_num + i] = event;
        /* Update the signal of the event to say it activates the behavior. */
        SignalI sig = event->signal;
        switch(event->edge) {
            case ANYEDGE:
                sig->num_any++;
                sig->any = realloc(sig->any,sizeof(Object)*sig->num_any);
                sig->any[sig->num_any-1] = (Object)behavior;
                break;
            case POSEDGE:
                sig->num_pos++;
                sig->pos = realloc(sig->pos,sizeof(Object)*sig->num_pos);
                sig->pos[sig->num_pos-1] = (Object)behavior;
                break;
            case NEGEDGE:
                sig->num_neg++;
                sig->neg = realloc(sig->neg,sizeof(Object)*sig->num_neg);
                sig->neg[sig->num_neg-1] = (Object)behavior;
                break;
            default:
                perror("Invalid value for an edge.");
        }
    }
    return behaviorV;
}

/* Adds alternate system types to a C system instance. */
VALUE rcsim_add_systemI_systemTs(VALUE mod, VALUE systemIV, VALUE sysVs) {
    /* Get the C systemI from the Ruby value. */
    SystemI systemI;
    value_to_rcsim(SystemIS,systemIV,systemI);
    /* Prepare the size for the alternate system types. */
    long num = RARRAY_LEN(sysVs);
    long old_num = systemI->num_systems;
    systemI->num_systems += num;
    systemI->systems=realloc(systemI->systems,sizeof(SystemT)*systemI->num_systems);
    /* Get and add the alternate system types from the Ruby value. */
    for(int i=0; i< num; ++i) {
        SystemT sys;
        value_to_rcsim(SystemTS,rb_ary_entry(sysVs,i),sys);
        systemI->systems[old_num + i] = sys;
    }
    return systemIV;
}

/* Adds arguments to a C print. */
VALUE rcsim_add_print_args(VALUE mod, VALUE printV, VALUE argVs) {
    /* Get the C print from the Ruby value. */
    Print print;
    value_to_rcsim(PrintS,printV,print);
    /* Prepare the size for the arguments. */
    long num = RARRAY_LEN(argVs);
    long old_num = print->num_args;
    print->num_args += num;
    print->args = realloc(print->args,
                               sizeof(Expression)*print->num_args);
    /* Get and add the arguments from the Ruby value. */
    for(int i=0; i< num; ++i) {
        Expression arg;
        value_to_rcsim(ExpressionS,rb_ary_entry(argVs,i),arg);
        print->args[old_num + i] = arg;
    }
    return printV;
}

/* Adds noifs to a C hardware if. */
VALUE rcsim_add_hif_noifs(VALUE mod, VALUE hifV, VALUE condVs, VALUE stmntVs) {
    /* Get the C hardware if from the Ruby value. */
    HIf hif;
    value_to_rcsim(HIfS,hifV,hif);
    /* Prepare the size for the noifs. */
    long num = RARRAY_LEN(condVs);
    long old_num = hif->num_noifs;
    hif->num_noifs += num;
    hif->noconds = realloc(hif->noconds, sizeof(Expression)*hif->num_noifs);
    hif->nostmnts = realloc(hif->nostmnts, sizeof(Statement)*hif->num_noifs);
    /* Get and add the noifs from the Ruby value. */
    for(int i=0; i< num; ++i) {
        Expression cond;
        Statement stmnt;
        value_to_rcsim(ExpressionS,rb_ary_entry(condVs,i),cond);
        hif->noconds[old_num + i] = cond;
        value_to_rcsim(StatementS,rb_ary_entry(stmntVs,i),stmnt);
        hif->nostmnts[old_num + i] = stmnt;
    }
    return hifV;
}

/* Adds whens to a C hardware case. */
VALUE rcsim_add_hcase_whens(VALUE mod, VALUE hcaseV, VALUE matchVs, VALUE stmntVs) {
    /* Get the C hardware case from the Ruby value. */
    HCase hcase;
    value_to_rcsim(HCaseS,hcaseV,hcase);
    /* Prepare the size for the noifs. */
    long num = RARRAY_LEN(matchVs);
    long old_num = hcase->num_whens;
    hcase->num_whens += num;
    hcase->matches = realloc(hcase->matches,
                             sizeof(Expression)*hcase->num_whens);
    hcase->stmnts = realloc(hcase->stmnts,
                             sizeof(Statement)*hcase->num_whens);
    /* Get and add the whens from the Ruby value. */
    for(int i=0; i< num; ++i) {
        Expression match;
        Statement stmnt;
        value_to_rcsim(ExpressionS,rb_ary_entry(matchVs,i),match);
        hcase->matches[old_num + i] = match;
        value_to_rcsim(StatementS,rb_ary_entry(stmntVs,i),stmnt);
        hcase->stmnts[old_num + i] = stmnt;
    }
    return hcaseV;
}

/* Adds inners to a C block. */
VALUE rcsim_add_block_inners(VALUE mod, VALUE blockV, VALUE sigVs) {
    /* Get the C block from the Ruby value. */
    Block block;
    value_to_rcsim(BlockS,blockV,block);
    /* Prepare the size for the inners. */
    long num = RARRAY_LEN(sigVs);
    long old_num = block->num_inners;
    block->num_inners += num;
    block->inners = realloc(block->inners,sizeof(SignalI)*block->num_inners);
    /* Get and add the signals from the Ruby value. */
    for(int i=0; i< num; ++i) {
        SignalI sig;
        value_to_rcsim(SignalIS,rb_ary_entry(sigVs,i),sig);
        block->inners[old_num + i] = sig;
    }
    return blockV;
}

/* Adds statements to a C block. */
VALUE rcsim_add_block_statements(VALUE mod, VALUE blockV, VALUE stmntVs) {
    /* Get the C block from the Ruby value. */
    Block block;
    value_to_rcsim(BlockS,blockV,block);
    /* Prepare the size for the statements. */
    long num = RARRAY_LEN(stmntVs);
    long old_num = block->num_stmnts;
    block->num_stmnts += num;
    block->stmnts = realloc(block->stmnts,sizeof(Statement)*block->num_stmnts);
    /* Get and add the statements from the Ruby value. */
    for(int i=0; i< num; ++i) {
        Statement stmnt;
        value_to_rcsim(StatementS,rb_ary_entry(stmntVs,i),stmnt);
        block->stmnts[old_num + i] = stmnt;
    }
    return blockV;
}

/* Adds choices to a C select. */
VALUE rcsim_add_select_choices(VALUE mod, VALUE selectV, VALUE choiceVs) {
    /* Get the C select from the Ruby value. */
    Select select;
    value_to_rcsim(SelectS,selectV,select);
    /* Prepare the size for the choices. */
    long num = RARRAY_LEN(choiceVs);
    long old_num = select->num_choices;
    select->num_choices += num;
    select->choices = realloc(select->choices,sizeof(Expression)*select->num_choices);
    /* Get and add the choices from the Ruby value. */
    for(int i=0; i< num; ++i) {
        Expression choice;
        value_to_rcsim(ExpressionS,rb_ary_entry(choiceVs,i),choice);
        select->choices[old_num + i] = choice;
    }
    return selectV;
}

/* Adds expressions to a C concat. */
VALUE rcsim_add_concat_expressions(VALUE mod, VALUE concatV, VALUE exprVs) {
    /* Get the C concat from the Ruby value. */
    Concat concat;
    value_to_rcsim(ConcatS,concatV,concat);
    /* Prepare the size for the expressions. */
    long num = RARRAY_LEN(exprVs);
    long old_num = concat->num_exprs;
    // printf("add_concat_expressions with num=%li old_num=%li\n",num,old_num);
    concat->num_exprs += num;
    concat->exprs = realloc(concat->exprs,sizeof(Expression)*concat->num_exprs);
    /* Get and add the expressions from the Ruby value. */
    for(int i=0; i< num; ++i) {
        Expression expr;
        value_to_rcsim(ExpressionS,rb_ary_entry(exprVs,i),expr);
        // printf("Adding expression with type width=%llu\n",type_width(expr->type));
        concat->exprs[old_num + i] = expr;
    }
    return concatV;
}

/* Adds references to a C ref concat. */
VALUE rcsim_add_refConcat_refs(VALUE mod, VALUE refConcatV, VALUE refVs) {
    /* Get the C refConcat from the Ruby value. */
    RefConcat refConcat;
    value_to_rcsim(RefConcatS,refConcatV,refConcat);
    /* Prepare the size for the references. */
    long num = RARRAY_LEN(refVs);
    long old_num = refConcat->num_refs;
    refConcat->num_refs += num;
    refConcat->refs = realloc(refConcat->refs,sizeof(Reference)*refConcat->num_refs);
    /* Get and add the references from the Ruby value. */
    for(int i=0; i< num; ++i) {
        Reference ref;
        value_to_rcsim(ReferenceS,rb_ary_entry(refVs,i),ref);
        refConcat->refs[old_num + i] = ref;
    }
    return refConcatV;
}


/*#### Modifying C simulation objects. ####*/

/** Sets the owner for a C simulation object. */
VALUE rcsim_set_owner(VALUE mod, VALUE objV, VALUE ownerV) {
    /* Get the C object from the Ruby value. */
    Object obj;
    value_to_rcsim(ObjectS,objV,obj);
    /* Get the C owner from the Ruby value. */
    Object owner;
    value_to_rcsim(ObjectS,ownerV,owner);
    /* Set the owner. */
    obj->owner = owner;
    return objV;
}

/** Sets the scope for a C system type. */
VALUE rcsim_set_systemT_scope(VALUE mod, VALUE systemTV, VALUE scopeV) {
    /* Get the C system type from the Ruby value. */
    SystemT systemT;
    value_to_rcsim(SystemTS,systemTV,systemT);
    /* Get the C scope from the Ruby value. */
    Scope scope;
    value_to_rcsim(ScopeS,scopeV,scope);
    /* Set the scope. */
    systemT->scope = scope;
    return systemTV;
}

/** Sets the block for a C behavior. */
VALUE rcsim_set_behavior_block(VALUE mod, VALUE behaviorV, VALUE blockV) {
    /* Get the C behavior from the Ruby value. */
    Behavior behavior;
    value_to_rcsim(BehaviorS,behaviorV,behavior);
    /* Get the C block from the Ruby value. */
    Block block;
    value_to_rcsim(BlockS,blockV,block);
    /* Set the block. */
    behavior->block = block;
    return behaviorV;
}

/** Sets the value for a C signal. */
VALUE rcsim_set_signal_value(VALUE mod, VALUE signalV, VALUE exprV) {
    /* Get the C signal from the Ruby value. */
    SignalI signal;
    value_to_rcsim(SignalIS,signalV,signal);
    // printf("rc_sim_set_signal_value for signal=%s\n",signal->name);
    /* Get the C expression from the Ruby value. */
    Expression expr;
    value_to_rcsim(ExpressionS,exprV,expr);
    /* Compute the value from it. */
    // Value value = calc_expression(expr);
    Value value = get_value();
    value = calc_expression(expr,value);
    /* Copies the value. */
    signal->f_value = copy_value(value,signal->f_value);
    free_value();
    return signalV;
}


/** Starts the C-Ruby hybrid simulation.
 *  @param systemTV the top system type. 
 *  @param name the name of the simulation.
 *  @param vcd tells if the vcd generation is used or not. */
VALUE rcsim_main(VALUE mod, VALUE systemTV, VALUE name, VALUE vcd) {
    /* Get the C system type from the Ruby value. */
    SystemT systemT;
    value_to_rcsim(SystemTS,systemTV,systemT);
    /* Set it as the top of the simulator. */
    top_system = systemT;
    /* Enable it. */
    set_enable_system(systemT,1);
    /* Starts the simulation. */
    if (TYPE(vcd) == T_TRUE) 
        hruby_sim_core(StringValueCStr(name),init_vcd_visualizer,-1);
    else
        hruby_sim_core(StringValueCStr(name),init_default_visualizer,-1);
    return systemTV;
}




/** The initialization of the C-part of the C-Ruby hybrid HDLRuby simulator. */
void Init_hruby_sim() {
    /* Generate the ID of the symbols used in the simulator. */
    make_sym_IDs();
    /* Create the module for C-Ruby interface. */
    VALUE mod = rb_define_module("RCSimCinterface");

    /* Create the class that wraps C pointers. */
    RCSimPointer = rb_define_class("RCSimPointer",rb_cObject);

    /* Add the interface methods. */
    /* Getting the C simulation type objects. */
    rb_define_singleton_method(mod,"rcsim_get_type_bit",rcsim_get_type_bit,0);
    rb_define_singleton_method(mod,"rcsim_get_type_signed",rcsim_get_type_signed,0);
    rb_define_singleton_method(mod,"rcsim_get_type_vector",rcsim_get_type_vector,2);
    /* Creating the C simulation objects. */
    rb_define_singleton_method(mod,"rcsim_make_systemT",rcsim_make_systemT,1);
    rb_define_singleton_method(mod,"rcsim_make_scope",rcsim_make_scope,1);
    rb_define_singleton_method(mod,"rcsim_make_behavior",rcsim_make_behavior,1);
    rb_define_singleton_method(mod,"rcsim_make_event",rcsim_make_event,2);
    rb_define_singleton_method(mod,"rcsim_make_signal",rcsim_make_signal,2);
    rb_define_singleton_method(mod,"rcsim_make_systemI",rcsim_make_systemI,2);
    rb_define_singleton_method(mod,"rcsim_make_transmit",rcsim_make_transmit,2);
    rb_define_singleton_method(mod,"rcsim_make_print",rcsim_make_print,0);
    rb_define_singleton_method(mod,"rcsim_make_timeWait",rcsim_make_timeWait,2);
    rb_define_singleton_method(mod,"rcsim_make_timeTerminate",rcsim_make_timeTerminate,0);
    rb_define_singleton_method(mod,"rcsim_make_hif",rcsim_make_hif,3);
    rb_define_singleton_method(mod,"rcsim_make_hcase",rcsim_make_hcase,2);
    rb_define_singleton_method(mod,"rcsim_make_block",rcsim_make_block,1);
    rb_define_singleton_method(mod,"rcsim_make_value_numeric",rcsim_make_value_numeric,2);
    rb_define_singleton_method(mod,"rcsim_make_value_bitstring",rcsim_make_value_bitstring,2);
    rb_define_singleton_method(mod,"rcsim_make_cast",rcsim_make_cast,2);
    rb_define_singleton_method(mod,"rcsim_make_unary",rcsim_make_unary,3);
    rb_define_singleton_method(mod,"rcsim_make_binary",rcsim_make_binary,4);
    rb_define_singleton_method(mod,"rcsim_make_select",rcsim_make_select,2);
    rb_define_singleton_method(mod,"rcsim_make_concat",rcsim_make_concat,2);
    rb_define_singleton_method(mod,"rcsim_make_refConcat",rcsim_make_refConcat,1);
    rb_define_singleton_method(mod,"rcsim_make_refIndex",rcsim_make_refIndex,3);
    rb_define_singleton_method(mod,"rcsim_make_refRange",rcsim_make_refRange,4);
    /* Adding elements to C simulation objects. */
    rb_define_singleton_method(mod,"rcsim_add_systemT_inputs",rcsim_add_systemT_inputs,2);
    rb_define_singleton_method(mod,"rcsim_add_systemT_outputs",rcsim_add_systemT_outputs,2);
    rb_define_singleton_method(mod,"rcsim_add_systemT_inouts",rcsim_add_systemT_inouts,2);
    rb_define_singleton_method(mod,"rcsim_add_scope_inners",rcsim_add_scope_inners,2);
    rb_define_singleton_method(mod,"rcsim_add_scope_behaviors",rcsim_add_scope_behaviors,2);
    rb_define_singleton_method(mod,"rcsim_add_scope_systemIs",rcsim_add_scope_systemIs,2);
    rb_define_singleton_method(mod,"rcsim_add_scope_scopes",rcsim_add_scope_scopes,2);
    rb_define_singleton_method(mod,"rcsim_add_behavior_events",rcsim_add_behavior_events,2);
    rb_define_singleton_method(mod,"rcsim_add_systemI_systemTs",rcsim_add_systemI_systemTs,2);
    rb_define_singleton_method(mod,"rcsim_add_print_args",rcsim_add_print_args,2);
    rb_define_singleton_method(mod,"rcsim_add_hif_noifs",rcsim_add_hif_noifs,3);
    rb_define_singleton_method(mod,"rcsim_add_hcase_whens",rcsim_add_hcase_whens,3);
    rb_define_singleton_method(mod,"rcsim_add_block_inners",rcsim_add_block_inners,2);
    rb_define_singleton_method(mod,"rcsim_add_block_statements",rcsim_add_block_statements,2);
    rb_define_singleton_method(mod,"rcsim_add_select_choices",rcsim_add_select_choices,2);
    rb_define_singleton_method(mod,"rcsim_add_concat_expressions",rcsim_add_concat_expressions,2);
    rb_define_singleton_method(mod,"rcsim_add_refConcat_refs",rcsim_add_refConcat_refs,2);
    /* Modifying C simulation objects. */
    rb_define_singleton_method(mod,"rcsim_set_owner",rcsim_set_owner,2);
    rb_define_singleton_method(mod,"rcsim_set_systemT_scope",rcsim_set_systemT_scope,2);
    rb_define_singleton_method(mod,"rcsim_set_behavior_block",rcsim_set_behavior_block,2);
    rb_define_singleton_method(mod,"rcsim_set_signal_value",rcsim_set_signal_value,2);
    /* Starting the simulation. */
    rb_define_singleton_method(mod,"rcsim_main",rcsim_main,3);

}


#endif
