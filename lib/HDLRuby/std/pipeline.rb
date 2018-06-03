module HDLRuby::High::Std

##
# Standard HDLRuby::High library: pipeline generator
# 
########################################################################


    ##
    #  Factory for a pipeline architecture.
    class Pipeline
        High = HDLRuby::High

        # Creates a delay systemI for a signal with +type+.
        def self.make_delay(type)
            systemT = High::SystemT.new(High.uniq_name) do
                type.input :i
                type.output :o
                o <= i
            end
            # return High::SystemI.new(High.uniq_name,systemT)
            res = systemT.instantiate(High.uniq_name)
            High.cur_system.add_systemI(res)
            res
        end

        ## Class describing a wrapper for inserting a component in the
        # pipeline.
        class Wrapper
            # The wrapped component
            attr_reader :component

            # The stage number
            attr_reader :stage

            # Creates a new wrapper for +component+ in pipeline +pipe+ at
            # stage number +n+.
            def initialize(pipe,component,n)
                # Sets the pipeline factory.
                @pipeline = pipe
                # Sets the component.
                @component = component
                # Sets the stage
                @stage = n
                # Initialize the pipeline register as an empty array.
                @register = []
            end

            # Connects +src+ signal to +dst+ signal through the pipeline.
            def connect(src,dst)
                # Ensure dst is valid.
                # puts "@component=#{@component}"
                # puts "#src=#{src}, dst=#{dst}"
                # unless @component.each_input.include?(dst) then
                #     raise "#{dst} is not an input signal of #{@component}"
                # end
                unless dst.parent == @component or
                       # dst.object.parent == @component then
                        dst.base.object == @component then
                    # puts "dst.parent = #{dst.parent}"
                    # puts "dst.base = #{dst.base}"
                    raise "#{dst} is not a signal of #{@component}"
                end
                # Allocates the signal in the pipeline register.
                @register << @pipeline.block.add_inner(
                               SignalI.new(High.uniq_name,src.type,:inner))
                # Connect src to it
                @pipeline.block.add_statement(
                    Transmit.new(@register.last.to_ref,src.to_expr) )
                # Connect it to dst
                @pipeline.block.add_statement(
                    Transmit.new(dst.to_ref,@register.last.to_expr) )
            end 
        end


        # The name of the pipeline factory
        attr_reader :name

        # Creates a new pipeline factory named +name+ synchronized on +clk+
        # and reset on +rst+.
        def initialize(name,clk,rst)
            # Set the name as a symbol.
            @name = name.to_sym

            # Check and set the synchornization event.
            @clk = clk.to_event
            # Check and set the reset event.
            @rst = rst.to_event

            # Create the behavior controlling the pipeline.
            @behavior = High::Behavior.new(:par,@clk,@rst) {}
            # Add it to the current scope.
            High.cur_system.add_behavior(@behavior)

            # Initialize the stages of the pipeline.
            @stages = []

            # Generates the function for setting up the pipeline.
            obj = self # For using the right self within the proc
            High.space_reg(@name) do |*args|
                # If no name it is actually an access to the system type.
                return obj if args.empty?
                # Otherwise use the call method for setting the pipeline.
                obj.call(*args)
            end
        end

        # Gets the depths of the pipeline.
        def depth
            return @stages.size
        end

        # Gets the block containing the control of the pipeline.
        def block
            return @behavior.block
        end

        # Adds components in the pipeline.
        # There are two possible format (number is the stage number):
        #
        # - component, number
        # - { component => number, ... }
        def add(*args)
            # Process the arguments
            if args.size > 1 then
                # Format 0, convert to format 1
                args = { args[0] => args[1] }
            else
                args = args[0]
            end

            # Add the components.
            args.each do |component, number|
                # puts "Adding #{component} at #{number}"
                # Adjust the depth of the pipeline if required.
                if self.depth <= number then
                    @stages.fill(self.depth..number) { Array.new }
                end
                # Wraps and adds the component.
                @stages[number] << Wrapper.new(self,component,number)
            end
        end

        # Get a wrapper by component if any.
        def get_wrapper(obj)
            # Get the wrapper if any.
            @stages.each do |stage|
                found = stage.detect { |wrp| wrp.component == obj }
                return found if found
            end
            # No wrapper found
            return nil
        end

        # Connect signals +dst+ and +src+ among the pipeline.
        #
        # There are two possible format (number is the stage number):
        #
        # - src, dst
        # - { src => dst, ... }
        #
        # NOTE: performs dst <= src while ensuring the pipeline
        # synchronization is valid.
        def connect(*args)
            # Process the arguments
            if args.size > 1 then
                # Format 0, convert to format 1
                args = { args[0] => args[1] }
            else
                args = args[0]
            end

            # Add the connections.
            args.each do |src,dst|
                # Get the real source and destination.
                # Ensure to get the real source and destination.
                src_obj = src.is_a?(RefObject) ? src.object : src
                dst_obj = dst.is_a?(RefObject) ? dst.object : dst
                # puts "src_obj=#{src_obj.name}, src_obj.parent=#{src_obj.parent}"
                # puts "dst_obj=#{dst_obj.name}, dst_obj.parent=#{dst_obj.parent}"
                # Get the wrapper containing the source signal if any
                src_wrp = self.get_wrapper(src_obj.parent)
                # Get the wrapper containing the destination signal if any
                dst_wrp = self.get_wrapper(dst_obj.parent)

                # Get the stages of the signals if any (within the pipeline).
                dst_stg = dst_wrp && dst_wrp.stage
                src_stg = src_wrp && src_wrp.stage

                # Inner connection?
                # if dst_stg and src_stg then
                if dst_stg then
                    src_stg = -1 unless src_stg # Extern connection to inner stage
                    # Yes, connect after inserting delays if dst_stg > src_stg+1
                    while dst_stg > src_stg+1 do
                        # Creates the delay systemI
                        delay = Pipeline.make_delay(src.type)
                        # Add it to the pipeline
                        # wrp = self.add_delay(delay,src_stg+1)
                        self.add(delay,src_stg+1)
                        wrp = self.get_wrapper(delay)
                        # Connect it
                        wrp.connect(src,delay.i)
                        # Prepare the connect to the next stage
                        src_stg += 1
                        src = delay.o
                    end
                    dst_wrp.connect(src,dst)
                # elsif dst_stg then
                #     # No, but it is a connection to one component of the
                #     # pipeline, insert delay until its stage is reached.
                #     dst_wrp.connect(src,dst)
                elsif src_stg then
                    # No, but it is a connection from one component of the
                    # pipeline.
                    # puts "self.block=#{self.block}"
                    self.block.add_statement(
                        Transmit.new(dst.to_ref,src.to_ref) )
                else
                    # No and the pipeline is not related to the signals, error.
                    raise "Signals #{dst} and #{src} are not related to pipeline #{self}"
                end
            end
        end
    end



    # Declares a pipeline factory named +name+ synchronised on +clk+ and 
    # reset on +rst+.
    def pipeline(name = :"", clk, rst)
        # Creates the resulting factory.
        result = Pipeline.new(name,clk,rst)
    end

end
