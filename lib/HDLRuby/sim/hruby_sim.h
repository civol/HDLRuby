/**
 *  The HDLRuby simulation global header, to include in C code
 *  generated by hruby_low2c. 
 **/

#include <pthread.h>
#include <stdarg.h>


/* The interface to the HDLRuby objects C models. */

typedef struct TypeS_      TypeS;
typedef struct FlagsS_     FlagsS;
typedef struct ValueS_     ValueS;
typedef struct ObjectS_    ObjectS;
typedef struct SystemTS_   SystemTS;
typedef struct SignalIS_   SignalIS;
typedef struct ScopeS_     ScopeS;
typedef struct BehaviorS_  BehaviorS;
typedef struct SystemIS_   SystemIS;
typedef struct CodeS_      CodeS;
typedef struct BlockS_     BlockS;
typedef struct EventS_     EventS;

typedef struct RefRangeS_  RefRangeS;

typedef struct TypeS_*     Type;
typedef struct ValueS_*    Value;
typedef struct ObjectS_*   Object;
typedef struct SystemTS_*  SystemT;
typedef struct SignalIS_*  SignalI;
typedef struct ScopeS_*    Scope;
typedef struct BehaviorS_* Behavior;
typedef struct SystemIS_*  SystemI;
typedef struct CodeS_*     Code;
typedef struct BlockS_*    Block;
typedef struct EventS_*    Event;

typedef struct RefRangeS_*  RefRange;

/* The kinds of HDLRuby objects. */
typedef enum { 
    OBJECT, SYSTEMT, SIGNALI, SCOPE, BEHAVIOR, SYSTEMI, CODE, BLOCK, EVENT 
} Kind;

/*  The kinds of HDLRuby event edge. */
typedef enum {
    ANYEDGE, POSEDGE, NEGEDGE
} Edge;


/* The interface to the type engine. */
typedef struct FlagsS_ {
    // unsigned int all;
    // unsigned int sign : 1; /* Tells if the type is signed or not. */
    unsigned int sign; /* Tells if the type is signed or not. */
} FlagsS;

/** The type structure. */
typedef struct TypeS_ {
    unsigned long long base;   /* The size in bits of the base elements. */
    unsigned long long number; /* The number of elements of the type. */
    FlagsS flags;              /* The features of the type. */
} TypeS;


/** Computes the width in bits of a type.
 *  @param type the type to compute the width
 *  @return the resulting width in bits */
extern unsigned long long type_width(Type type);

/** Gets the single bit type. */
extern Type get_type_bit();

/** Gets the single signed bit type. */
extern Type get_type_signed();

/** Creates a new type from a HDLRuby TypeVector.
 *  @param base the type of an element
 *  @param number the number of base elements */
extern Type make_type_vector(Type base, unsigned long long number);

/** Gets a vector type by size and base.
 *  @param base the type of an element
 *  @param number the number of base elements */
extern Type get_type_vector(Type base, unsigned long long number);



/* The interface to the value computation engine. */

/* The structure of a value. */
typedef struct ValueS_ {
    Type type;                   /* The type of the value. */
    int numeric;         /* Tell if the value is numeric or a bitstring. */
    unsigned long long capacity; /* The capacity in char of the bit string. */
    char* data_str;             /* The bit string data if not numeric. */
    unsigned long long data_int;/* The integer data if numeric. */
    SignalI signal;         /* The signal associated with the value if any. */
} ValueS;

/* The tructure of a reference to a range in a value. */
typedef struct RefRangeS_ {
    SignalI signal;           /* The refered signal. */
    Type type;                /* The tyep of the elements. */
    unsigned long long first; /* The first index in the range. */
    unsigned long long last;  /* The last index in the range. */
} RefRangeS;

/** Creates a new value.
 *  @param type the type of the value
 *  @param numeric tells if the value is numeric or not
 *  @return the resulting value */
extern Value make_value(Type type,int numeric);

/** Sets a value with data.
 *  @param value the value to fill
 *  @param numeric tell if the value is in numeric form or in bitstring form
 *  @param data the source data */
extern void set_value(Value value, int numeric, void* data);

/** Makes and sets a value with data.
 *  @param type the type of the value
 *  @param numeric tell if the value is in numeric form or in bitstring form
 *  @param data the source data */
extern Value make_set_value(Type type, int numeric, void* data);


