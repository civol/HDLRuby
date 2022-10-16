#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <pthread.h>

#include "hruby_sim.h"


/**
 *  The HDLRuby simulation core, to be used with C code generated by
 *  hruby_low2c. 
 *  */

/** The top system. */
SystemT top_system;

/** The number of all the signals. */
static int num_all_signals = 0;
/** The capacity of the set of signals. */
static int cap_all_signals = 0;
/** The set of all the signals. */
static SignalI* all_signals = NULL;

/** The list of touched signals. */
static ListS touched_signals_content = { NULL, NULL };
static List touched_signals = &touched_signals_content;

/** The list of touched signals in the sequential execution model. */
static ListS touched_signals_seq_content = { NULL, NULL };
static List touched_signals_seq = &touched_signals_seq_content;


/** The list of activated code. */
static ListS activate_codes_content = { NULL, NULL }; 
static List activate_codes = &activate_codes_content;

/** The number of timed behaviors. */
static int num_timed_behaviors = 0;
/** The capacity of the timed behaviors. */
static int cap_timed_behaviors = 0;
/** The timed behaviors. */
static Behavior* timed_behaviors = NULL;

/** The number of running behaviors. */
static int num_run_behaviors = 0;
/** The number of activated behaviors. */
static int num_active_behaviors = 0;

/** Flag saying the behaviors can run. */
static int behaviors_can_run = 0;

/** The current simulation time. */
static unsigned long long hruby_sim_time = 0;

/** The mutex for accessing the simulator ressources. */
static pthread_mutex_t hruby_sim_mutex = PTHREAD_MUTEX_INITIALIZER;

/** The condition the behaviors wait on. */
static pthread_cond_t hruby_beh_cond = PTHREAD_COND_INITIALIZER;
/** The condition the simulator waits on. */
static pthread_cond_t hruby_sim_cond = PTHREAD_COND_INITIALIZER;

/** Flags for the simulation. */
static int sim_single_flag = 0; /* Run in single timed behavior mode. */
static int sim_end_flag = 0;    /* Ending the simulation. */

/** Adds a timed behavior for processing. 
 *  @param behavior the timed behavior to register */
void register_timed_behavior(Behavior behavior) {
    // printf("Registering timed behavior=%p\n",behavior);fflush(stdout);
    if (num_timed_behaviors == cap_timed_behaviors) {
        if (cap_timed_behaviors == 0) {
            /* Need to create the array containing the timed behaviors. */
            cap_timed_behaviors = 5;
            timed_behaviors = calloc(cap_timed_behaviors,sizeof(Behavior));
        } else {
            /* Need to increase the capacity. */
            Behavior* behaviors = calloc(cap_timed_behaviors*2,sizeof(Behavior));
            // memcpy(behaviors,timed_behaviors,sizeof(Behavior)*cap_timed_behaviors);
            memcpy(behaviors,timed_behaviors,sizeof(Behavior[cap_timed_behaviors]));
            timed_behaviors = behaviors;
            cap_timed_behaviors *= 2;
        }
    }
    /* Add the behavior. */
    timed_behaviors[num_timed_behaviors++] = behavior;
}


/** Adds a signal for global processing. 
 *  @param signal the signal to register  */
void register_signal(SignalI signal) {
    if (num_all_signals == cap_all_signals) {
        if (cap_all_signals == 0) {
            /* Need to create the array containing the timed behaviors. */
            cap_all_signals = 100;
            all_signals = calloc(cap_all_signals,sizeof(SignalI));
        } else {
            /* Need to increase the capacity. */
            SignalI* new_signals = calloc(cap_all_signals*2,sizeof(SignalI));
            // memcpy(new_signals,all_signals,sizeof(SignalI)*cap_all_signals);
            memcpy(new_signals,all_signals,sizeof(SignalI[cap_all_signals]));
            cap_all_signals *= 2;
            all_signals=new_signals;
        }
    }
    /* Add the signal. */
    all_signals[num_all_signals++] = signal;
}


/** Recursively update the signals until no (untimed) behavior are
 *  activated. */
