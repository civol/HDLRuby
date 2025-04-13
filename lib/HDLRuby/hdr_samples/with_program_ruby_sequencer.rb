
# A benchmark for testing the use of Ruby software code including a
# sequencer.
#
system :with_ruby_prog_seq do
    inner :clk
    [8].inner :count, :echo

    program(:ruby,:echo) do
        actport clk.posedge
        inport  inP: count
        outport outP: echo
        code(proc do
          activate_sequencer_sw(binding)

          $my_seq = nil

          def echo
            unless $my_seq then
              [32].input :inP
              [32].output :outP
              $my_seq = sequencer do
                sloop do
                  outP <= inP
                  sync
                end
              end
            end
            $my_seq.()
          end
        end)
    end


    timed do
        clk <= 0
        count <= 0
        !10.ns
        repeat(10) do
            clk <= 1
            hprint("echo=",echo,"\n")
            !10.ns
            count <= count + 1
            clk <= 0
            !10.ns
        end

    end
end