/** Computes the neg of a value.
 *  @param src the source value of the neg
 *  @param dst the destination value
 *  @return dst */
extern Value neg_value(Value src, Value dst);

/** Computes the addition of two values.
 *  @param src0 the first source value of the addition
 *  @param src1 the second source value of the addition
 *  @param dst the destination value
 *  @return dst */
extern Value add_value(Value src0, Value src1, Value dst);

/** Computes the subtraction of two values.
 *  @param src0 the first source value of the subtraction
 *  @param src1 the second source value of the subtraction
 *  @param dst the destination value
 *  @return dst */
extern Value sub_value(Value src0, Value src1, Value dst);

/** Computes the multiplication of two general values.
 *  @param src0 the first source value of the addition
 *  @param src1 the second source value of the addition
 *  @param dst the destination value
 *  @return dst */
extern Value mul_value(Value src0, Value src1, Value dst);

/** Computes the division of two general values.
 *  @param src0 the first source value of the addition
 *  @param src1 the second source value of the addition
 *  @param dst the destination value
 *  @return dst */
extern Value div_value(Value src0, Value src1, Value dst);

/** Computes the modulo of two general values.
 *  @param src0 the first source value of the addition
 *  @param src1 the second source value of the addition
 *  @param dst the destination value
 *  @return dst */
extern Value mod_value(Value src0, Value src1, Value dst);

/** Computes the not of a value.
 *  @param src the source value of the not
 *  @param dst the destination value
 *  @return dst */
extern Value not_value(Value src, Value dst);

/** Compute the or of the bits a a value.
 *  @param src the source value
 *  @param dst the destination value
 *  @return dst */
extern Value reduce_or_value(Value src, Value dst);

/** Computes the AND of two values.
 *  @param src0 the first source value of the and
 *  @param src1 the second source value of the and
 *  @param dst the destination value
 *  @return dst */
extern Value and_value(Value src0, Value src1, Value dst);

/** Computes the OR of two values.
 *  @param src0 the first source value of the or
 *  @param src1 the second source value of the or
 *  @param dst the destination value
 *  @return dst */
extern Value or_value(Value src0, Value src1, Value dst);

/** Computes the XOR of two values.
 *  @param src0 the first source value of the xor
 *  @param src1 the second source value of the xor
 *  @param dst the destination value
 *  @return dst */
extern Value xor_value(Value src0, Value src1, Value dst);

/** Computes the left shift of two general values.
 *  @param src0 the first source value of the shift
 *  @param src1 the second source value of the shift
 *  @param dst the destination
 *  @return dst */
Value shift_left_value(Value src0, Value src1, Value dst);

/** Computes the right shift of two general values.
 *  @param src0 the first source value of the shift
 *  @param src1 the second source value of the shift
 *  @param dst the destination
 *  @return dst */
Value shift_right_value(Value src0, Value src1, Value dst);

/** Computes the equal (NXOR) of two values.
 *  @param src0 the first source value of the comparison
 *  @param src1 the second source value of the comparison
 *  @param dst the destination value
 *  @return dst */
extern Value equal_value(Value src0, Value src1, Value dst);

/** Computes the C equal of two general values.
 *  @param src0 the first source value of the addition
 *  @param src1 the second source value of the addition
 *  @param dst the destination value
 *  @return the destination value */
extern Value equal_value_c(Value src0, Value src1, Value dst);

/** Computes the C not equal of two general values.
 *  @param src0 the first source value of the addition
 *  @param src1 the second source value of the addition
 *  @param dst the destination value
 *  @return the destination value */
extern Value not_equal_value_c(Value src0, Value src1, Value dst);

/** Computes the greater comparision of two values.
 *  @param src0 the first source value of the comparison
 *  @param src1 the second source value of the comparison
 *  @param dst the destination value
 *  @return dst */
extern Value greater_value(Value src0, Value src1, Value dst);

/** Computes the lesser comparision of two values.
 *  @param src0 the first source value of the comparison
 *  @param src1 the second source value of the comparison
 *  @param dst the destination value
 *  @return dst */
extern Value lesser_value(Value src0, Value src1, Value dst);

/** Computes the greater or equal comparision of two values.
 *  @param src0 the first source value of the comparison
 *  @param src1 the second source value of the comparison
 *  @param dst the destination value
 *  @return dst */
