#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdarg.h>
#include "hruby_sim.h"


/**
 *  The HDLRuby simulation vcd format genertion engine, to be used with C code
 *  generated by the csim engine or by the rcsim engine.
 **/

/* Global variables storing the configuration of the vcd generation. */

/* The target file. */
static FILE* vcd_file;

/* The time scale unit in the ps. */
static unsigned long long vcd_timeunit = 1;

/* Accessing target file. */

/** Prints to the vcd file.
 *  @param fmt the format for handling the variadic arguments. */
static int vcd_print(const char* fmt, ...) {
    int ret;

    /* Declare a va_list type variable */
    va_list myargs;

    /* Initialise the va_list variable with the ... after fmt */
    va_start(myargs, fmt);

    /* Forward the '...' to vprintf */
    ret = vfprintf(vcd_file, fmt, myargs);

    /* Clean up the va_list */
    va_end(myargs);

    return ret;
}


/* Utility functions for printing in vcd format. */

/* Replace all the occurences of a character with another. 
 * CREDIT: Superlokkus */
static char* replace_char(char* str, char find, char replace){
    char *current_pos = strchr(str,find);
    while (current_pos){
        *current_pos = replace;
        current_pos = strchr(current_pos+1,find);
    }
    return str;
}


/* Low-end print functions. */

/** Prints the time.
 *  @param time the time to show (given in ps). */
static void vcd_print_time(unsigned long long time) {
    vcd_print("#%llu\n",time/vcd_timeunit);
}


/** Prints the name of an object without its hierarchy.
 *  @param object the object to print the name. */
static void vcd_print_name(Object object) {
    /* Depending on the kind of object. */
    switch(object->kind) {
        case SYSTEMT:
        case SIGNALI:
        case SCOPE:
        case SYSTEMI:
        case BLOCK:
            /* Print the name if name. */
            /* Trick: SystemT, SignalI, Scope and SystemI have the
             * field name at the same place. */
            if ((((Block)object)->name != NULL) &&
                    strlen(((Block)object)->name)>0) {
                char name[256];
                strncpy(name,((Block)object)->name,256);
                replace_char(name,':','$');
                vcd_print("%s",name);
            } else {
                /* No name, use the address of the object as name generator.*/
                vcd_print("x$%p",(void*)object);
            }
            break;
        default: /* Nothing to do */
            break;
    }
}


/** Prints the name of an object incluing its hierarchy.
 *  @param object the object to print the name. */
static void vcd_print_full_name(Object object) {
    /* Recurse on the owner if any. */
    if (object->owner != NULL) {
        vcd_print_full_name(object->owner);
        vcd_print("$");
    }
    /* Print the name of the object. */
    vcd_print_name(object);
}

/** Prints the id of a signal in vcd indentifier format.
 *  @param signal the signal to print the id. */
static void vcd_print_signal_id(SignalI signal) {
    size_t id = signal->id;
    do {
        vcd_print("%c",(id % (127-33)) + 33);
        id = id / (127-33);
    } while (id > 0);
}

/** Prints a value.
 *  @param value the value to print */
static void vcd_print_value(Value value) {
    unsigned long long width = type_width(value->type);
    if (width > 1) vcd_print("b");
    if (value->numeric) {
        // unsigned long long width = type_width(value->type);
        unsigned long long mask = 1ULL << (width-1);
        for(; mask > 0; mask >>= 1) {
            vcd_print("%d",(value->data_int & mask) != 0);
        }
    } else {
        /* Display a bitstring value. */
        unsigned long long i;
        // unsigned long long width = type_width(value->type);
        char* data = value->data_str;
        if (value->capacity == 0) {
            /* The value is empty, therefore undefined. */
            for(i=width; i>0; --i) {
                vcd_print("u");
            }
        }
        else {
            /* The value is not empty. */
            for(i=width; i>0; --i) {
                vcd_print("%c",data[i-1]);
            } 
        }
    }
    if (width > 1) vcd_print(" ");
}

/** Prints a signal declaration.
 *  @param signal the signal to declare */
static void vcd_print_var(SignalI signal) {
    vcd_print("$var wire %d ",type_width(signal->type));
    // vcd_print_full_name((Object)signal);
    vcd_print_signal_id(signal);
    vcd_print(" ");
    vcd_print_name((Object)signal);
    vcd_print(" $end\n");
}


/** Prints a signal with its future value if any.
 *  @param signal the signal to show */
static void vcd_print_signal_fvalue(SignalI signal) {
    if (signal->f_value) {
        vcd_print_value(signal->f_value);
        // vcd_print(" ");
        // vcd_print_full_name((Object)signal);
        vcd_print_signal_id(signal);
        vcd_print("\n");
    }
}


/** Prints a signal with its current value if any
 *  @param signal the signal to show */
static void vcd_print_signal_cvalue(SignalI signal) {
    if (signal->c_value) {
        vcd_print_value(signal->c_value);
        // vcd_print(" ");
        // vcd_print_full_name((Object)signal);
        vcd_print_signal_id(signal);
        vcd_print("\n");
    }
}


/** Prints the hierarchy content of a system type.
 *  @param system the system to print. */
static void vcd_print_systemT_content(SystemT system);

/** Prints the hierarchy of a scope.
 *  @param scope the scope to print. */
static void vcd_print_scope(Scope scope);


/** Prints the hierarchy of a block.
 *  @param block the block to print. */