void hruby_sim_update_signals() {
    // printf("hruby_sim_update_signals...\n");fflush(stdout);
    /* As long as the list of touched signals is not empty go on computing. */
    while(!empty_list(touched_signals) || !empty_list(touched_signals_seq)) {
        // printf("## Checking touched signals.\n");fflush(stdout);
        /* Sets the new signals values and mark the signals as activating. */
        /* For the case of the parallel execution model. */
        while(!empty_list(touched_signals)) {
            Elem e = remove_list(touched_signals);
            SignalI sig = e->data;
            // printf("sig=%p kind=%d\n",sig,sig->kind);fflush(stdout);
            delete_element(e);
            /* Is there a change? */
            if (same_content_value(sig->c_value,sig->f_value)) continue;
            /* Yes, process the signal. */
            printer.print_signal(sig);
            // printf("c_value="); printer.print_value(sig->c_value);
            // printf("\nf_value="); printer.print_value(sig->f_value); printf("\n");
            // printf("Touched signal: %p (%s)\n",sig,sig->name);fflush(stdout);
            /* Update the current value of the signal. */
            copy_value(sig->f_value,sig->c_value);
            // /* Mark the signal as activated. */
            // add_list(activate_signals,e);
            /* Mark the corresponding code as activated. */
            /* Any edge activation. */
            int i;
            for(i=0; i<sig->num_any; ++i) {
                Object obj = sig->any[i];
                if (obj->kind == BEHAVIOR) {
                    /* Behavior case. */
                    Behavior beh = (Behavior)obj;
                    beh->activated = 1;
                    add_list(activate_codes,get_element(beh));
                } else {
                    /* Other code case. */
                    Code cod = (Code)obj;
                    cod->activated = 1;
                    add_list(activate_codes,get_element(cod));
                }
            }
            /* Positive edge activation. */
            if (!zero_value(sig->c_value)) {
                // printf("PAR: posedge for sig=%s with num_pos=%i\n",sig->name,sig->num_pos);
                for(i=0; i<sig->num_pos; ++i) {
                    Object obj = sig->pos[i];
                    if (obj->kind == BEHAVIOR) {
                        /* Behavior case. */
                        Behavior beh = (Behavior)obj;
                        // printf("Activating beh=%p.\n",beh);
                        beh->activated = 1;
                        add_list(activate_codes,get_element(beh));
                    } else {
                        /* Other code case. */
                        Code cod = (Code)obj;
                        cod->activated = 1;
                        add_list(activate_codes,get_element(cod));
                    }
                }
            }
            /* Negative edge activation. */
            if (zero_value(sig->c_value)) {
                for(i=0; i<sig->num_neg; ++i) {
                    Object obj = sig->neg[i];
                    if (obj->kind == BEHAVIOR) {
                        /* Behavior case. */
                        Behavior beh = (Behavior)obj;
                        beh->activated = 1;
                        add_list(activate_codes,get_element(beh));
                    } else {
                        /* Other code case. */
                        Code cod = (Code)obj;
                        cod->activated = 1;
                        add_list(activate_codes,get_element(cod));
                    }
                }
            }
        }
        /* And fdor the case of the sequential execution model
         * (no more content check nor update of current value necessary). */
        while(!empty_list(touched_signals_seq)) {
            Elem e = remove_list(touched_signals_seq);
            SignalI sig = e->data;
            delete_element(e);
            /* Yes, process the signal. */
            // println_signal(sig);
            printer.print_signal(sig);
            /* Update the current value of the signal. */
            /* Mark the corresponding code as activated. */
            /* Any edge activation. */
            int i;
            for(i=0; i<sig->num_any; ++i) {
                Object obj = sig->any[i];
                if (obj->kind == BEHAVIOR) {
                    /* Behavior case. */
                    Behavior beh = (Behavior)obj;
                    beh->activated = 1;
                    add_list(activate_codes,get_element(beh));
                } else {
                    /* Other code case. */
                    Code cod = (Code)obj;
                    cod->activated = 1;
                    add_list(activate_codes,get_element(cod));
                }
            }
            /* Positive edge activation. */
            if (!zero_value(sig->c_value)) {
                // printf("SEQ: posedge for sig=%s with num_pos=%i\n",sig->name,sig->num_pos);
                for(i=0; i<sig->num_pos; ++i) {
                    Object obj = sig->pos[i];
                    if (obj->kind == BEHAVIOR) {
                        /* Behavior case. */
                        Behavior beh = (Behavior)obj;
                        beh->activated = 1;
                        add_list(activate_codes,get_element(beh));
                    } else {
                        /* Other code case. */
                        Code cod = (Code)obj;
                        cod->activated = 1;
                        add_list(activate_codes,get_element(cod));
                    }
                }
            }
            /* Negative edge activation. */
            if (zero_value(sig->c_value)) {
                for(i=0; i<sig->num_neg; ++i) {
                    Object obj = sig->neg[i];
                    if (obj->kind == BEHAVIOR) {
                        /* Behavior case. */
                        Behavior beh = (Behavior)obj;
                        beh->activated = 1;
                        add_list(activate_codes,get_element(beh));
                    } else {
                        /* Other code case. */
                        Code cod = (Code)obj;
                        cod->activated = 1;
                        add_list(activate_codes,get_element(cod));
                    }
                }
            }
        }

        // printf("## Checking activate codes.\n");
        /* Execute the behaviors activated by the signals. */
        while(!empty_list(activate_codes)) {
            Elem e = remove_list(activate_codes);
            Object obj = e->data;
            delete_element(e);
            if (obj->kind == BEHAVIOR) {
                /* Behavior case. */
                Behavior beh = (Behavior)obj;
                // printf("beh=%p\n",beh);
                /* Is the code really enabled and activated? */
                if (beh->enabled && beh->activated) {
                    /* Yes, execute it. */
#ifdef RCSIM
                    // printf("going to execute with beh=%p\n",beh);
                    // printf("going to execute: %p with kind=%d\n",beh->block,beh->block->kind);
                    execute_statement((Statement)(beh->block),0,beh);
#else
                    beh->block->function();
#endif
                    /* And deactivate it. */
                    beh->activated = 0;
                }
            } else {
                /* Other code case. */
                Code cod = (Code)obj;
                /* Is the code really activated? */
                if (cod->enabled && cod->activated) {
                    /* Yes, execute it. */
                    cod->function();
                    /* And deactivate it. */
                    cod->activated = 0;
                }
            }
        }
    }
}