extern Value greater_equal_value(Value src0, Value src1, Value dst);

/** Computes the lesser or equal comparision of two values.
 *  @param src0 the first source value of the comparison
 *  @param src1 the second source value of the comparison
 *  @param dst the destination value
 *  @return dst */
extern Value lesser_equal_value(Value src0, Value src1, Value dst);

/** Selects a value depending on a condition.
 *  @param cond   the condition to use for selecting a value
 *  @param dst    the destination value
 *  @param num    the number of values for the selection
 *  @return the selected value */
extern Value select_value(Value cond, Value dst, unsigned int num, ...);

/** Concat multiple values to a single one.
 *  @param num the number of values to concat
 *  @param dir the direction of concatenation
 *  @param dst the destination value
 *  @return dst */
extern Value concat_value(int num, int dir, Value dst, ...);
extern Value concat_valueV(int num, int dir, Value dst, va_list args);
extern Value concat_valueP(int num, int dir, Value dst, Value* args);

/** Casts a value to another type.
 *  @param src the source value
 *  @param type the type to cast to
 *  @param dst the destination value
 *  @return dst */
extern Value cast_value(Value src, Type type, Value dst);

/** Copies a value to another, the type of the destination is preserved.
 *  @param src the source value
 *  @param dst the destination value
 *  @return dst */
extern Value copy_value(Value src, Value dst);

/** Copies a value to another but without overwritting with Z, the type of 
 *  the destination is preserved.
 *  @param src the source value
 *  @param dst the destination value
 *  @return dst */
extern Value copy_value_no_z(Value src, Value dst);

/** Testing if a value is 0.
 *  @param value the value to check 
 *  @return 1 if 0 and 0 otherwize */
extern int zero_value(Value value);

/** Testing if a value is defined or not.
 *  @param value the value to check
 *  @return 1 if defined and 0 otherwize */
extern int is_defined_value(Value value);

/** Testing if two values have the same content (the type is not checked).
 *  @param value0 the first value to compare
 *  @param value1 the second value to compare
 *  @return 1 if same content. */
extern int same_content_value(Value value0, Value value1);

/** Testing if two values have the same content (the type is not checked).
 *  @param value0 the first value to compare
 *  @param first the first index of the range
 *  @param last the last index of the range
 *  @param value1 the second value to compare
 *  @return 1 if same content. */
extern int same_content_value_range(Value value0, unsigned long long first,
        unsigned long long last, Value value1);

/** Creates a reference to a range inside a signal.
 *  @param signal the signal to refer
 *  @param typ the type of the elements.
 *  @param first the start index of the range
 *  @param last the end index of the range
 *  @return the resulting reference */
extern RefRangeS make_ref_rangeS(SignalI signal, Type typ, 
        unsigned long long first, unsigned long long last);


/* The interface for the lists. */

/** The list element data structure. */
typedef struct ElemS_ {
    void* data;          /* The data stored in the element. */
    struct ElemS_* next; /* The next element in the lisdt if any. */
} ElemS;

typedef ElemS* Elem;

/** The list data structure. */
typedef struct ListS_ {
    Elem head;   /* The head of the list */
    Elem tail;   /* The tail of the list */
} ListS;

typedef ListS* List;

/** Get a list element for containing some data.
 *  @param data the data of the element
 *  @return the resulting element */
extern Elem get_element(void* data);

/** Delete an element (it will return to the pool).
  *  @param elem the element to delete */
void delete_element(Elem elem);

/** Tells if a list is empty.
 *  @param list the list to check. */
#define empty_list(list) ((list)->head == NULL)

/** Builds a list.
 *  @param list the place where to build the list
 *  @return the resulting list */
extern List build_list(List list);

/** Clears a list.
 *  @param list the list to clear */
extern void clear_list(List list);

/** Adds an element to the tail of a list.
 *  @param list the list to add the element in
 *  @param elem the element to add in the list */
extern void add_list(List list, Elem elem);

/** Remove the head of the list.
 *  @param list the list to remove the head from
 *  @return the removed element */
extern Elem remove_list(List list);


/* The interface for the pool of values. */

/** Get a fresh value. */
extern Value get_value();

/** Get the current top value. */
Value get_top_value();

/** Frees the last value of the pool. */
extern void free_value();

/** Gets the current state of the value pool. */
extern unsigned int get_value_pos();

/** Restores the state of the value pool.
 *  @param pos the new position in the pool */