static void vcd_print_block(Block block) {
    int i;
    /* Do not print block with no declaration. */
    if (block->num_inners == 0) return;

    /* Declares the block if named. */
    vcd_print("$scope module ");
    vcd_print_name((Object)block);
    vcd_print(" $end\n");

    /* Declare the inners of the systems. */
    for(i=0; i<block->num_inners; ++i) {
        vcd_print_var(block->inners[i]);
    }

    /* Close the hierarchy. */
    vcd_print("$upscope $end\n");
}


/** Prints the hierarchy of a system instances.
 *  @param scope the scope to print. */
static void vcd_print_systemI(SystemI systemI) {
    /* Declares the systemI. */
    vcd_print("$scope module ");
    vcd_print_name((Object)systemI);
    vcd_print(" $end\n");

    /* Declares its content. */
    vcd_print_systemT_content(systemI->system);

    /* Close the hierarchy. */
    vcd_print("$upscope $end\n");
}


/** Prints the hierarchy inside a scope.
 *  @param scope the scope to print the inside. */
static void vcd_print_scope_content(Scope scope) {
    int i;

    /* Declare the inners of the systems. */
    for(i=0; i<scope->num_inners; ++i) {
        vcd_print_var(scope->inners[i]);
    }

    /* Recurse on the system instances. */
    for(i=0; i<scope->num_systemIs; ++i) {
        vcd_print_systemI(scope->systemIs[i]);
    }

    /* Recurse on the sub scopes. */
    for(i=0; i<scope->num_scopes; ++i) {
        vcd_print_scope(scope->scopes[i]);
    }

    /* Recurse on the behaviors. */
    for(i=0; i<scope->num_behaviors; ++i) {
        vcd_print_block(scope->behaviors[i]->block);
    }
}


/** Prints the hierarchy of a scope.
 *  @param scope the scope to print. */
static void vcd_print_scope(Scope scope) {
    /* Do not print block with no declaration. */
    if (scope->num_inners == 0 && scope->num_scopes == 0 && scope->num_behaviors == 0) return;
    /* Declares the scope. */
    vcd_print("$scope module ");
    vcd_print_name((Object)scope);
    vcd_print(" $end\n");

    /* Declares its content. */
    vcd_print_scope_content(scope);

    /* Close the hierarchy. */
    vcd_print("$upscope $end\n");
}


/** Prints the hierarchy content of a system type.
 *  @param system the system to print. */
static void vcd_print_systemT_content(SystemT system) {
    int i;

    /* Declare the inputs of the systems. */
    for(i = 0; i<system->num_inputs; ++i) {
        vcd_print_var(system->inputs[i]);
    }
    /* Declare the outputs of the systems. */
    for(i = 0; i<system->num_outputs; ++i) {
        vcd_print_var(system->outputs[i]);
    }
    /* Declare the inouts of the systems. */
    for(i = 0; i<system->num_inouts; ++i) {
        vcd_print_var(system->inouts[i]);
    }
    /* Recurse on the content of the scope (the scope header is the system).*/
    vcd_print_scope_content(system->scope);
}


/** Prints the hierarchy of a system type.
 *  @param system the system to print. */
static void vcd_print_systemT(SystemT system) {
    /* Declares the module. */
    vcd_print("$scope module ");
    vcd_print_name((Object)system);
    vcd_print(" $end\n");

    /* Declares the content. */
    vcd_print_systemT_content(system);

    /* Close the hierarchy. */
    vcd_print("$upscope $end\n");
}





/* high-end print functions. */

/** Prints the header of the vcd file. */
static void vcd_print_header() {
    /* The date section. */
    vcd_print("$date\n");
    {
        char text[100];
        time_t now = time(NULL);
        struct tm *t = localtime(&now);
        strftime(text, sizeof(text), "%d %m %Y %H:%M", t);
        vcd_print("   %s\n", text);
    }
    vcd_print("$end\n");

    /* The version section. */
    vcd_print("$version\n");
    vcd_print("   Generated from HDLRuby simulator\n");
    vcd_print("$end\n");
    
    /* The comment section. */
    vcd_print("$comment\n");
    vcd_print("   Is it an easter egg?\n");
    vcd_print("$end\n");

    /* The time scale section: for now 1ps only. */
    vcd_print("$timescale 1ps $end\n");

    // /* The scope section: nothing specific. */
    // vcd_print("$scope module logic $end\n");

    // /* The variables declaration. */
    // each_all_signal(&vcd_print_var);

    // /* Ends the declarations. */
    // vcd_print("$upscope $end\n");
    // vcd_print("$enddefinitions $end\n");

    /* The declaration of the hierarchy and the variables
     * from the top system. */
    // printf("top_system=%p\n",top_system);
    vcd_print_systemT(top_system);
    /* Ends the declarations. */
    vcd_print("$enddefinitions $end\n");

    /* Display the initializations. */
    vcd_print("$dumpvars\n");
    each_all_signal(&vcd_print_signal_cvalue);
    vcd_print("$end\n");
}



/* The configuration and initialization of the vcd vizualizer. */


/** Sets up the vcd vizualization engine.
 *  @param name the name of the vizualization. */
extern void init_vcd_visualizer(char* name) {
    /* Open the resulting file with name: <name>.vcd */
    char filename[256];
    strncpy(filename,name,255);
    strncat(filename,".vcd",255);
    vcd_file = fopen(filename,"w");

    /* Initialize the vizualizer printer engine. */
    init_visualizer(&vcd_print_time,
                    &vcd_print_full_name,
                    &vcd_print_value,
                    &vcd_print_signal_fvalue,
                    &default_print_string,
                    &default_print_name,
                    &default_print_value);

    /* Prints the header of the vcd file. */
    vcd_print_header();
}