/** Advance time to the next time step. */
void hruby_sim_advance_time() {
    /* Collects the activation time of all the timed behaviors and find
     * the shortest one. */
    unsigned long long next_time = ULLONG_MAX;
    int i;
    for(i=0; i<num_timed_behaviors; ++i) {
        unsigned long long beh_time = timed_behaviors[i]->active_time;
        // printf("beh_time=%llu\n",beh_time);
        if (timed_behaviors[i]->timed == 1)
            if (beh_time < next_time) next_time = beh_time;
    }
    /* Mark again all the signals as fading. */
    for(i=0; i<num_all_signals; ++i) all_signals[i]->fading = 1;
    // printf("hruby_sim_time=%llu next_time=%llu\n",hruby_sim_time,next_time);
    /* Sets the new activation time. */
    hruby_sim_time = next_time;
    // println_time(hruby_sim_time);
    printer.print_time(hruby_sim_time);
}


/** Sets the enable status of the behaviors of a scope.
 *  @param scope the scope to process.
 *  @param status the enable status. */
static void set_enable_scope(Scope scope, int status) {
    int i;
    int num_beh = scope->num_behaviors;
    Behavior*  behs = scope->behaviors;
    int num_scp = scope->num_scopes;
    Scope* scps = scope->scopes;

    /* Enable the behaviors. */
    for(i=0; i<num_beh; ++i) {
        behs[i]->enabled = status;
    }

    /* Recurse on the sub scopes. */
    for(i=0; i<num_scp; ++i) {
        set_enable_scope(scps[i],status);
    }
}

/** Sets the enable status of the behaviors of a system type. 
 *  @param systemT the system type to process.
 *  @param status the enable status. */
void set_enable_system(SystemT systemT, int status) {
    set_enable_scope(systemT->scope,status);
}


/** Activates a behavior.
 *  @param behavior the behavior to activate. */
void activate_behavior(Behavior behavior) {

}


/** Activates the timed behavior that have to be activated at this
  * time. */
void hruby_sim_activate_behaviors_on_time() {
    int i;
    pthread_mutex_lock(&hruby_sim_mutex); 
    /* Count the number of behaviors that will be activated. */
    for(i=0; i<num_timed_behaviors; ++i) {
        Behavior beh = timed_behaviors[i];
        // printf("beh->active_time=%llu\n",beh->active_time);
        // if (beh->active_time == hruby_sim_time) {
        if (beh->timed == 1 && beh->active_time == hruby_sim_time) {
            /* Increase the number of timed behavior to wait for. */
            num_active_behaviors ++;
            // printf("num_active_behaviors = %d\n",num_active_behaviors);
        }
    }
    /* Activate the behaviors .*/
    behaviors_can_run = 1;
    // pthread_cond_signal(&compute_cond); /* No behaviors. */
    // pthread_cond_signal(&hruby_beh_cond); 
    pthread_mutex_unlock(&hruby_sim_mutex);
    pthread_cond_broadcast(&hruby_beh_cond); 
}


