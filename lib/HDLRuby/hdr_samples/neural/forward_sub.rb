require "./forward.rb"
require "./sigmoid.rb"

##
# A fully specified forward module with 8.24-bit fixed point computation
# and 4.4bit table-based sigmoid activation function.
# Structure: 2 inputs, one 3-column hidden layer and 2 outputs.

system :forward_sub, forward(
    signed[31..0],   # Data type
    [2,3,2], # NN structure
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
    [
        # Second column
        [_shFF000000, _shFF000000, _shFF000000],
        # Third column
        [_shFF000000, _shFF000000]
    ],
    # Weights initial values
    [
        # Second column
        [
            # First neuron
            [ _sh00199999, _sh00666666 ],
            # Second neuron
            [ _sh004CCCCC, _sh00800000 ],
            # Third neuron
            [ _sh00999999, _sh00199999 ]
        ],
        # Third column
        [
            # First neuron
            [ _sh00B33333, _sh00333333, _sh0014CCCC ],
            # Second neuron
            [ _sh00333333, _sh00800000, _sh01199999 ]
        ]
    ],
    # The activation function.
    proc{|addr| sigmoid(8,4,32,24,addr)},
    # The sum of production function.
    proc do |xs,ws|
        (xs.zip(ws).map { |x,w| x*w }.reduce(:+))[27..20]
    end
) do
end