extern void set_value_pos(unsigned int pos);

/** Saves the current state+1 of the value pool to the pool state stack. */
extern void save_value_pos();

/** Restores the state of the value pool from the state stack. */
extern void restore_value_pos();

/** Macros for short control of the pool of values. */
#define SV save_value_pos();
#define PV push(get_value());save_value_pos();
#define RV restore_value_pos();




/** An HDLRuby object. */
typedef struct ObjectS_ {
    Kind kind;          /* The kind of object. */
    Object owner;       /* The owner of the object if any. */
} ObjectS;


/** The C model of a SystemT. */
typedef struct SystemTS_ {
    Kind kind;          /* The kind of object. */
    Object owner;       /* The owner if any. */

    char* name;         /* The name of the system. */
    int num_inputs;     /* The number of inputs. */
    SignalI* inputs;    /* The inputs of the system. */
    int num_outputs;    /* The number of outputs. */
    SignalI* outputs;   /* The outputs of the system. */
    int num_inouts;     /* The number of inouts. */
    SignalI* inouts;    /* The inouts of the system. */
    Scope scope;        /* The scope of the system. */
} SystemTS;


/** The C model of a Signal. */
typedef struct SignalIS_ {
    Kind kind;          /* The kind of object. */
    Object owner;       /* The owner if any. */

    char* name;         /* The name of the signal. */
    Type  type;         /* The type of the signal. */
    Value c_value;      /* The current value of the signal. */
    Value f_value;      /* The future (next) value of the signal. */

    int fading;         /* Tell if the signal can be overwritten by Z. */

    int num_any;        /* The number of behavior activated on any edge. */
    Object* any;        /* The objects activated on any edge. */
    int num_pos;        /* The number of behavior activated on pos edge. */
    Object* pos;        /* The objects actvated on pos edge. */
    int num_neg;        /* The number of behavior activated on neg edge. */
    Object* neg;        /* The objects actvated on neg edge. */
} SignalIS;


/** The C model of a system instance. */
typedef struct SystemIS_ {
    Kind kind;          /* The kind of object. */
    Object owner;       /* The owner if any. */

    char* name;         /* The name of the signal. */
    SystemT system;     /* The instantiated system. */
} SystemIS;


/** The C model of a Scope. */
typedef struct ScopeS_ {
    Kind kind;          /* The kind of object. */
    Object owner;       /* The owner if any. */

    char* name;         /* The name of the scope. */
    int num_systemIs;   /* The number of system instances. */
    SystemI* systemIs;  /* The system instances of the scope. */
    int num_inners;     /* The number of inners. */
    SignalI* inners;    /* The inners of the scope. */
    int num_scopes;     /* The number of sub scopes. */
    Scope *scopes;      /* The sub scopes of the scope. */
    int num_behaviors;  /* The number of behaviors. */
    Behavior* behaviors;/* The behaviors of the scope. */
    int num_codes;      /* The number of non-HDLRuby codes. */
    Code* codes;        /* The non-HDLRuby codes of the scope. */
} ScopeS;


/** The C model of a behavior. */
typedef struct BehaviorS_ {
    Kind kind;          /* The kind of object. */
    Object owner;       /* The owner if any. */

    int num_events;     /* The number of events. */
    Event* events;      /* The events of the behavior. */
    Block block;        /* The block of the behavior. */

    int activated;      /* Tells if the behavior is activated or not. */

    int timed;          /* Tell if the behavior is timed or not:
                           - 0: not timed
                           - 1: timed
                           - 2: timed and finished. */
    unsigned long long active_time; /* The next time the behavior has to be activated. */
    pthread_t thread;   /* The thread assotiated with the behavior (if any).*/
} BehaviorS;


/** The C model of non-HDLRuby code. */
typedef struct CodeS_ {
    Kind kind;          /* The kind of object. */
    Object owner;       /* The owner if any. */

    int num_events;     /* The number of events. */
    Event* events;      /* The events of the behavior. */
    void (*function)(); /* The function to execute for the code. */

    int activated;      /* Tells if the code is activated or not. */
} CodeS;


/** The C model of a Scope. */
typedef struct BlockS_ {
    Kind kind;          /* The kind of object. */
    Object owner;       /* The owner if any. */

    char* name;         /* The name of the block. */
    int num_inners;     /* The number of inners. */
    SignalI* inners;    /* The inners of the scope. */
    void (*function)(); /* The function to execute for the block. */
} BlockS;