/** Wait for the active timed behaviors to advance. */
void hruby_sim_wait_behaviors() {
    pthread_mutex_lock(&hruby_sim_mutex);
    while(num_active_behaviors > 0) {
        // printf("num_active_behaviors = %d\n",num_active_behaviors);
        // pthread_cond_wait(&active_behaviors_cond, &hruby_sim_mutex);
        pthread_cond_wait(&hruby_sim_cond, &hruby_sim_mutex);
    }
    behaviors_can_run = 0;
    pthread_mutex_unlock(&hruby_sim_mutex);
}


/** The code for starting a behavior.
 *  @param arg the behavior to execute. */
void* behavior_run(void* arg) {
    Behavior behavior = (Behavior)arg;
    /* First lock the behavior until the simulation engine starts. */
    pthread_mutex_lock(&hruby_sim_mutex);
    num_active_behaviors -= 1;
    while(!behaviors_can_run) {
        // printf("cannot run\n");
        // pthread_cond_wait(&compute_cond, &hruby_sim_mutex);
        pthread_cond_wait(&hruby_beh_cond, &hruby_sim_mutex);
    }
    pthread_mutex_unlock(&hruby_sim_mutex);
    /* Now can start the execution of the behavior. */
    if (behavior->enabled) {
#ifdef RCSIM
        // printf("going to execute with behavior=%p\n",behavior);
        // printf("going to execute: %p with kind=%d\n",behavior->block,behavior->block->kind);
        execute_statement((Statement)(behavior->block),0,behavior);
#else
        behavior->block->function();
#endif
    }
    /* Now can start the execution of the behavior. */
    /* Stops the behavior. */
    pthread_mutex_lock(&hruby_sim_mutex);
    num_active_behaviors -= 1;
    num_run_behaviors -= 1;
    // printf("num_run_behaviors=%d\n",num_run_behaviors);
    behavior->timed = 2;
    // pthread_cond_signal(&hruby_sim_cond);
    pthread_mutex_unlock(&hruby_sim_mutex);
    pthread_cond_signal(&hruby_sim_cond);
    /* End the thread. */
    pthread_exit(NULL);
}

/** Starts a signle timed behavior to run without the multi-threaded engine. */
void hruby_sim_start_single_timed_behavior() {
    int i;
    // printf("hruby_sim_start_single_timed_behaviors\n");fflush(stdout);
    /* Set in mono-thread mode. */
    sim_single_flag = 1;
    Behavior behavior = timed_behaviors[0];
    /* Simply run the timed behavior. */
#ifdef RCSIM
        execute_statement((Statement)(behavior->block),0,behavior);
#else
        behavior->block->function();
#endif
}


/** Starts the timed behaviors.
 *  @note create a thread per timed behavior. */
void hruby_sim_start_timed_behaviors() {
    int i;
    // printf("hruby_sim_start_timed_behaviors\n");fflush(stdout);
    // printf("timed_behaviors=%p\n",timed_behaviors);fflush(stdout);
    pthread_mutex_lock(&hruby_sim_mutex);
    /* Sets the end flags to 0. */
    sim_end_flag = 0;
    /* Tells the behavior can run. */
    behaviors_can_run = 1;
    /* Create and start the threads. */
    for(i=0; i<num_timed_behaviors; ++i) {
        num_run_behaviors += 1;
        pthread_create(&timed_behaviors[i]->thread,NULL,
                       &behavior_run,timed_behaviors[i]);
    }
    pthread_mutex_unlock(&hruby_sim_mutex);
    // exit(0);
}

/** Ends waiting all the threads properly terminates. */
void hruby_sim_end_timed_behaviors() {
    int i;
    /* Sets the end flag to 1. */
    sim_end_flag = 1;
    /* Wait for the threads to terminate. */
    for(i=0; i<num_timed_behaviors; ++i) {
        pthread_join(timed_behaviors[i]->thread,NULL);
    }
}




// /** The simulation core function.
//  *  @param limit the time limit in fs. */
// void hruby_sim_core(unsigned long long limit) {
/** The simulation core function.
 *  @param name the name of the simulation.
 *  @param vizualizer the vizualizer engine initializer.
 *  @param limit the time limit in fs. */
