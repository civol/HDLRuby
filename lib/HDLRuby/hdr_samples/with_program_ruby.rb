
# A benchmark for testing the use of Ruby software code.
system :with_ruby_prog do
    inner :clk
    [8].inner :count, :echo

    clkR = clk
    countR = count
    echoR = echo

    program(:ruby,:echo) do
        actport clkR.posedge
        inport  inP: countR
        outport outP: echoR
        code "echo.rb"
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
