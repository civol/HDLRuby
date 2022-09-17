/* Used by the C-Ruby hybrid simulator only. */
#ifdef RCSIM

#include "extconf.h"

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include "hruby_sim.h"


/**
 *  The HDLRuby simulation tree-based calculation engine. 
 **/



/** Calculates a tree expression.
 *  @param expr the expression to execute. */
Value calc_expression(Expression expr) {
    /* The resulting value. */
    Value res = get_value();
    // printf("clac_expression with kind=%d\n",expr->kind);
    /* Depending on the kind of expression. */
    switch(expr->kind) {
        case UNARY:
            {
                Unary uexpr = (Unary)expr;
                res = uexpr->oper(calc_expression(uexpr->child),res);
                break;
            }
        case BINARY:
            {
                Binary bexpr = (Binary)expr;
                res = bexpr->oper(calc_expression(bexpr->left),
                                  calc_expression(bexpr->right),res);
            break;
            }
        case CONCAT:
            {
                Concat cexpr = (Concat)expr;
                /* Calculate the sub expressions. */
                Value values[cexpr->num_exprs];
                for(int i=0; i<cexpr->num_exprs; ++i) {
                    values[i] = calc_expression(cexpr->exprs[i]);
                }
                /* Use them for calculating the concat. */
                res = concat_valueP(cexpr->num_exprs,cexpr->dir,res,values);
                break;
            }
        case CAST:
            {
                Cast cexpr = (Cast)expr;
                res = cast_value(calc_expression(cexpr->child),cexpr->type,res);
                break;
            }
        case REF_OBJECT:
            res = calc_expression((Expression)(((RefObject)expr)->object));
            break;
        case REF_INDEX:
            {
                RefIndex rexpr = (RefIndex)expr;
                /* Compute the index. */
                Value indexV = calc_expression(rexpr->index);
                /* Compute the accessed value. */
                Value value = calc_expression((Expression)(rexpr->ref));
                /* Get its integer index. */
                long long index = value2integer(indexV);
                /* Performs the access. */
                res = read_range(value,index,index,rexpr->ref->type,res);
                break;
            }
        case REF_RANGE: 
            {
                RefRangeE rexpr = (RefRangeE)expr;
                /* Compute the range. */
                Value firstV = calc_expression(rexpr->first);
                Value lastV = calc_expression(rexpr->last);
                /* Compute the accessed value. */
                Value value = calc_expression((Expression)(rexpr->ref));
                /* Get its integer range. */
                long long first = value2integer(firstV);
                long long last = value2integer(lastV);
                /* Performs the access. */
                res = read_range(value,first,last,rexpr->ref->type,res);
                break;
            }
        case REF_CONCAT: 
            {
                RefConcat rexpr = (RefConcat)expr;
                /* Process like a simple concat. */
                /* Calculate the sub expressions. */
                Value values[rexpr->num_refs];
                for(int i=0; i<rexpr->num_refs; ++i) {
                    values[i] = calc_expression((Expression)(rexpr->refs[i]));
                }
                /* Use them for calculating the concat. */
                res = concat_valueP(rexpr->num_refs,rexpr->dir,res,values);
                break;
            }
        case SIGNALI:
            res = calc_expression((Expression)(((SignalI)expr)->c_value));
            break;
        default:
            /* Assume it is a Value. */
            res = (Value)expr;
    }
    free_value();
    return res;
}



/** Executes a statement.
 *  @param stmnt the statement to execute.
 *  @param mode blocking mode: 0: par, 1:seq
 *  @param behavior the behavior in execution. */
