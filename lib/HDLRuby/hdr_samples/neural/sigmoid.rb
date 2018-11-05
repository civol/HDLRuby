def sigmoid(a_width, a_point, d_width, d_point, addr)
   # Initialize the result to force it as a ruby variable.
    High.cur_system.open do
      sub do
         # Generates the rom
         [d_width].inner :contents
         contents <= (2**a_width).times.map do |i|
            # Converts i to a float
            i = i.to_f * 2**(-a_point)
            # Compute the sigmoid
            sigm = (1.0 / (1+Math.exp(i)))
            # Convert it to fixed point
            (sigm * 2**d_point).to_i
         end

         # Use it for the access
         contents[addr[(a_point+d_width-1-d_point)..a_point-d_point]]
      end
   end
end