/** The C model of a Scope. */
typedef struct EventS_ {
    Kind kind;          /* The kind of object. */
    Object owner;       /* The owner if any. */

    Edge edge;          /* The edge of the event. */
    SignalI signal;     /* The signal of the event. */
} EventS;



/* The interface to the simulator. */

/* The time units. */
typedef enum { S, MS, US, NS, PS, FS } Unit;

/** The top system. */
extern SystemT top_system;

/** Adds a timed behavior for processing. 
 *  @param behavior the timed behavior to register */
extern void register_timed_behavior(Behavior behavior);

/** Adds a signal for global processing. 
 *  @param signal the signal to register  */
extern void register_signal(SignalI signal);

/** Makes the behavior wait for a given time.
 *  @param delay the delay to wait in fs.
 *  @param behavior the current behavior. */
extern void hw_wait(unsigned long long delay, Behavior behavior);

// /** Transmit a signal to another signal.
//  *  @param dst the destination signal
//  *  @param src the source signal */
// extern void transmit(SignalI src, SignalI dst);

/** Touch a signal. 
 *  @param signal the signal to touch  */
extern void touch_signal(SignalI signal);

/** Transmit a value to a signal.
 *  @param value the value to transmit
 *  @param signal the signal to transmit the value to. */
extern void transmit_to_signal(Value value, SignalI signal);

/** Transmit a value to a range within a signal.
 *  @param value the value to transmit
 *  @param ref the reference to the range in the signal to transmit the
 *         value to. */
extern void transmit_to_signal_range(Value value, RefRangeS ref);


/** Touch a signal. in case of a sequential execution model.
 *  @param signal the signal to touch  */
extern void touch_signal_seq(SignalI signal);

/** Transmit a value to a signal in case of a sequential execution model.
 *  @param value the value to transmit
 *  @param signal the signal to transmit the value to. */
extern void transmit_to_signal_seq(Value value, SignalI signal);

/** Transmit a value to a range within a signal in case of sequential
 *  execution model.
 *  @param value the value to transmit
 *  @param ref the reference to the range in the signal to transmit the
 *         value to. */
extern void transmit_to_signal_range_seq(Value value, RefRangeS ref);

/** Creates an event.
 *  @param edge the edge of the event
 *  @param signal the signal of the event */
extern Event make_event(Edge edge, SignalI signal);

/** Creates a delay.
 *  Actually generates an unsigned long long giving the corresponding
 *  delay in the base unit of the simulator. 
 *  @param value the value of the delay
 *  @param unit the used unit
 *  @return the result delay in the base unit of the simulator (ns) */
extern unsigned long long make_delay(int value, Unit unit);



/* Iterate over all the signals.
 * @param func function to applie on each signal. */
extern void each_all_signal(void (*func)(SignalI));

/* Interface to the visualization engine. */

typedef struct {
    /* The simulation prints. */
    void (*print_time)(unsigned long long);
    void (*print_name)(Object);
    void (*print_value)(Value);
    void (*print_signal)(SignalI);
    /* The custom 'string' prints. */
    void (*print_string)(const char*);
    void (*print_string_name)(Object);
    void (*print_string_value)(Value);
} PrinterS;

extern PrinterS printer;

/** Initializes the visualization printer engine.
 *  @param print_time the time printer
 *  @param print_name the name printer
 *  @param print_value the value printer
 *  @param print_signal the signal state printer
 *  @param print_string the string printer
 *  @param print_string_name the string name printer
 *  @param print_string_value the string value printer */
extern void init_visualizer(void (*print_time)(unsigned long long), 
                            void (*print_name)(Object),
                            void (*print_value)(Value),
                            void (*print_signal)(SignalI),
                            void (*print_string)(const char*),
                            void (*print_string_name)(Object),
                            void (*print_string_value)(Value));

/** Prints a name (default).
 *  @param signal the signal to show */
extern void default_print_name(Object);

/** Prints a value (default).
 *  @param signal the signal to show */
extern void default_print_value(Value);

/** Prints a string (default).
 *  @param str the string to print. */
extern void default_print_string(const char* str);

