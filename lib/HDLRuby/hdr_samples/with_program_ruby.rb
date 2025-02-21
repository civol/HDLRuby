
# A benchmark for testing the use of Ruby software code.
system :with_ruby_prog do
    inner :clk
    [8].inner :count, :echo

    program(:ruby,:echo) do
        actport clk.posedge
        inport  inP: count
        outport outP: echo
        # code "ruby_program/echo.rb"
        code(proc do
          def echo
            val = RubyHDL.inP
            puts "Echoing: #{val}"
            RubyHDL.outP = val    
          end
        end)
    end


    timed do
        clk <= 0
        count <= 0
        !10.ns
        repeat(10) do
            clk <= 1
            !10.ns
            count <= count + 1
            clk <= 0
            !10.ns
        end

    end
end
