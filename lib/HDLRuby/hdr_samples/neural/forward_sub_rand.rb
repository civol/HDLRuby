require "./forward.rb"
require "./sigmoid.rb"
require "./random.rb"

##
# A fully specified forward module with 8.24-bit fixed point computation
# and 4.4bit table-based sigmoid activation function.
# Structure: 2 inputs, one 3-column hidden layer and 2 outputs.

system :forward_sub, forward(
    signed[31..0],   # Data type
    [2,4,3,2], # NN structure
    [
        # Input samples.
          # First input.
        [[_sh08000000, _sh08000000, _sh05000000, _sh05000000, 
          *([_sh00000000]*28)],
          # Second input.
         [_sh08000000, _sh05000000, _sh08000000, _sh05000000,
          *([_sh00000000]*28)]],
        # Expected outputs
          # First output
        [[_sh01000000, _sh00000000, _sh00000000, _sh00000000, 
          *([_sh00000000]*28)],
          # Second output
         [_sh00000000, _sh01000000, _sh01000000, _sh01000000,
          *([_sh00000000]*28)]]
    ],
    # Biases initial values
    rand_array([4,3,2],32),
    # Weights initial values
    rand_array([[2,2,2,2],[4,4,4],[3,3]],32),
    # The activation function.
    proc{|addr| sigmoid(8,4,32,24,addr)},
    # The sum of production function.
    proc do |xs,ws|
        (xs.zip(ws).map { |x,w| x*w }.reduce(:+))[27..20]
    end
) do
end

