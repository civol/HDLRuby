require 'std/task.rb'



##
# Standard HDLRuby::High library: loops encapsulated in tasks.
# 
########################################################################

## While loop: loops until +condition+ is met execution +ruby_block+.
#  The loop is synchronized on +clk_e+ and initialized by +init+.
#  If +condition+ is nil, then +init+ is used as +condition+.
HDLRuby::High::Std.task(:while_task) do |clk_e, init, condition, ruby_block|
    # Ensure clk_e is an event, if not set it to a positive edge.
    clk_e = clk_e.posedge unless clk_e.is_a?(Event)

    # Ensures there is a condition.
    unless condition then
        condition = init
        init = nil
    end

    # Transform condition into a proc if it is not the case.
    unless condition.is_a?(Proc) then
        condition_expr = condition
        condition = proc { condition_expr }
    end

    # Transform init into a proc if any.
    init = proc { init } unless (init.is_a?(Proc) || init == nil)

    # Declares the signals for controlling the loop.
    inner :req  # Signal to set to 1 for running the loop.
    inner :ack  # Signal set to 1 by the loop when over.

    # Declares the runner signals.
    runner_output :req
    # Declares the finisher signals.
    finisher_input :ack

    par(clk_e) do
        ack <= 0
        # Performs the loop.
        hif(req) do
            # By default the loop is not finished.
            # If the condition is still met go on looping.
            hif(condition.call,&ruby_block)
            # No, ends the loop.
            helse { ack <= 1 }
        end
        if (init) then
            # There is an initialization, do it when there is no req.
            helse do
                init.call
            end
        end
    end

    # The code for running the task.
    runner do
        top_block.unshift { req <= 0 }
        req <= 1
    end

    # The code for checking the end of execution.
    finisher do |blk|
        hif(ack,&blk) 
    end

end



## A simplified loop: loops until +condition+ is met execution +ruby_block+.
#  The loop is synchronized on +clk_e+ and initialized by +init+.
#  If +condition+ is nil, then +init+ is used as +condition+.
def while_loop(clk_e, init, condition = nil, &ruby_block)
    # Create the loop task.
    tsk = while_task(clk_e,init,condition,ruby_block).(HDLRuby.uniq_name)
    # Create the inner access port.
    prt = tsk.inner HDLRuby.uniq_name
    # Return the access port.
    return prt
end
