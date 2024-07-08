
# A benchmark for testing the use of a board model implementing:
# * a simple NAND whose input are set using slide switches, and
#   whose output bits are showns on LEDs and an oscilloscope.
system :nand_board do
    [8].input :din0, :din1
    [8].output :dout

    dout <= ~(din0 & din1)

    inner :clk
    # Description of the board.
<<<<<<< HEAD
    # It is updated at each rising edge of +clk2+.
=======
    # It is updated at each rising edge of +clk+.
>>>>>>> 0ce41ea (Fixed hdef and verilog generation of reference to signals of sub-blocks.)
    board(:nand,8080) do
        actport clk.posedge
        sw din0: din0
        sw din1: din1
        row
        led dout: dout
        row
        scope doutS: dout
    end

    timed do
        clk <= 0
        !10.ns
        repeat(2000) do
            clk <= ~clk
            !10.ns
        end
    end
end