// /** Prints the time.
//  *  @param time the time to show. */
// extern void print_time(unsigned long long time);
// 
// // /** Prints the time and goes to the next line.
// //  *  @param time the time to show. */
// // extern void println_time(unsigned long long time);
// 
// /** Prints the name of an object.
//  *  @param object the object to print the name. */
// extern void print_name(Object object);
// 
// /** Prints a value.
//  *  @param value the value to print */
// extern void print_value(Value value);
// 
// /** Prints a signal.
//  *  @param signal the signal to show */
// extern void print_signal(SignalI signal);
// 
// // /** Prints a signal and goes to the next line.
// //  *  @param signal the signal to show */
// // extern void println_signal(SignalI signal);

/** Sets up the default vizualization engine.
 *  @param name the name of the vizualization. */
extern void init_default_visualizer(char* name);

/** Sets up the vcd vizualization engine.
 *  @param name the name of the vizualization. */
extern void init_vcd_visualizer(char* name);

/* The interface to the simulator core. */

/** The simulation core function.
 *  @param name the name of the simulation.
 *  @param init_vizualizer the vizualizer engine initializer.
 *  @param limit the time limit in fs. */
extern void hruby_sim_core(char* name, void (*init_vizualizer)(char*),
                           unsigned long long limit);



/* Access and conversion functions. */

/** Converts a value to a long long int.
 *  @param value the value to convert
 *  @return the resulting unsigned int. */
extern unsigned long long value2integer(Value value);

/** Reads a range from a value. 
 *  @param value the value to read
 *  @param first the first index of the range
 *  @param last the last index of the range
 *  @param base the type of the elements
 *  @param dst the destination value
 *  @return dst */
extern Value read_range(Value value, long long first, long long last,
                        Type base, Value dst);

/** Writes to a range within a value. 
 *  @param src the source value
 *  @param first the first index of the range
 *  @param last the last index of the range
 *  @param base the type of the elements
 *  @param dst the destination value
 *  @return dst */
extern Value write_range(Value src, long long first, long long last, 
        Type base, Value dst);

/** Writes to a range within a value but without overwrite with Z. 
 *  @param src the source value
 *  @param first the first index of the range
 *  @param last the last index of the range
 *  @param base the type of the elements
 *  @param dst the destination value
 *  @return dst */
extern Value write_range_no_z(Value src, long long first, long long last,
        Type base, Value dst);


/** Stack-based computations. */

/** Push a value.
 *  @param val the value to push. */
extern void push(Value val);

/** Pops a value.
 *  @return the value. */
extern Value pop();

/** Access the top value of the stack without removing it.
 *  @return the value. */
extern Value peek();

/** Unary calculation.
 *  @param oper the operator function
 *  @return the destination
 **/
extern Value unary(Value (*oper)(Value,Value));

/** Binary calculation.
 *  @param oper the operator function
 *  @return the destination
 **/
extern Value binary(Value (*oper)(Value,Value,Value));

/** Cast calculation.
 *  @param typ the type to cast to.
 *  @return the destination.
 **/
extern Value cast(Type typ);

/* Concat values.
 * @param num the number of values to concat.
 * @param dir the direction. */
extern Value sconcat(int num, int dir);

/* Index read calculation.
 * @param typ the data type of the access. */
extern Value sreadI(Type typ);

/* Index write calculation.
 * @param typ the data type of the access. */
extern Value swriteI(Type typ);

/* Range read calculation.
 * @param typ the data type of the access. */
extern Value sreadR(Type typ);

/* Range write calculation.
 * @param typ the data type of the access. */
extern Value swriteR(Type typ);

/** Check if the top value is defined. */
extern int is_defined();

/** Convert the top value to an integer. */
extern unsigned long long to_integer();

/** Check if a value is true.
 *  Actually check if it is defined and convert it to integer. */
extern unsigned long long is_true();

/* Transmit the top value to a signal in parallel. 
 * @param sig the signal to transmit to. */
extern void transmit(SignalI sig);

/* Transmit the top value to a signal in sequence.
 * @param sig the signal to transmit to. */
extern void transmit_seq(SignalI sig);

/* Transmit the top value to a range in a signal in parallel. 
 * @param ref the ref to the range of the signal to transmit to. */
extern void transmitR(RefRangeS ref);

/* Transmit the top value to a range in a signal in sequence. 
 * @param ref the ref to the range of the signal to transmit to. */
extern void transmitR_seq(RefRangeS ref);