void hruby_sim_core(char* name, void (*init_vizualizer)(char*),
                           unsigned long long limit) {
    /* Initilize the vizualizer. */
    init_vizualizer(name);

    /* Initialize the time to 0. */
    hruby_sim_time = 0;

    if (num_timed_behaviors == 1) {
        /* Initialize and touch all the signals. */
        hruby_sim_update_signals(); 
        each_all_signal(&touch_signal);
        /* Only one timed behavior, no need of the multi-threaded engine. */
        hruby_sim_start_single_timed_behavior();
    } else {
        /* Use the multi-threaded engine. */
        /* Start all the timed behaviors. */
        hruby_sim_start_timed_behaviors();
        // /* Activate the timed behavior that are on time. */
        // hruby_sim_activate_behaviors_on_time();

        /* Run while there are active behaviors and the time limit is not 
         * reached */
        while(hruby_sim_time<limit) {
            int i;
            // printf("num_active_behaviors = %d\n",num_active_behaviors);
            /* Wait for the active timed behaviors to perform their computations. */
            hruby_sim_wait_behaviors();
            /* Update the signal values (recursively executing blocks locked
             * on the signals). */
            hruby_sim_update_signals(); 
            if (hruby_sim_time == 0) {
                /* Initially touch all the signals. */
                each_all_signal(&touch_signal);
            }
            // printf("num_run_behavior=%d\n",num_run_behaviors);
            if (num_run_behaviors <= 0) break;
            /* Advance time to next timestep. */
            hruby_sim_advance_time();

            /* Mark the signals as fading. */
            for(i=0; i<num_all_signals; ++i) {
                all_signals[i]->fading = 1;
            }

            /* Activate the timed behavior that are on time. */
            hruby_sim_activate_behaviors_on_time();
        }
    }
}




/* ##################################################################### */
/* ##                The interface for the HW description.            ## */
/* ##################################################################### */




/** Makes the behavior wait for a given time.
 *  @param delay the delay to wait in ps.
 *  @param behavior the current behavior. */
void hw_wait(unsigned long long delay, Behavior behavior) {
    /* Is it in single timed behavior mode? */
    if (sim_single_flag) {
        /* Yes, simply update signals and advance time. */
        behavior->active_time += delay;
        hruby_sim_update_signals(); 
        hruby_sim_advance_time();
    } else {
        /* No, handle the multi-threading. */
        /* Maybe the thread is to end immediatly. */
        if (sim_end_flag)
            pthread_exit(NULL);
        /* No go on with the wait procedure. */
        pthread_mutex_lock(&hruby_sim_mutex);
        /* Indicate the behavior finished current execution. */
        num_active_behaviors -= 1;
        // printf("!!num_active_behaviors=%d\n",num_active_behaviors);
        // pthread_cond_signal(&hruby_sim_cond);
        /* Update the behavior's time. */
        behavior->active_time += delay;
        pthread_mutex_unlock(&hruby_sim_mutex);
        pthread_cond_signal(&hruby_sim_cond);
        /* Wait for being reactivated. */
        while(behavior->active_time > hruby_sim_time) {
            pthread_mutex_lock(&hruby_sim_mutex);
            while(!behaviors_can_run) {
                // printf("!1\n");
                // pthread_cond_wait(&compute_cond, &hruby_sim_mutex);
                pthread_cond_wait(&hruby_beh_cond, &hruby_sim_mutex);
                // printf("!2\n");
            }
            pthread_mutex_unlock(&hruby_sim_mutex);
        }
    }
}


/** Touch a signal. 
 *  @param signal the signal to touch  */
void touch_signal(SignalI signal) {
    // printf("touching signal: %p\n",signal);
    add_list(touched_signals,get_element(signal));
    // println_signal(signal);
    /* Now the signal is not fading any longer. */
    signal->fading = 0;
}


/** Transmit a value to a signal.
 *  @param value the value to transmit
 *  @param signal the signal to transmit the value to. */
void transmit_to_signal(Value value, SignalI signal) {
    // printf("Tansmit to signal: %s(%p)\n",signal->name,signal);
    /* Copy the content. */
    if (signal->fading)
        signal->f_value = copy_value(value,signal->f_value);
    else
        signal->f_value = copy_value_no_z(value,signal->f_value);
    /* And touch the signal. */
    touch_signal(signal);
}

/** Transmit a value to a range within a signal.
 *  @param value the value to transmit
 *  @param ref the reference to the range in the signal to transmit the
 *         value to. */
