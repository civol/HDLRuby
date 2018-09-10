# A simple generic multiplier
system :multer do |i0,i1,o|
    [(i0-1)..0].input :x
    [(i1-1)..0].input :y
    [(o-1)..0].output :s

    s <= x * y
end
