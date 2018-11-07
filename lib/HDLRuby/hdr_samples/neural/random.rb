# Generate a +width+ bit (signed) random value.
def rand_signed(width)
    :"_s#{width.times.map { Random.rand(0..1).to_s }.join }".to_expr
end

# Generates a N-dimension array described by +geometry+ filled
# with +width+ bit values.
def rand_array(geometry,width)
    if geometry.is_a?(Array) then
        # Geometry is hierarchical, recurse on it.
        return geometry.map {|elem| rand_array(elem,width) }
    else
        # Geometry is a size of a 1-D array, generate it.
        return geometry.times.map { |i| rand_signed(width) }
    end
end

# rand_array(4,6).each do |v|
#     puts v.content
# end
# 
# system :test do
# end