void execute_statement(Statement stmnt, int mode, Behavior behavior) {
    /* Depending on the kind of statement. */
    // printf("Executing statement=%p with kind=%d\n",stmnt,stmnt->kind);fflush(stdout);
    switch(stmnt->kind) {
        case TRANSMIT: 
            {
                Transmit trans = (Transmit)stmnt;
                // printf("trans=%p trans->left=%p trans->left->kind=%d\n",trans,trans->left,trans->left->kind);
                /* Compute the right value. */
                Value right = calc_expression(trans->right);
                // printf("right=%p mode=%d\n",right,mode);
                /* Depending on the left value. */
                switch (trans->left->kind) {
                    case SIGNALI:
                        /* Simple transmission. */
                        if (mode)
                            transmit_to_signal_seq(right,(SignalI)(trans->left));
                        else 
                            transmit_to_signal(right,(SignalI)(trans->left));
                        break;
                    case REF_INDEX:
                        {
                            /* Transmission to sub element. */
                            RefIndex refi = (RefIndex)(trans->left);
                            /* Compute the index. */
                            Value indexV = calc_expression(refi->index);
                            long long index = value2integer(indexV);
                            /* Generate the reference inside the left value. */
                            RefRangeS ref = 
                                make_ref_rangeS((SignalI)(refi->ref),refi->type,
                                    index,index);
                            /* Perform the transmit. */
                            if(mode)
                                transmit_to_signal_range_seq(right,ref);
                            else
                                transmit_to_signal_range(right,ref);
                            break;
                        }
                    case REF_RANGE: 
                        {
                            /* Transmission to range of sub elements. */
                            RefRangeE refr = (RefRangeE)(trans->left);
                            /* Compute the range. */
                            Value firstV = calc_expression(refr->first);
                            long long first = value2integer(firstV);
                            Value lastV = calc_expression(refr->last);
                            long long last = value2integer(lastV);
                            /* Generate the reference inside the left value. */
                            RefRangeS ref = 
                                make_ref_rangeS((SignalI)(refr->ref),refr->type,
                                    first,last);
                            /* Perform the transmit. */
                            if(mode)
                                transmit_to_signal_range_seq(right,ref);
                            else
                                transmit_to_signal_range(right,ref);
                            break;
                        }
                    case REF_CONCAT:
                        {
                            /* Transmit to each sub-reference. */
                            RefConcat refc = (RefConcat)(trans->left);
                            /* For that purpose use a temporary Transmit node. */
                            TransmitS subtrans = { TRANSMIT, NULL, NULL };
                            long long pos=0; /* The current position in the value
                                                to assign */
                            /* For each sub reference. */
                            for(int i=0; i < refc->num_refs; ++i) {
                                /* Set up the transmit. */
                                subtrans.left = refc->refs[i];
                                long long size = type_width(subtrans.left->type);
                                subtrans.right = (Expression)get_value();
                                subtrans.right = (Expression)read_range(
                                        right,pos,pos+size-1,
                                        get_type_bit(),(Value)(subtrans.right));
                                /* Execute it. */
                                execute_statement((Statement)&subtrans,
                                        mode,behavior);
                                /* Prepare the next step. */
                                free_value();
                                pos += size;
                            }
                        }
                    default:
                        perror("Invalid kind for a reference.");
                }
                break;
            }
        case HIF:
            {
                HIf hif = (HIf)stmnt;
                /* Calculation the condition. */
                Value condition = calc_expression(hif->condition);
                /* Is it true? */
                if (is_defined_value(condition) && value2integer(condition)) {
                    /* Yes, execute the yes branch. */
                    execute_statement(hif->yes,mode,behavior);
                } else {
                    /* No, maybe an alternate condition is met. */
                    int met = 0;/* Tell if an alternate condition has been met.*/
                    for(int i=0; i<hif->num_noifs; ++i) {
                        Value subcond = calc_expression(hif->noconds[i]);
                        if (is_defined_value(subcond) && value2integer(subcond)){
                            /* The subcondition is met, execute the corresponding
                             * substatement. */
                            execute_statement(hif->nostmnts[i],mode,behavior);
                            /* And remember it. */
                            met = 1;
                            break;
                        }
                    }
                    /* Where there a sub condition met? */
                    if (!met) {
                        /* No, execute the no statement. */
                        execute_statement(hif->no,mode,behavior);
                    }
                }
                break;
            }
        case HCASE:
            {
                HCase hcase = (HCase)stmnt;
                /* Calculation the value to check. */
                Value value = calc_expression(hcase->value);
                /* Tell if a case if matched. */
                int met = 0;
                /* Check each case. */
                Value cmp = get_value();
                for(int i=0; i<hcase->num_whens; ++i) {
                    cmp = equal_value_c(value,calc_expression(hcase->matches[i]),
                            cmp);
                    if (is_defined_value(cmp) && value2integer(cmp)) {
                        /* Found the right case, execute the corresponding
                         * statement. */
                        execute_statement(hcase->stmnts[i],mode,behavior);
                        /* And remeber it. */
                        met = 1;
                        break;
                    }
                }
                free_value();
                /* Was no case found and is there a default statement? */
                if (!met && hcase->defolt) {
                    /* Yes, execute the default statement. */
                    execute_statement(hcase->defolt,mode,behavior);
                }
                break;
            }
        case TIME_WAIT:
            {
                /* Get the value of the delay. */
                long long delay = ((TimeWait)stmnt)->delay;
                /* Wait the given delay. */
                hw_wait(delay,behavior);
                break;
            }
        case BLOCK:
            {
                Block block = (Block)stmnt;
                /* Execute each statement of the block. */
                for(int i=0; i<block->num_stmnts; ++i)
                    execute_statement(block->stmnts[i],block->mode,behavior);
                break;
            }

        default:
            perror("Invalid kind for an expression."); 
    }
}

#endif
