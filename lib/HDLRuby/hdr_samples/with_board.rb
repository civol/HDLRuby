
# A benchmark for testing the use of a board model implementing:
# * a simple adder whose input are set using slide switches, and
#   whose output bits are showns on LEDs.
# * simple unsigned and signed counters whose values are shown using
#   decimal or hexadecimal displays, and oscilloscopes.
system :with_board do
    inner :clk, :clk2
    [8].inner clk_cnt: 0
    inner rst: 0
    [8].inner :sw_a, :sw_b
    [9].inner :led_z
    [8].inner :expr, :show
    [16].inner counter: 0
    [8].inner :counter8
    signed[8].inner :scounter8

    bit[8][-256].inner :mem
    [8].inner :addr, :din, :dout

    mem[addr] <= din
    dout <= mem[addr]

    # Description of the board.
    # It is updated at each rising edge of +clk2+.
    board(:some_board) do
        actport clk2.posedge
        bt  reset:    rst
        hook sw_ai: sw_a
        hook sw_bi: sw_b
        row
        sw  sw_a:     sw_a
        slider sw_b:  sw_b
        led led_z:    led_z
        row
        text expr:    expr
        digit show:   show
        row
        text addr:    addr
        hexa dout:    dout
        text din:     din
        row
        digit cnt_d:  counter
        hexa  cnt_h:  counter
        digit cnt_s:  scounter8
        row
        scope scope:  counter8
        scope scope_s:scounter8
    end

    # The adder.
    led_z <= sw_a.as(bit[9]) + sw_b

    # The text input and result.
    show <= expr

    # The counters and the generation of +clk2+.
    counter8 <= counter[7..0]
    scounter8 <= counter[7..0]

    seq(clk.posedge) do
      hif(rst) { counter <= 0 }
      helse { counter <= counter + 1 }
      clk_cnt <= clk_cnt + 1
      hif(clk_cnt & 3 == 0) { clk2 <= ~clk2 }
    end



    timed do
        clk <= 0
        clk2 <= 0
        !10.ns
        repeat(10000) do
            clk <= 1
            !10.ns
            clk <= 0
            !10.ns
        end

    end
end
