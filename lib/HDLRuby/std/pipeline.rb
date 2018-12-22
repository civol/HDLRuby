
module HDLRuby::High::Std

    ##
    # Standard HDLRuby::High library: pipeline
    # 
    ########################################################################


    ## 
    # Describes a high-level pipeline type.
    class PipelineT
        include HDLRuby::High::HScope_missing

        # The stage class
        class Stage < Array
            attr_accessor :code
        end

        # The pipeline signal generator class
        class PipeSignal
            include HDLRuby::High::HExpression

            attr_reader :name   # The name of the signal to generate
            attr_reader :type   # The type of the signal to generate
            attr_reader :signal # The generated signal

            # Create a new pipeline signal generator with +name+ whose
            # resulting signal is to be added to +scope+.
            def initialize(name,scope)
                @name  = name.to_sym
                @scope = scope
                @type = nil
                @signal = nil
            end

            # Assigns +expr+ to the signal. Is the signal is not generated
            # yet, generate it.
            def <=(expr)
                # Ensures expr is an expression
                expr = expr.to_expr
                # Generate the signal if not existant
                # puts "@scope=#{@scope}"
                puts "For @name=#{@name} @signal=#{@signal}"
                @signal = @scope.make_inners(expr.type,@name) unless @signal
                # Performs the assignment.
                @signal <= expr
            end

            # Converts to an expression.
            def to_expr
                return @signal.to_expr
            end

            # Converts to a reference.
            def to_ref
                return @signal.to_ref
            end

            # # The HDLRuby operators on expressions.
            # HDLRuby::High::Operators.each do |op|
            #     define_method(op) do |val|
            #         self.to_expr.send(op,val)
            #     end
            # end
        end

        # The name of the pipeline type.
        attr_reader :name

        # The namespace associated with the pipeline
        attr_reader :namespace

        # Creates a new pipeline type with +name+.
        #
        # The proc +ruby_block+ is executed when instantiating the fsm.
        def initialize(name)
            # Check and set the name
            @name = name.to_sym

            # Initialize the internals of the pipeline.


            # Initialize the environment for building the pipeline

            # The stages
            @stages = []

            # The event synchronizing the pipeline
            @mk_ev = proc { $clk.posedge }

            # The reset
            @mk_rst = proc { $rst }

            # Creates the namespace to execute the pipeline block in.
            @namespace = Namespace.new(self)

            # Generates the function for setting up the pipeline.
            obj = self # For using the right self within the proc
            HDLRuby::High.space_reg(@name) do |&ruby_block|
                if ruby_block then
                    # Builds the pipeline.
                    obj.build(&ruby_block)
                else
                    # Return the pipeline as is.
                    return obj
                end
            end

        end

        ## builds the pipeline by executing +ruby_block+.
        def build(&ruby_block)
            # Use local variable for accessing the attribute since they will
            # be hidden when opening the sytem.
            name      = @name
            stages    = @stages
            namespace = @namespace
            this      = self
            mk_ev     = @mk_ev
            mk_rst    = @mk_rst
            scope     = HDLRuby::High.cur_system.scope

            return_value = nil

            # Enters the current system
            HDLRuby::High.cur_system.open do
                sub do
                    HDLRuby::High.space_push(namespace)
                    # Execute the instantiation block
                    return_value =HDLRuby::High.top_user.instance_exec(&ruby_block)
                    HDLRuby::High.space_pop

                    # Create the pipeline code.
                    
                    # Declare and register the pipeline registers generators.
                    prs = []
                    stages.each do |st|
                        st.each do |rn|
                            r = PipeSignal.new(name.to_s+"::"+rn.to_s,scope)
                            prs << r
                            namespace.add_method(rn) { r }
                        end
                    end

                    # Build the pipeline structure.
                    return_value = par(mk_ev.call) do
                        hif(mk_rst.call == 0) do
                            # No reset, pipeline handling.
                            stages.each do |st|
                                # Generate the code for the stage.
                                HDLRuby::High.space_push(namespace)
                                HDLRuby::High.top_user.instance_exec(&st.code)
                                HDLRuby::High.space_pop
                            end
                        end
                        helse do
                            prs.each { |r| r <= 0 }
                        end
                    end
                end
            end

            return return_value
        end

        ## The interface for building the pipeline

        # Sets the event synchronizing the pipeline.
        def for_event(event = nil,&ruby_block)
            if event then
                # An event is passed as argument, use it.
                @mk_ev = proc { event.to_event }
            else
                # No event given, use the ruby_block as event generator.
                @mk_ev = ruby_block
            end
        end

        # Sets the reset.
        def for_reset(reset = nil,&ruby_block)
            if reset then
                # An reset is passed as argument, use it.
                @mk_rst = proc { reset.to_expr }
            else
                # No reset given, use the ruby_block as event generator.
                @mk_rst = ruby_block
            end
        end


        # Declare a new stage synchronized on registers declared in +regs+
        # and executing +ruby_block+.
        def stage(*regs, &ruby_block)
            # Create the resulting state
            result = Stage.new
            # Test and set the registers.
            regs.each do |reg|
                # Ensure it is a symbol.
                reg = reg.to_sym
                # Add it.
                result << reg
            end
            # Sets the generation code.
            result.code = ruby_block
            # Add it to the list of states.
            @stages << result
            # Return it.
            return result
        end

    end


    ## Declare a new pipeline with +name+.
    def pipeline(name)
        return PipelineT.new(name)
    end

end