void transmit_to_signal_range(Value value, RefRangeS ref) {
    SignalI signal = ref.signal;
    unsigned long long first = ref.first;
    unsigned long long last = ref.last;
    /* The base type is stored here to avoid allocating a new type each time.
     * It have an arbitrary base size a single element. */
    static TypeS baseT = { 1, 1 };
    baseT.base = signal->f_value->type->base;
    // printf("Tansmit to signal range: %s(%p) [%lld:%lld]\n",signal->name,signal,first,last);
    /* Can transmit, copy the content. */
    if (signal->fading)
        signal->f_value = write_range(value,first,last,&baseT,
                signal->f_value);
    else
        signal->f_value = write_range_no_z(value,first,last,&baseT,
                signal->f_value);
    /* And touch the signal. */
    touch_signal(signal);
}



/** Touch a signal in case of sequential execution model. 
 *  @param signal the signal to touch  */
void touch_signal_seq(SignalI signal) {
    // printf("touching signal seq: %p\n",signal);
    // printf("signal->c_value=%p\n",signal->c_value);
    /* Is there a difference between the present and future value? */ 
    if (same_content_value(signal->c_value,signal->f_value)) return;
    /* Yes, add the signal to the list of touched sequential ones and update
     * its current value. */
    add_list(touched_signals_seq,get_element(signal));
    copy_value(signal->f_value,signal->c_value);
    // println_signal(signal);
    /* Now the signal is not fading any longer. */
    signal->fading = 0;
}


/** Transmit a value to a signal in case of a sequential execution model.
 *  @param value the value to transmit
 *  @param signal the signal to transmit the value to. */
void transmit_to_signal_seq(Value value, SignalI signal) {
    // printf("Tansmit to signal seq: %s(%p)\n",signal->name,signal);
    // printf("signal->f_value=%p\n",signal->f_value);
    /* Copy the content. */
    if (signal->fading)
        copy_value(value,signal->f_value);
    else
        copy_value_no_z(value,signal->f_value);
    /* And touch the signal. */
    touch_signal_seq(signal);
}

/** Transmit a value to a range within a signal in case of sequential
 *  execution model.
 *  @param value the value to transmit
 *  @param ref the reference to the range in the signal to transmit the
 *         value to. */
void transmit_to_signal_range_seq(Value value, RefRangeS ref) {
    SignalI signal = ref.signal;
    unsigned long long first = ref.first;
    unsigned long long last = ref.last;
    // printf("Tansmit to signal range: %s(%p) [%llu,%llu]\n",signal->name,signal,first,last);
    /* Can transmit, copy the content. */
    if (signal->fading)
        // write_range(value,first,last,signal->f_value->type,signal->f_value);
        write_range(value,first,last,ref.type,signal->f_value);
    else
        // write_range_no_z(value,first,last,signal->f_value->type,signal->f_value);
        write_range_no_z(value,first,last,ref.type,signal->f_value);
    /* And touch the signal. */
    touch_signal_seq(signal);
}

/** Creates an event.
 *  @param edge the edge of the event
 *  @param signal the signal of the event */
Event make_event(Edge edge, SignalI signal) {
    Event event = malloc(sizeof(EventS));
    event->edge = edge;
    event->signal = signal;

    return event;
}


/** Creates a delay.
 *  Actually generates an unsigned long long giving the corresponding
 *  delay in the base unit of the simulator. 
 *  @param value the value of the delay
 *  @param unit the used unit
 *  @return the result delay in the base unit of the simulator (ns) */
unsigned long long make_delay(int value, Unit unit) {
    switch(unit) {
        case  S: return value * 1000000000000ULL;
        case MS: return value * 1000000000ULL;
        case US: return value * 1000000ULL;
        case NS: return value * 1000ULL;
        case PS: return value * 1ULL;
        default: 
                 perror("Invalid unit for a delay."); 
    }
    return -1;
}




/** Iterates over all the signals.
 *  @param func function to applie on each signal. */
void each_all_signal(void (*func)(SignalI)) {
    int i;
    for(i = 0; i<num_all_signals; ++i) {
        func(all_signals[i]);
    }
}


/** Configure a system instance.
 *  @param systemI the system instance to configure.
 *  @param idx the index of the target system. */
void configure(SystemI systemI, int idx) {
    int i;
    // printf("Configure to: %i\n",idx);
    /* Sets the current system type. */
    systemI->system = systemI->systems[idx];
    /* Disable all the behaviors of the system instance. */
    for(i=0; i<systemI->num_systems; ++i) {
        if (i != idx)
            set_enable_system(systemI->systems[i],0);
    }
    /* Enable the current system. */
    set_enable_system(systemI->systems[idx],1);
}


/** Terminates the simulation. */
void terminate() {
    exit(0);
}
