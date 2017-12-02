########################################################################
##            Program for testing the HDLRuby bit strings.            ##
########################################################################

require "HDLRuby.rb"
require "HDLRuby/hruby_bstr.rb"

include HDLRuby

$success = true

print "\nCreating specificed bit strings... "
begin
    $n0 = BitString.new("00000001",0)    #   1
    # $n0l = [ 0, 0, 0, 0, 0, 0, 0, 0, 1 ].reverse
    $n0n = 1
    $n1 = BitString.new("11111111",1)    #  -1
    # $n1l = [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ].reverse
    $n1n = -1
    $n2 = BitString.new("00000010","0")  #   2
    # $n2l = [ 0, 0, 0, 0, 0, 0, 0, 1, 0 ].reverse
    $n2n = 2
    $n3 = BitString.new("11111110","1")  #  -2
    # $n3l = [ 1, 1, 1, 1, 1, 1, 1, 1, 0 ].reverse
    $n3n = -2
    $n4 = BitString.new("11111111",0)    # 255
    # $n4l = [ 0, 1, 1, 1, 1, 1, 1, 1, 1 ].reverse
    $n4n = 255
    $n5 = BitString.new("11111110",0)    # 254
    # $n5l = [ 0, 1, 1, 1, 1, 1, 1, 1, 0 ].reverse
    $n5n = 254
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end

print "\nCreating bit strings with z states... "
begin
    $z0 = BitString.new("0000000z", 0)   # positive partial z
    # $z0l = [ 0, 0, 0, 0, 0, 0, 0, 0, 2 ].reverse
    $z1 = BitString.new("zzzZZzzz","0")  # positive full z
    # $z1l = [ 0, 2, 2, 2, 2, 2, 2, 2, 2 ].reverse
    $z2 = BitString.new("000000z0", 1)   # negative partial z
    # $z2l = [ 1, 0, 0, 0, 0, 0, 0, 2, 0 ].reverse
    $z3 = BitString.new("zzzzzzzz","1")  # negative full z
    # $z3l = [ 1, 2, 2, 2, 2, 2, 2, 2, 2 ].reverse
    $z4 = BitString.new("00000001","z")  # z sign 1
    # $z4l = [ 2, 0, 0, 0, 0, 0, 0, 0, 1 ].reverse
    $z5 = BitString.new("000000z0","Z")  # z sign partial z
    # $z5l = [ 2, 0, 0, 0, 0, 0, 0, 2, 0 ].reverse
    $z6 = BitString.new("zzzzzzzz", 2)   # z sign full z
    # $z6l = [ 2, 2, 2, 2, 2, 2, 2, 2, 2 ].reverse
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end

print "\nCreating bit strings with x states... "
begin
    $x0 = BitString.new("0000000x", 0)   # positive partial x
    # $x0l = [ 0, 0, 0, 0, 0, 0, 0, 0, 3 ].reverse
    $x1 = BitString.new("xxxXXxxx","0")  # positive full x
    # $x1l = [ 0, 3, 3, 3, 3, 3, 3, 3, 3 ].reverse
    $x2 = BitString.new("000000x0", 1)   # negative partial x
    # $x2l = [ 1, 0, 0, 0, 0, 0, 0, 3, 0 ].reverse
    $x3 = BitString.new("xxxxxxxx","1")  # negative full x
    # $x3l = [ 1, 3, 3, 3, 3, 3, 3, 3, 3 ].reverse
    $x4 = BitString.new("00000001","x")  # x sign 1
    # $x4l = [ 3, 0, 0, 0, 0, 0, 0, 0, 1 ].reverse
    $x5 = BitString.new("000000x0","X")  # x sign partial x
    # $x5l = [ 3, 0, 0, 0, 0, 0, 0, 3, 0 ].reverse
    $x6 = BitString.new("xxxxxxxx", 3)   # x sign full x
    # $x6l = [ 3, 3, 3, 3, 3, 3, 3, 3, 3 ].reverse
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end

print "\nCreating bit strings with x and z states... "
begin
    $m0 = BitString.new("00000z0x", 0)   # positive partial x and z
    # $m0l = [ 0, 0, 0, 0, 0, 0, 2, 0, 3 ].reverse
    $m1 = BitString.new("xZxXXxZx","0")  # positive full x and z
    # $m1l = [ 0, 3, 2, 3, 3, 3, 3, 2, 3 ].reverse
    $m2 = BitString.new("0000X0z0", 1)   # negative partial x and z
    # $m2l = [ 1, 0, 0, 0, 0, 3, 0, 2, 0 ].reverse
    $m3 = BitString.new("xxzzzxzx","1")  # negative full x and z
    # $m3l = [ 1, 3, 3, 2, 2, 2, 3, 2, 3 ].reverse
    $m4 = BitString.new("000z00x0","z")  # z sign partial x and z
    # $m4l = [ 2, 0, 0, 0, 2, 0, 0, 3, 0 ].reverse
    $m5 = BitString.new("000z00x0","X")  # x sign partial x and z
    # $m5l = [ 3, 0, 0, 0, 2, 0, 0, 3, 0 ].reverse
    $m6 = BitString.new("xxxzzzxx", 2)   # z sign full x and z
    # $m6l = [ 2, 3, 3, 3, 2, 2, 2, 3, 3 ].reverse
    $m7 = BitString.new("xxxzzzxx", 3)   # x sign full x and z
    # $m7l = [ 3, 3, 3, 3, 2, 2, 2, 3, 3 ].reverse
    puts "Ok."
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end

# The various combinations of bit strings to test.
Ns  = [ $n0,  $n1,  $n2,  $n3,  $n4,  $n5 ]
# NLs = [ $n0l, $n1l, $n2l, $n3l, $n4l, $n5l ]
NNs = [ $n0n, $n1n, $n2n, $n3n, $n4n, $n5n ]
Zs  = [ $z0,  $z1,  $z2,  $z3,  $z4,  $z5,  $z6 ]
# ZLs = [ $z0l, $z1l, $z2l, $z3l, $z4l, $z5l, $z6l ]
Xs  = [ $x0,  $x1,  $x2,  $x3,  $x4,  $x5,  $x6 ]
# XLs = [ $x0l, $x1l, $x2l, $x3l, $x4l, $x5l, $x6l ]
Ms  = [ $m0,  $m1,  $m2,  $m3,  $m4,  $m5,  $m6,  $m7 ]
# MLs = [ $m0l, $m1l, $m2l, $m3l, $m4l, $m5l, $m6l, $m7l ]

STRs = Ns + Zs + Xs + Ms


# print "\nTesting conversion to list of bits... \n"
# begin
#     STRs.zip(NLs + ZLs + XLs + MLs) do |str,list|
#         print("  #{str} list of bits = #{str.to_list} ... ")
#         if str.to_list == list then
#             puts "Ok."
#         else
#             puts "Error: invalid list of bits, expecting #{list}."
#             $success = false
#         end
#     end
# rescue Exception => e
#     puts "Error: unexpected exception raised ", e, e.backtrace
#     $success = false
# end


print "\nTesting conversion to numeric value... \n"
begin
    Ns.zip(NNs) do |str,num|
        print("  #{str} numeric value = #{str.to_numeric} ... ")
        if str.to_numeric == num then
            puts "Ok."
        else
            puts "Error: invalid numeric value, expecting #{num}."
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
   

print "\nTesting not... \n   "
begin
    STRs.zip( [ "-2", "0", "-3", "1", "-256", "-255",
"11111111x", "1xxxxxxxx", "0111111x1", "0xxxxxxxx", "x11111110", "x111111x1",
"xxxxxxxxx", "11111111x", "1xxxxxxxx", "0111111x1", "0xxxxxxxx", "x11111110",
"x111111x1", "xxxxxxxxx", "111111x1x", "1xxxxxxxx", "01111x1x1", "0xxxxxxxx",
"x111x11x1", "x111x11x1", "xxxxxxxxx", "xxxxxxxxx"
    ]) do |str,res|
        # puts("~#{str} = #{~str} ... "); 
        print "#"
        if (~str).to_s != res then
            print("   \n ~#{str} = #{~str} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end


print "\nTesting and... \n   "
begin
    STRs.product(STRs).zip( [ "1", "1", "0", "0", "1", "0",
"00000000x", "00000000x", "000000000", "00000000x", "000000001", "000000000",
"00000000x", "00000000x", "00000000x", "000000000", "00000000x", "000000001",
"000000000", "00000000x", "00000000x", "00000000x", "000000000", "00000000x",
"000000000", "000000000", "00000000x", "00000000x", "1"        , "-1"       ,
"2"        , "-2"       , "255"      , "254"      , "00000000x", "0xxxxxxxx",
"1000000x0", "1xxxxxxxx", "x00000001", "x000000x0", "xxxxxxxxx", "00000000x",
"0xxxxxxxx", "1000000x0", "1xxxxxxxx", "x00000001", "x000000x0", "xxxxxxxxx",
"000000x0x", "0xxxxxxxx", "10000x0x0", "1xxxxxxxx", "x000x00x0", "x000x00x0",
"xxxxxxxxx", "xxxxxxxxx", "0"        , "2"        , "2"        , "2"        ,
"2"        , "2"        , "000000000", "0000000x0", "0000000x0", "0000000x0",
"000000000", "0000000x0", "0000000x0", "000000000", "0000000x0", "0000000x0",
"0000000x0", "000000000", "0000000x0", "0000000x0", "000000000", "0000000x0",
"0000000x0", "0000000x0", "0000000x0", "0000000x0", "0000000x0", "0000000x0",
"0"        , "-2"       , "2"        , "-2"       , "254"      , "254"      ,
"000000000", "0xxxxxxx0", "1000000x0", "1xxxxxxx0", "x00000000", "x000000x0",
"xxxxxxxx0", "000000000", "0xxxxxxx0", "1000000x0", "1xxxxxxx0", "x00000000",
"x000000x0", "xxxxxxxx0", "000000x00", "0xxxxxxx0", "10000x0x0", "1xxxxxxx0",
"x000x00x0", "x000x00x0", "xxxxxxxx0", "xxxxxxxx0", "1"        , "255"      ,
"2"        , "254"      , "255"      , "254"      , "00000000x", "0xxxxxxxx",
"0000000x0", "0xxxxxxxx", "000000001", "0000000x0", "0xxxxxxxx", "00000000x",
"0xxxxxxxx", "0000000x0", "0xxxxxxxx", "000000001", "0000000x0", "0xxxxxxxx",
"000000x0x", "0xxxxxxxx", "00000x0x0", "0xxxxxxxx", "0000x00x0", "0000x00x0",
"0xxxxxxxx", "0xxxxxxxx", "0"        , "254"      , "2"        , "254"      ,
"254"      , "254"      , "000000000", "0xxxxxxx0", "0000000x0", "0xxxxxxx0",
"000000000", "0000000x0", "0xxxxxxx0", "000000000", "0xxxxxxx0", "0000000x0",
"0xxxxxxx0", "000000000", "0000000x0", "0xxxxxxx0", "000000x00", "0xxxxxxx0",
"00000x0x0", "0xxxxxxx0", "0000x00x0", "0000x00x0", "0xxxxxxx0", "0xxxxxxx0",
"00000000x", "00000000x", "000000000", "000000000", "00000000x", "000000000",
"00000000x", "00000000x", "000000000", "00000000x", "00000000x", "000000000",
"00000000x", "00000000x", "00000000x", "000000000", "00000000x", "00000000x",
"000000000", "00000000x", "00000000x", "00000000x", "000000000", "00000000x",
"000000000", "000000000", "00000000x", "00000000x", "00000000x", "0xxxxxxxx",
"0000000x0", "0xxxxxxx0", "0xxxxxxxx", "0xxxxxxx0", "00000000x", "0xxxxxxxx",
"0000000x0", "0xxxxxxxx", "00000000x", "0000000x0", "0xxxxxxxx", "00000000x",
"0xxxxxxxx", "0000000x0", "0xxxxxxxx", "00000000x", "0000000x0", "0xxxxxxxx",
"000000x0x", "0xxxxxxxx", "00000x0x0", "0xxxxxxxx", "0000x00x0", "0000x00x0",
"0xxxxxxxx", "0xxxxxxxx", "000000000", "1000000x0", "0000000x0", "1000000x0",
"0000000x0", "0000000x0", "000000000", "0000000x0", "1000000x0", "1000000x0",
"x00000000", "x000000x0", "x000000x0", "000000000", "0000000x0", "1000000x0",
"1000000x0", "x00000000", "x000000x0", "x000000x0", "000000000", "0000000x0",
"1000000x0", "1000000x0", "x000000x0", "x000000x0", "x000000x0", "x000000x0",
"00000000x", "1xxxxxxxx", "0000000x0", "1xxxxxxx0", "0xxxxxxxx", "0xxxxxxx0",
"00000000x", "0xxxxxxxx", "1000000x0", "1xxxxxxxx", "x0000000x", "x000000x0",
"xxxxxxxxx", "00000000x", "0xxxxxxxx", "1000000x0", "1xxxxxxxx", "x0000000x",
"x000000x0", "xxxxxxxxx", "000000x0x", "0xxxxxxxx", "10000x0x0", "1xxxxxxxx",
"x000x00x0", "x000x00x0", "xxxxxxxxx", "xxxxxxxxx", "000000001", "x00000001",
"000000000", "x00000000", "000000001", "000000000", "00000000x", "00000000x",
"x00000000", "x0000000x", "x00000001", "x00000000", "x0000000x", "00000000x",
"00000000x", "x00000000", "x0000000x", "x00000001", "x00000000", "x0000000x",
"00000000x", "00000000x", "x00000000", "x0000000x", "x00000000", "x00000000",
"x0000000x", "x0000000x", "000000000", "x000000x0", "0000000x0", "x000000x0",
"0000000x0", "0000000x0", "000000000", "0000000x0", "x000000x0", "x000000x0",
"x00000000", "x000000x0", "x000000x0", "000000000", "0000000x0", "x000000x0",
"x000000x0", "x00000000", "x000000x0", "x000000x0", "000000000", "0000000x0",
"x000000x0", "x000000x0", "x000000x0", "x000000x0", "x000000x0", "x000000x0",
"00000000x", "xxxxxxxxx", "0000000x0", "xxxxxxxx0", "0xxxxxxxx", "0xxxxxxx0",
"00000000x", "0xxxxxxxx", "x000000x0", "xxxxxxxxx", "x0000000x", "x000000x0",
"xxxxxxxxx", "00000000x", "0xxxxxxxx", "x000000x0", "xxxxxxxxx", "x0000000x",
"x000000x0", "xxxxxxxxx", "000000x0x", "0xxxxxxxx", "x0000x0x0", "xxxxxxxxx",
"x000x00x0", "x000x00x0", "xxxxxxxxx", "xxxxxxxxx", "00000000x", "00000000x",
"000000000", "000000000", "00000000x", "000000000", "00000000x", "00000000x",
"000000000", "00000000x", "00000000x", "000000000", "00000000x", "00000000x",
"00000000x", "000000000", "00000000x", "00000000x", "000000000", "00000000x",
"00000000x", "00000000x", "000000000", "00000000x", "000000000", "000000000",
"00000000x", "00000000x", "00000000x", "0xxxxxxxx", "0000000x0", "0xxxxxxx0",
"0xxxxxxxx", "0xxxxxxx0", "00000000x", "0xxxxxxxx", "0000000x0", "0xxxxxxxx",
"00000000x", "0000000x0", "0xxxxxxxx", "00000000x", "0xxxxxxxx", "0000000x0",
"0xxxxxxxx", "00000000x", "0000000x0", "0xxxxxxxx", "000000x0x", "0xxxxxxxx",
"00000x0x0", "0xxxxxxxx", "0000x00x0", "0000x00x0", "0xxxxxxxx", "0xxxxxxxx",
"000000000", "1000000x0", "0000000x0", "1000000x0", "0000000x0", "0000000x0",
"000000000", "0000000x0", "1000000x0", "1000000x0", "x00000000", "x000000x0",
"x000000x0", "000000000", "0000000x0", "1000000x0", "1000000x0", "x00000000",
"x000000x0", "x000000x0", "000000000", "0000000x0", "1000000x0", "1000000x0",
"x000000x0", "x000000x0", "x000000x0", "x000000x0", "00000000x", "1xxxxxxxx",
"0000000x0", "1xxxxxxx0", "0xxxxxxxx", "0xxxxxxx0", "00000000x", "0xxxxxxxx",
"1000000x0", "1xxxxxxxx", "x0000000x", "x000000x0", "xxxxxxxxx", "00000000x",
"0xxxxxxxx", "1000000x0", "1xxxxxxxx", "x0000000x", "x000000x0", "xxxxxxxxx",
"000000x0x", "0xxxxxxxx", "10000x0x0", "1xxxxxxxx", "x000x00x0", "x000x00x0",
"xxxxxxxxx", "xxxxxxxxx", "000000001", "x00000001", "000000000", "x00000000",
"000000001", "000000000", "00000000x", "00000000x", "x00000000", "x0000000x",
"x00000001", "x00000000", "x0000000x", "00000000x", "00000000x", "x00000000",
"x0000000x", "x00000001", "x00000000", "x0000000x", "00000000x", "00000000x",
"x00000000", "x0000000x", "x00000000", "x00000000", "x0000000x", "x0000000x",
"000000000", "x000000x0", "0000000x0", "x000000x0", "0000000x0", "0000000x0",
"000000000", "0000000x0", "x000000x0", "x000000x0", "x00000000", "x000000x0",
"x000000x0", "000000000", "0000000x0", "x000000x0", "x000000x0", "x00000000",
"x000000x0", "x000000x0", "000000000", "0000000x0", "x000000x0", "x000000x0",
"x000000x0", "x000000x0", "x000000x0", "x000000x0", "00000000x", "xxxxxxxxx",
"0000000x0", "xxxxxxxx0", "0xxxxxxxx", "0xxxxxxx0", "00000000x", "0xxxxxxxx",
"x000000x0", "xxxxxxxxx", "x0000000x", "x000000x0", "xxxxxxxxx", "00000000x",
"0xxxxxxxx", "x000000x0", "xxxxxxxxx", "x0000000x", "x000000x0", "xxxxxxxxx",
"000000x0x", "0xxxxxxxx", "x0000x0x0", "xxxxxxxxx", "x000x00x0", "x000x00x0",
"xxxxxxxxx", "xxxxxxxxx", "00000000x", "000000x0x", "000000000", "000000x00",
"000000x0x", "000000x00", "00000000x", "000000x0x", "000000000", "000000x0x",
"00000000x", "000000000", "000000x0x", "00000000x", "000000x0x", "000000000",
"000000x0x", "00000000x", "000000000", "000000x0x", "000000x0x", "000000x0x",
"000000000", "000000x0x", "000000000", "000000000", "000000x0x", "000000x0x",
"00000000x", "0xxxxxxxx", "0000000x0", "0xxxxxxx0", "0xxxxxxxx", "0xxxxxxx0",
"00000000x", "0xxxxxxxx", "0000000x0", "0xxxxxxxx", "00000000x", "0000000x0",
"0xxxxxxxx", "00000000x", "0xxxxxxxx", "0000000x0", "0xxxxxxxx", "00000000x",
"0000000x0", "0xxxxxxxx", "000000x0x", "0xxxxxxxx", "00000x0x0", "0xxxxxxxx",
"0000x00x0", "0000x00x0", "0xxxxxxxx", "0xxxxxxxx", "000000000", "10000x0x0",
"0000000x0", "10000x0x0", "00000x0x0", "00000x0x0", "000000000", "00000x0x0",
"1000000x0", "10000x0x0", "x00000000", "x000000x0", "x0000x0x0", "000000000",
"00000x0x0", "1000000x0", "10000x0x0", "x00000000", "x000000x0", "x0000x0x0",
"000000000", "00000x0x0", "10000x0x0", "10000x0x0", "x000000x0", "x000000x0",
"x0000x0x0", "x0000x0x0", "00000000x", "1xxxxxxxx", "0000000x0", "1xxxxxxx0",
"0xxxxxxxx", "0xxxxxxx0", "00000000x", "0xxxxxxxx", "1000000x0", "1xxxxxxxx",
"x0000000x", "x000000x0", "xxxxxxxxx", "00000000x", "0xxxxxxxx", "1000000x0",
"1xxxxxxxx", "x0000000x", "x000000x0", "xxxxxxxxx", "000000x0x", "0xxxxxxxx",
"10000x0x0", "1xxxxxxxx", "x000x00x0", "x000x00x0", "xxxxxxxxx", "xxxxxxxxx",
"000000000", "x000x00x0", "0000000x0", "x000x00x0", "0000x00x0", "0000x00x0",
"000000000", "0000x00x0", "x000000x0", "x000x00x0", "x00000000", "x000000x0",
"x000x00x0", "000000000", "0000x00x0", "x000000x0", "x000x00x0", "x00000000",
"x000000x0", "x000x00x0", "000000000", "0000x00x0", "x000000x0", "x000x00x0",
"x000x00x0", "x000x00x0", "x000x00x0", "x000x00x0", "000000000", "x000x00x0",
"0000000x0", "x000x00x0", "0000x00x0", "0000x00x0", "000000000", "0000x00x0",
"x000000x0", "x000x00x0", "x00000000", "x000000x0", "x000x00x0", "000000000",
"0000x00x0", "x000000x0", "x000x00x0", "x00000000", "x000000x0", "x000x00x0",
"000000000", "0000x00x0", "x000000x0", "x000x00x0", "x000x00x0", "x000x00x0",
"x000x00x0", "x000x00x0", "00000000x", "xxxxxxxxx", "0000000x0", "xxxxxxxx0",
"0xxxxxxxx", "0xxxxxxx0", "00000000x", "0xxxxxxxx", "x000000x0", "xxxxxxxxx",
"x0000000x", "x000000x0", "xxxxxxxxx", "00000000x", "0xxxxxxxx", "x000000x0",
"xxxxxxxxx", "x0000000x", "x000000x0", "xxxxxxxxx", "000000x0x", "0xxxxxxxx",
"x0000x0x0", "xxxxxxxxx", "x000x00x0", "x000x00x0", "xxxxxxxxx", "xxxxxxxxx",
"00000000x", "xxxxxxxxx", "0000000x0", "xxxxxxxx0", "0xxxxxxxx", "0xxxxxxx0",
"00000000x", "0xxxxxxxx", "x000000x0", "xxxxxxxxx", "x0000000x", "x000000x0",
"xxxxxxxxx", "00000000x", "0xxxxxxxx", "x000000x0", "xxxxxxxxx", "x0000000x",
"x000000x0", "xxxxxxxxx", "000000x0x", "0xxxxxxxx", "x0000x0x0", "xxxxxxxxx",
"x000x00x0", "x000x00x0", "xxxxxxxxx", "xxxxxxxxx"
    ]) do |strs,res|
        # puts("#{strs[0]} & #{strs[1]} = #{strs[0] & strs[1]} ... "); 
        print "#"
        if (strs[0] & strs[1]).to_s != res then
            print("   \n #{strs[0]} & #{strs[1]} = #{strs[0] & strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end


print "\nTesting or... \n   "
begin
    STRs.product(STRs).zip( [ "1", "-1", "3", "-1", "255", "255", 
"000000001", "0xxxxxxx1", "1000000x1", "1xxxxxxx1", "x00000001", "x000000x1",
"xxxxxxxx1", "000000001", "0xxxxxxx1", "1000000x1", "1xxxxxxx1", "x00000001",
"x000000x1", "xxxxxxxx1", "000000x01", "0xxxxxxx1", "10000x0x1", "1xxxxxxx1",
"x000x00x1", "x000x00x1", "xxxxxxxx1", "xxxxxxxx1", "-1",  "-1",        "-1",  
"-1",  "-1",        "-1", "111111111", "111111111", "111111111", "111111111",
"111111111", "111111111", "111111111", "111111111", "111111111", "111111111",
"111111111", "111111111", "111111111", "111111111", "111111111", "111111111",
"111111111", "111111111", "111111111", "111111111", "111111111", "111111111",
"3",    "-1",    "2",    "-2",    "255",    "254",    "00000001x", "0xxxxxx1x",
"100000010", "1xxxxxx1x", "x00000011", "x00000010", "xxxxxxx1x", "00000001x",
"0xxxxxx1x", "100000010", "1xxxxxx1x", "x00000011", "x00000010", "xxxxxxx1x",
"000000x1x", "0xxxxxx1x", "10000x010", "1xxxxxx1x", "x000x0010", "x000x0010",
"xxxxxxx1x", "xxxxxxx1x", "-1",    "-1",    "-2",    "-2",    "-1",    "-2",  
"11111111x", "11111111x", "111111110", "11111111x", "111111111", "111111110",
"11111111x", "11111111x", "11111111x", "111111110", "11111111x", "111111111",
"111111110", "11111111x", "11111111x", "11111111x", "111111110", "11111111x",
"111111110", "111111110", "11111111x", "11111111x", "255",    "-1",    "255",
"-1",    "255",    "255",    "011111111", "011111111", "111111111",
"111111111", "x11111111", "x11111111", "x11111111", "011111111", "011111111",
"111111111", "111111111", "x11111111", "x11111111", "x11111111", "011111111",
"011111111", "111111111", "111111111", "x11111111", "x11111111", "x11111111",
"x11111111", "255",    "-1",    "254",    "-2",    "255",    "254",   
"01111111x", "01111111x", "111111110", "11111111x", "x11111111", "x11111110",
"x1111111x", "01111111x", "01111111x", "111111110", "11111111x", "x11111111",
"x11111110", "x1111111x", "01111111x", "01111111x", "111111110", "11111111x",
"x11111110", "x11111110", "x1111111x", "x1111111x", "000000001", "111111111",
"00000001x", "11111111x", "011111111", "01111111x", "00000000x", "0xxxxxxxx",
"1000000xx", "1xxxxxxxx", "x00000001", "x000000xx", "xxxxxxxxx", "00000000x",
"0xxxxxxxx", "1000000xx", "1xxxxxxxx", "x00000001", "x000000xx", "xxxxxxxxx",
"000000x0x", "0xxxxxxxx", "10000x0xx", "1xxxxxxxx", "x000x00xx", "x000x00xx",
"xxxxxxxxx", "xxxxxxxxx", "0xxxxxxx1", "111111111", "0xxxxxx1x", "11111111x",
"011111111", "01111111x", "0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"xxxxxxxx1", "xxxxxxxxx", "xxxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "xxxxxxxx1", "xxxxxxxxx", "xxxxxxxxx", "0xxxxxxxx", "0xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"1000000x1", "111111111", "100000010", "111111110", "111111111", "111111110",
"1000000xx", "1xxxxxxxx", "1000000x0", "1xxxxxxxx", "1000000x1", "1000000x0",
"1xxxxxxxx", "1000000xx", "1xxxxxxxx", "1000000x0", "1xxxxxxxx", "1000000x1",
"1000000x0", "1xxxxxxxx", "100000xxx", "1xxxxxxxx", "10000x0x0", "1xxxxxxxx",
"1000x00x0", "1000x00x0", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxx1", "111111111",
"1xxxxxx1x", "11111111x", "111111111", "11111111x", "1xxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "1xxxxxxx1", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxx1", "1xxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "x00000001", "111111111", "x00000011", "111111111",
"x11111111", "x11111111", "x00000001", "xxxxxxxx1", "1000000x1", "1xxxxxxx1",
"x00000001", "x000000x1", "xxxxxxxx1", "x00000001", "xxxxxxxx1", "1000000x1",
"1xxxxxxx1", "x00000001", "x000000x1", "xxxxxxxx1", "x00000x01", "xxxxxxxx1",
"10000x0x1", "1xxxxxxx1", "x000x00x1", "x000x00x1", "xxxxxxxx1", "xxxxxxxx1",
"x000000x1", "111111111", "x00000010", "111111110", "x11111111", "x11111110",
"x000000xx", "xxxxxxxxx", "1000000x0", "1xxxxxxxx", "x000000x1", "x000000x0",
"xxxxxxxxx", "x000000xx", "xxxxxxxxx", "1000000x0", "1xxxxxxxx", "x000000x1",
"x000000x0", "xxxxxxxxx", "x00000xxx", "xxxxxxxxx", "10000x0x0", "1xxxxxxxx",
"x000x00x0", "x000x00x0", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxx1", "111111111",
"xxxxxxx1x", "11111111x", "x11111111", "x1111111x", "xxxxxxxxx", "xxxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "xxxxxxxx1", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxx1", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "000000001", "111111111", "00000001x", "11111111x",
"011111111", "01111111x", "00000000x", "0xxxxxxxx", "1000000xx", "1xxxxxxxx",
"x00000001", "x000000xx", "xxxxxxxxx", "00000000x", "0xxxxxxxx", "1000000xx",
"1xxxxxxxx", "x00000001", "x000000xx", "xxxxxxxxx", "000000x0x", "0xxxxxxxx",
"10000x0xx", "1xxxxxxxx", "x000x00xx", "x000x00xx", "xxxxxxxxx", "xxxxxxxxx",
"0xxxxxxx1", "111111111", "0xxxxxx1x", "11111111x", "011111111", "01111111x",
"0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxx1", "xxxxxxxxx",
"xxxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxx1",
"xxxxxxxxx", "xxxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "1000000x1", "111111111",
"100000010", "111111110", "111111111", "111111110", "1000000xx", "1xxxxxxxx",
"1000000x0", "1xxxxxxxx", "1000000x1", "1000000x0", "1xxxxxxxx", "1000000xx",
"1xxxxxxxx", "1000000x0", "1xxxxxxxx", "1000000x1", "1000000x0", "1xxxxxxxx",
"100000xxx", "1xxxxxxxx", "10000x0x0", "1xxxxxxxx", "1000x00x0", "1000x00x0",
"1xxxxxxxx", "1xxxxxxxx", "1xxxxxxx1", "111111111", "1xxxxxx1x", "11111111x",
"111111111", "11111111x", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"1xxxxxxx1", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "1xxxxxxx1", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"x00000001", "111111111", "x00000011", "111111111", "x11111111", "x11111111",
"x00000001", "xxxxxxxx1", "1000000x1", "1xxxxxxx1", "x00000001", "x000000x1",
"xxxxxxxx1", "x00000001", "xxxxxxxx1", "1000000x1", "1xxxxxxx1", "x00000001",
"x000000x1", "xxxxxxxx1", "x00000x01", "xxxxxxxx1", "10000x0x1", "1xxxxxxx1",
"x000x00x1", "x000x00x1", "xxxxxxxx1", "xxxxxxxx1", "x000000x1", "111111111",
"x00000010", "111111110", "x11111111", "x11111110", "x000000xx", "xxxxxxxxx",
"1000000x0", "1xxxxxxxx", "x000000x1", "x000000x0", "xxxxxxxxx", "x000000xx",
"xxxxxxxxx", "1000000x0", "1xxxxxxxx", "x000000x1", "x000000x0", "xxxxxxxxx",
"x00000xxx", "xxxxxxxxx", "10000x0x0", "1xxxxxxxx", "x000x00x0", "x000x00x0",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxx1", "111111111", "xxxxxxx1x", "11111111x",
"x11111111", "x1111111x", "xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"xxxxxxxx1", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "xxxxxxxx1", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"000000x01", "111111111", "000000x1x", "11111111x", "011111111", "01111111x",
"000000x0x", "0xxxxxxxx", "100000xxx", "1xxxxxxxx", "x00000x01", "x00000xxx",
"xxxxxxxxx", "000000x0x", "0xxxxxxxx", "100000xxx", "1xxxxxxxx", "x00000x01",
"x00000xxx", "xxxxxxxxx", "000000x0x", "0xxxxxxxx", "10000xxxx", "1xxxxxxxx",
"x000x0xxx", "x000x0xxx", "xxxxxxxxx", "xxxxxxxxx", "0xxxxxxx1", "111111111",
"0xxxxxx1x", "11111111x", "011111111", "01111111x", "0xxxxxxxx", "0xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "xxxxxxxx1", "xxxxxxxxx", "xxxxxxxxx", "0xxxxxxxx",
"0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxx1", "xxxxxxxxx", "xxxxxxxxx",
"0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "10000x0x1", "111111111", "10000x010", "111111110",
"111111111", "111111110", "10000x0xx", "1xxxxxxxx", "10000x0x0", "1xxxxxxxx",
"10000x0x1", "10000x0x0", "1xxxxxxxx", "10000x0xx", "1xxxxxxxx", "10000x0x0",
"1xxxxxxxx", "10000x0x1", "10000x0x0", "1xxxxxxxx", "10000xxxx", "1xxxxxxxx",
"10000x0x0", "1xxxxxxxx", "1000xx0x0", "1000xx0x0", "1xxxxxxxx", "1xxxxxxxx",
"1xxxxxxx1", "111111111", "1xxxxxx1x", "11111111x", "111111111", "11111111x",
"1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxx1", "1xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxx1",
"1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "x000x00x1", "111111111",
"x000x0010", "111111110", "x11111111", "x11111110", "x000x00xx", "xxxxxxxxx",
"1000x00x0", "1xxxxxxxx", "x000x00x1", "x000x00x0", "xxxxxxxxx", "x000x00xx",
"xxxxxxxxx", "1000x00x0", "1xxxxxxxx", "x000x00x1", "x000x00x0", "xxxxxxxxx",
"x000x0xxx", "xxxxxxxxx", "1000xx0x0", "1xxxxxxxx", "x000x00x0", "x000x00x0",
"xxxxxxxxx", "xxxxxxxxx", "x000x00x1", "111111111", "x000x0010", "111111110",
"x11111111", "x11111110", "x000x00xx", "xxxxxxxxx", "1000x00x0", "1xxxxxxxx",
"x000x00x1", "x000x00x0", "xxxxxxxxx", "x000x00xx", "xxxxxxxxx", "1000x00x0",
"1xxxxxxxx", "x000x00x1", "x000x00x0", "xxxxxxxxx", "x000x0xxx", "xxxxxxxxx",
"1000xx0x0", "1xxxxxxxx", "x000x00x0", "x000x00x0", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxx1", "111111111", "xxxxxxx1x", "11111111x", "x11111111", "x1111111x",
"xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxx1", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxx1",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxx1", "111111111",
"xxxxxxx1x", "11111111x", "x11111111", "x1111111x", "xxxxxxxxx", "xxxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "xxxxxxxx1", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxx1", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx"
    ]) do |strs,res|
        # puts("#{strs[0]} | #{strs[1]} = #{strs[0] | strs[1]} ... "); 
        print "#"
        if (strs[0] | strs[1]).to_s != res then
            print("   \n #{strs[0]} | #{strs[1]} = #{strs[0] | strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end


print "\nTesting xor... \n   "
begin
    STRs.product(STRs).zip( [ "0", "-2", "3", "-1", "254", "255", 
"00000000x", "0xxxxxxxx", "1000000x1", "1xxxxxxxx", "x00000000", "x000000x1",
"xxxxxxxxx", "00000000x", "0xxxxxxxx", "1000000x1", "1xxxxxxxx", "x00000000",
"x000000x1", "xxxxxxxxx", "000000x0x", "0xxxxxxxx", "10000x0x1", "1xxxxxxxx",
"x000x00x1", "x000x00x1", "xxxxxxxxx", "xxxxxxxxx", "-2", "0", "-3", "1",
"-256", "-255", "11111111x", "1xxxxxxxx", "0111111x1", "0xxxxxxxx",
"x11111110", "x111111x1", "xxxxxxxxx", "11111111x", "1xxxxxxxx", "0111111x1",
"0xxxxxxxx", "x11111110", "x111111x1", "xxxxxxxxx", "111111x1x", "1xxxxxxxx",
"01111x1x1", "0xxxxxxxx", "x111x11x1", "x111x11x1", "xxxxxxxxx", "xxxxxxxxx",
"3", "-3", "0", "-4", "253", "252", "00000001x", "0xxxxxxxx", "1000000x0",
"1xxxxxxxx", "x00000011", "x000000x0", "xxxxxxxxx", "00000001x", "0xxxxxxxx",
"1000000x0", "1xxxxxxxx", "x00000011", "x000000x0", "xxxxxxxxx", "000000x1x",
"0xxxxxxxx", "10000x0x0", "1xxxxxxxx", "x000x00x0", "x000x00x0", "xxxxxxxxx",
"xxxxxxxxx", "-1", "1", "-4", "0", "-255", "-256", "11111111x", "1xxxxxxxx",
"0111111x0", "0xxxxxxxx", "x11111111", "x111111x0", "xxxxxxxxx", "11111111x",
"1xxxxxxxx", "0111111x0", "0xxxxxxxx", "x11111111", "x111111x0", "xxxxxxxxx",
"111111x1x", "1xxxxxxxx", "01111x1x0", "0xxxxxxxx", "x111x11x0", "x111x11x0",
"xxxxxxxxx", "xxxxxxxxx", "254", "-256", "253", "-255", "0", "1", "01111111x",
"0xxxxxxxx", "1111111x1", "1xxxxxxxx", "x11111110", "x111111x1", "xxxxxxxxx",
"01111111x", "0xxxxxxxx", "1111111x1", "1xxxxxxxx", "x11111110", "x111111x1",
"xxxxxxxxx", "011111x1x", "0xxxxxxxx", "11111x1x1", "1xxxxxxxx", "x111x11x1",
"x111x11x1", "xxxxxxxxx", "xxxxxxxxx", "255", "-255", "252", "-256", "1", "0",
"01111111x", "0xxxxxxxx", "1111111x0", "1xxxxxxxx", "x11111111", "x111111x0",
"xxxxxxxxx", "01111111x", "0xxxxxxxx", "1111111x0", "1xxxxxxxx", "x11111111",
"x111111x0", "xxxxxxxxx", "011111x1x", "0xxxxxxxx", "11111x1x0", "1xxxxxxxx",
"x111x11x0", "x111x11x0", "xxxxxxxxx", "xxxxxxxxx", "00000000x", "11111111x",
"00000001x", "11111111x", "01111111x", "01111111x", "00000000x", "0xxxxxxxx",
"1000000xx", "1xxxxxxxx", "x0000000x", "x000000xx", "xxxxxxxxx", "00000000x",
"0xxxxxxxx", "1000000xx", "1xxxxxxxx", "x0000000x", "x000000xx", "xxxxxxxxx",
"000000x0x", "0xxxxxxxx", "10000x0xx", "1xxxxxxxx", "x000x00xx", "x000x00xx",
"xxxxxxxxx", "xxxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx",
"0xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "0xxxxxxxx", "0xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"1000000x1", "0111111x1", "1000000x0", "0111111x0", "1111111x1", "1111111x0",
"1000000xx", "1xxxxxxxx", "0000000x0", "0xxxxxxxx", "x000000x1", "x000000x0",
"xxxxxxxxx", "1000000xx", "1xxxxxxxx", "0000000x0", "0xxxxxxxx", "x000000x1",
"x000000x0", "xxxxxxxxx", "100000xxx", "1xxxxxxxx", "00000x0x0", "0xxxxxxxx",
"x000x00x0", "x000x00x0", "xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx", "0xxxxxxxx",
"1xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"0xxxxxxxx", "0xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "x00000000", "x11111110", "x00000011", "x11111111",
"x11111110", "x11111111", "x0000000x", "xxxxxxxxx", "x000000x1", "xxxxxxxxx",
"x00000000", "x000000x1", "xxxxxxxxx", "x0000000x", "xxxxxxxxx", "x000000x1",
"xxxxxxxxx", "x00000000", "x000000x1", "xxxxxxxxx", "x00000x0x", "xxxxxxxxx",
"x0000x0x1", "xxxxxxxxx", "x000x00x1", "x000x00x1", "xxxxxxxxx", "xxxxxxxxx",
"x000000x1", "x111111x1", "x000000x0", "x111111x0", "x111111x1", "x111111x0",
"x000000xx", "xxxxxxxxx", "x000000x0", "xxxxxxxxx", "x000000x1", "x000000x0",
"xxxxxxxxx", "x000000xx", "xxxxxxxxx", "x000000x0", "xxxxxxxxx", "x000000x1",
"x000000x0", "xxxxxxxxx", "x00000xxx", "xxxxxxxxx", "x0000x0x0", "xxxxxxxxx",
"x000x00x0", "x000x00x0", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "00000000x", "11111111x", "00000001x", "11111111x",
"01111111x", "01111111x", "00000000x", "0xxxxxxxx", "1000000xx", "1xxxxxxxx",
"x0000000x", "x000000xx", "xxxxxxxxx", "00000000x", "0xxxxxxxx", "1000000xx",
"1xxxxxxxx", "x0000000x", "x000000xx", "xxxxxxxxx", "000000x0x", "0xxxxxxxx",
"10000x0xx", "1xxxxxxxx", "x000x00xx", "x000x00xx", "xxxxxxxxx", "xxxxxxxxx",
"0xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx",
"0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "1000000x1", "0111111x1",
"1000000x0", "0111111x0", "1111111x1", "1111111x0", "1000000xx", "1xxxxxxxx",
"0000000x0", "0xxxxxxxx", "x000000x1", "x000000x0", "xxxxxxxxx", "1000000xx",
"1xxxxxxxx", "0000000x0", "0xxxxxxxx", "x000000x1", "x000000x0", "xxxxxxxxx",
"100000xxx", "1xxxxxxxx", "00000x0x0", "0xxxxxxxx", "x000x00x0", "x000x00x0",
"xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx",
"0xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"0xxxxxxxx", "0xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"x00000000", "x11111110", "x00000011", "x11111111", "x11111110", "x11111111",
"x0000000x", "xxxxxxxxx", "x000000x1", "xxxxxxxxx", "x00000000", "x000000x1",
"xxxxxxxxx", "x0000000x", "xxxxxxxxx", "x000000x1", "xxxxxxxxx", "x00000000",
"x000000x1", "xxxxxxxxx", "x00000x0x", "xxxxxxxxx", "x0000x0x1", "xxxxxxxxx",
"x000x00x1", "x000x00x1", "xxxxxxxxx", "xxxxxxxxx", "x000000x1", "x111111x1",
"x000000x0", "x111111x0", "x111111x1", "x111111x0", "x000000xx", "xxxxxxxxx",
"x000000x0", "xxxxxxxxx", "x000000x1", "x000000x0", "xxxxxxxxx", "x000000xx",
"xxxxxxxxx", "x000000x0", "xxxxxxxxx", "x000000x1", "x000000x0", "xxxxxxxxx",
"x00000xxx", "xxxxxxxxx", "x0000x0x0", "xxxxxxxxx", "x000x00x0", "x000x00x0",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"000000x0x", "111111x1x", "000000x1x", "111111x1x", "011111x1x", "011111x1x",
"000000x0x", "0xxxxxxxx", "100000xxx", "1xxxxxxxx", "x00000x0x", "x00000xxx",
"xxxxxxxxx", "000000x0x", "0xxxxxxxx", "100000xxx", "1xxxxxxxx", "x00000x0x",
"x00000xxx", "xxxxxxxxx", "000000x0x", "0xxxxxxxx", "10000xxxx", "1xxxxxxxx",
"x000x0xxx", "x000x0xxx", "xxxxxxxxx", "xxxxxxxxx", "0xxxxxxxx", "1xxxxxxxx",
"0xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "0xxxxxxxx",
"0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"0xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "10000x0x1", "01111x1x1", "10000x0x0", "01111x1x0",
"11111x1x1", "11111x1x0", "10000x0xx", "1xxxxxxxx", "00000x0x0", "0xxxxxxxx",
"x0000x0x1", "x0000x0x0", "xxxxxxxxx", "10000x0xx", "1xxxxxxxx", "00000x0x0",
"0xxxxxxxx", "x0000x0x1", "x0000x0x0", "xxxxxxxxx", "10000xxxx", "1xxxxxxxx",
"00000x0x0", "0xxxxxxxx", "x000xx0x0", "x000xx0x0", "xxxxxxxxx", "xxxxxxxxx",
"1xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx", "1xxxxxxxx", "1xxxxxxxx",
"1xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "1xxxxxxxx", "1xxxxxxxx", "0xxxxxxxx", "0xxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "x000x00x1", "x111x11x1",
"x000x00x0", "x111x11x0", "x111x11x1", "x111x11x0", "x000x00xx", "xxxxxxxxx",
"x000x00x0", "xxxxxxxxx", "x000x00x1", "x000x00x0", "xxxxxxxxx", "x000x00xx",
"xxxxxxxxx", "x000x00x0", "xxxxxxxxx", "x000x00x1", "x000x00x0", "xxxxxxxxx",
"x000x0xxx", "xxxxxxxxx", "x000xx0x0", "xxxxxxxxx", "x000x00x0", "x000x00x0",
"xxxxxxxxx", "xxxxxxxxx", "x000x00x1", "x111x11x1", "x000x00x0", "x111x11x0",
"x111x11x1", "x111x11x0", "x000x00xx", "xxxxxxxxx", "x000x00x0", "xxxxxxxxx",
"x000x00x1", "x000x00x0", "xxxxxxxxx", "x000x00xx", "xxxxxxxxx", "x000x00x0",
"xxxxxxxxx", "x000x00x1", "x000x00x0", "xxxxxxxxx", "x000x0xxx", "xxxxxxxxx",
"x000xx0x0", "xxxxxxxxx", "x000x00x0", "x000x00x0", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx"
    ]) do |strs,res|
        # puts("#{strs[0]} ^ #{strs[1]} = #{strs[0] ^ strs[1]} ... "); 
        print "#"
        if (strs[0] ^ strs[1]).to_s != res then
            print("   \n #{strs[0]} ^ #{strs[1]} = #{strs[0] ^ strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end



print "\nTesting neg... \n   "
begin
    STRs.zip( [ "-1", "1", "-2", "2", "-255", "-254", 
"xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxx0", "0xxxxxxxxx", "xx11111111",
"xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxx0",
"0xxxxxxxxx", "xx11111111", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "0xxxxxxxx0", "0xxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxxxx"
    ]) do |str,res|
        # puts("-#{str} = #{-str} ... "); 
        print "#"
        if (-str).to_s != res then
            print("   \n #{-str} = #{-str} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end


print "\nTesting add... \n   "
begin
    STRs.product(STRs).zip([ "2", "0", "3", "-1", "256", "255", 
"00000000xx", "0xxxxxxxxx", "11000000x1", "xxxxxxxxxx", "xx00000010",
"xx000000x1", "xxxxxxxxxx", "00000000xx", "0xxxxxxxxx", "11000000x1",
"xxxxxxxxxx", "xx00000010", "xx000000x1", "xxxxxxxxxx", "0000000xxx",
"0xxxxxxxxx", "110000x0x1", "xxxxxxxxxx", "xx000x00x1", "xx000x00x1",
"xxxxxxxxxx", "xxxxxxxxxx", "0", "-2", "1", "-3", "254", "253", "xxxxxxxxxx",
"xxxxxxxxxx", "1xxxxxxxx1", "1xxxxxxxxx", "xx00000000", "xxxxxxxxx1",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxx1", "1xxxxxxxxx",
"xx00000000", "xxxxxxxxx1", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"1xxxxxxxx1", "1xxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxx1", "xxxxxxxxxx",
"xxxxxxxxxx", "3", "1", "4", "0", "257", "256", "000000001x", "0xxxxxxxxx",
"1100000xx0", "xxxxxxxxxx", "xx00000011", "xx00000xx0", "xxxxxxxxxx",
"000000001x", "0xxxxxxxxx", "1100000xx0", "xxxxxxxxxx", "xx00000011",
"xx00000xx0", "xxxxxxxxxx", "0000000x1x", "0xxxxxxxxx", "110000xxx0",
"xxxxxxxxxx", "xx000x0xx0", "xx000x0xx0", "xxxxxxxxxx", "xxxxxxxxxx", "-1",
"-3", "0", "-4", "253", "252", "111111111x", "xxxxxxxxxx", "1xxxxxxxx0",
"1xxxxxxxxx", "xx11111111", "xxxxxxxxx0", "xxxxxxxxxx", "111111111x",
"xxxxxxxxxx", "1xxxxxxxx0", "1xxxxxxxxx", "xx11111111", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxx1x", "xxxxxxxxxx", "1xxxxxxxx0", "1xxxxxxxxx",
"xxxxxxxxx0", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx", "256", "254", "257",
"253", "510", "509", "0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxxx",
"xx00000000", "xxxxxxxxx1", "xxxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx",
"xxxxxxxxx1", "xxxxxxxxxx", "xx00000000", "xxxxxxxxx1", "xxxxxxxxxx",
"0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxxx", "xxxxxxxxx1",
"xxxxxxxxx1", "xxxxxxxxxx", "xxxxxxxxxx", "255", "253", "256", "252", "509",
"508", "001111111x", "0xxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx", "xx11111111",
"xxxxxxxxx0", "xxxxxxxxxx", "001111111x", "0xxxxxxxxx", "xxxxxxxxx0",
"xxxxxxxxxx", "xx11111111", "xxxxxxxxx0", "xxxxxxxxxx", "0xxxxxxx1x",
"0xxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxxxx", "00000000xx", "xxxxxxxxxx", "000000001x",
"111111111x", "0xxxxxxxxx", "001111111x", "00000000xx", "0xxxxxxxxx",
"11000000xx", "xxxxxxxxxx", "xx000000xx", "xx000000xx", "xxxxxxxxxx",
"00000000xx", "0xxxxxxxxx", "11000000xx", "xxxxxxxxxx", "xx000000xx",
"xx000000xx", "xxxxxxxxxx", "0000000xxx", "0xxxxxxxxx", "110000x0xx",
"xxxxxxxxxx", "xx000x00xx", "xx000x00xx", "xxxxxxxxxx", "xxxxxxxxxx",
"0xxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx",
"0xxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "11000000x1", "1xxxxxxxx1",
"1100000xx0", "1xxxxxxxx0", "xxxxxxxxx1", "xxxxxxxxx0", "11000000xx",
"xxxxxxxxxx", "1000000xx0", "1xxxxxxxxx", "xx000000x1", "xx00000xx0",
"xxxxxxxxxx", "11000000xx", "xxxxxxxxxx", "1000000xx0", "1xxxxxxxxx",
"xx000000x1", "xx00000xx0", "xxxxxxxxxx", "1100000xxx", "xxxxxxxxxx",
"100000xxx0", "1xxxxxxxxx", "xx000x0xx0", "xx000x0xx0", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx",
"1xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx", "1xxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xx00000010",
"xx00000000", "xx00000011", "xx11111111", "xx00000000", "xx11111111",
"xx000000xx", "xxxxxxxxxx", "xx000000x1", "xxxxxxxxxx", "xx00000010",
"xx000000x1", "xxxxxxxxxx", "xx000000xx", "xxxxxxxxxx", "xx000000x1",
"xxxxxxxxxx", "xx00000010", "xx000000x1", "xxxxxxxxxx", "xx00000xxx",
"xxxxxxxxxx", "xx0000x0x1", "xxxxxxxxxx", "xx000x00x1", "xx000x00x1",
"xxxxxxxxxx", "xxxxxxxxxx", "xx000000x1", "xxxxxxxxx1", "xx00000xx0",
"xxxxxxxxx0", "xxxxxxxxx1", "xxxxxxxxx0", "xx000000xx", "xxxxxxxxxx",
"xx00000xx0", "xxxxxxxxxx", "xx000000x1", "xx00000xx0", "xxxxxxxxxx",
"xx000000xx", "xxxxxxxxxx", "xx00000xx0", "xxxxxxxxxx", "xx000000x1",
"xx00000xx0", "xxxxxxxxxx", "xx00000xxx", "xxxxxxxxxx", "xx0000xxx0",
"xxxxxxxxxx", "xx000x0xx0", "xx000x0xx0", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "00000000xx", "xxxxxxxxxx",
"000000001x", "111111111x", "0xxxxxxxxx", "001111111x", "00000000xx",
"0xxxxxxxxx", "11000000xx", "xxxxxxxxxx", "xx000000xx", "xx000000xx",
"xxxxxxxxxx", "00000000xx", "0xxxxxxxxx", "11000000xx", "xxxxxxxxxx",
"xx000000xx", "xx000000xx", "xxxxxxxxxx", "0000000xxx", "0xxxxxxxxx",
"110000x0xx", "xxxxxxxxxx", "xx000x00xx", "xx000x00xx", "xxxxxxxxxx",
"xxxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx",
"0xxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx",
"0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "11000000x1",
"1xxxxxxxx1", "1100000xx0", "1xxxxxxxx0", "xxxxxxxxx1", "xxxxxxxxx0",
"11000000xx", "xxxxxxxxxx", "1000000xx0", "1xxxxxxxxx", "xx000000x1",
"xx00000xx0", "xxxxxxxxxx", "11000000xx", "xxxxxxxxxx", "1000000xx0",
"1xxxxxxxxx", "xx000000x1", "xx00000xx0", "xxxxxxxxxx", "1100000xxx",
"xxxxxxxxxx", "100000xxx0", "1xxxxxxxxx", "xx000x0xx0", "xx000x0xx0",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx",
"1xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx",
"1xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xx00000010", "xx00000000", "xx00000011", "xx11111111", "xx00000000",
"xx11111111", "xx000000xx", "xxxxxxxxxx", "xx000000x1", "xxxxxxxxxx",
"xx00000010", "xx000000x1", "xxxxxxxxxx", "xx000000xx", "xxxxxxxxxx",
"xx000000x1", "xxxxxxxxxx", "xx00000010", "xx000000x1", "xxxxxxxxxx",
"xx00000xxx", "xxxxxxxxxx", "xx0000x0x1", "xxxxxxxxxx", "xx000x00x1",
"xx000x00x1", "xxxxxxxxxx", "xxxxxxxxxx", "xx000000x1", "xxxxxxxxx1",
"xx00000xx0", "xxxxxxxxx0", "xxxxxxxxx1", "xxxxxxxxx0", "xx000000xx",
"xxxxxxxxxx", "xx00000xx0", "xxxxxxxxxx", "xx000000x1", "xx00000xx0",
"xxxxxxxxxx", "xx000000xx", "xxxxxxxxxx", "xx00000xx0", "xxxxxxxxxx",
"xx000000x1", "xx00000xx0", "xxxxxxxxxx", "xx00000xxx", "xxxxxxxxxx",
"xx0000xxx0", "xxxxxxxxxx", "xx000x0xx0", "xx000x0xx0", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "0000000xxx",
"xxxxxxxxxx", "0000000x1x", "xxxxxxxx1x", "0xxxxxxxxx", "0xxxxxxx1x",
"0000000xxx", "0xxxxxxxxx", "1100000xxx", "xxxxxxxxxx", "xx00000xxx",
"xx00000xxx", "xxxxxxxxxx", "0000000xxx", "0xxxxxxxxx", "1100000xxx",
"xxxxxxxxxx", "xx00000xxx", "xx00000xxx", "xxxxxxxxxx", "000000xxxx",
"0xxxxxxxxx", "110000xxxx", "xxxxxxxxxx", "xx000x0xxx", "xx000x0xxx",
"xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx",
"xxxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"110000x0x1", "1xxxxxxxx1", "110000xxx0", "1xxxxxxxx0", "xxxxxxxxx1",
"xxxxxxxxx0", "110000x0xx", "xxxxxxxxxx", "100000xxx0", "1xxxxxxxxx",
"xx0000x0x1", "xx0000xxx0", "xxxxxxxxxx", "110000x0xx", "xxxxxxxxxx",
"100000xxx0", "1xxxxxxxxx", "xx0000x0x1", "xx0000xxx0", "xxxxxxxxxx",
"110000xxxx", "xxxxxxxxxx", "10000xxxx0", "1xxxxxxxxx", "xx000xxxx0",
"xx000xxxx0", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx",
"xxxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx", "1xxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xx000x00x1", "xxxxxxxxx1", "xx000x0xx0", "xxxxxxxxx0",
"xxxxxxxxx1", "xxxxxxxxx0", "xx000x00xx", "xxxxxxxxxx", "xx000x0xx0",
"xxxxxxxxxx", "xx000x00x1", "xx000x0xx0", "xxxxxxxxxx", "xx000x00xx",
"xxxxxxxxxx", "xx000x0xx0", "xxxxxxxxxx", "xx000x00x1", "xx000x0xx0",
"xxxxxxxxxx", "xx000x0xxx", "xxxxxxxxxx", "xx000xxxx0", "xxxxxxxxxx",
"xx00xx0xx0", "xx00xx0xx0", "xxxxxxxxxx", "xxxxxxxxxx", "xx000x00x1",
"xxxxxxxxx1", "xx000x0xx0", "xxxxxxxxx0", "xxxxxxxxx1", "xxxxxxxxx0",
"xx000x00xx", "xxxxxxxxxx", "xx000x0xx0", "xxxxxxxxxx", "xx000x00x1",
"xx000x0xx0", "xxxxxxxxxx", "xx000x00xx", "xxxxxxxxxx", "xx000x0xx0",
"xxxxxxxxxx", "xx000x00x1", "xx000x0xx0", "xxxxxxxxxx", "xx000x0xxx",
"xxxxxxxxxx", "xx000xxxx0", "xxxxxxxxxx", "xx00xx0xx0", "xx00xx0xx0",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx"
    ]) do |strs,res|
        # puts("#{strs[0]} + #{strs[1]} = #{strs[0] + strs[1]} ... "); 
        print "#"
        if (strs[0] + strs[1]).to_s != res then
            print("   \n #{strs[0]} + #{strs[1]} = #{strs[0] + strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end

print "\nTesting sub... \n   "
begin
    STRs.product(STRs).zip([ "0", "2", "-1", "3", "-254", "-253", 
"000000000x", "xxxxxxxxxx", "0xxxxxxxx1", "0xxxxxxxxx", "xx00000000",
"xxxxxxxxx1", "xxxxxxxxxx", "000000000x", "xxxxxxxxxx", "0xxxxxxxx1",
"0xxxxxxxxx", "xx00000000", "xxxxxxxxx1", "xxxxxxxxxx", "xxxxxxxx0x",
"xxxxxxxxxx", "0xxxxxxxx1", "0xxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxx1",
"xxxxxxxxxx", "xxxxxxxxxx", "-2", "0", "-3", "1", "-256", "-255", "111111111x",
"11xxxxxxxx", "00111111x1", "00xxxxxxxx", "xx11111110", "xx111111x1",
"xxxxxxxxxx", "111111111x", "11xxxxxxxx", "00111111x1", "00xxxxxxxx",
"xx11111110", "xx111111x1", "xxxxxxxxxx", "1111111x1x", "11xxxxxxxx",
"001111x1x1", "00xxxxxxxx", "xx111x11x1", "xx111x11x1", "xxxxxxxxxx",
"xxxxxxxxxx", "1", "3", "0", "4", "-253", "-252", "00000000xx", "xxxxxxxxxx",
"01000000x0", "0xxxxxxxxx", "xx00000001", "xx000000x0", "xxxxxxxxxx",
"00000000xx", "xxxxxxxxxx", "01000000x0", "0xxxxxxxxx", "xx00000001",
"xx000000x0", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxx0x0",
"0xxxxxxxxx", "xxxxxx00x0", "xxxxxx00x0", "xxxxxxxxxx", "xxxxxxxxxx", "-3",
"-1", "-4", "0", "-257", "-256", "11111111xx", "1xxxxxxxxx", "00111111x0",
"xxxxxxxxxx", "xx11111101", "xx111111x0", "xxxxxxxxxx", "11111111xx",
"1xxxxxxxxx", "00111111x0", "xxxxxxxxxx", "xx11111101", "xx111111x0",
"xxxxxxxxxx", "1111111xxx", "1xxxxxxxxx", "001111x1x0", "xxxxxxxxxx",
"xx111x11x0", "xx111x11x0", "xxxxxxxxxx", "xxxxxxxxxx", "254", "256", "253",
"257", "0", "1", "001111111x", "00xxxxxxxx", "01111111x1", "01xxxxxxxx",
"xx11111110", "xx111111x1", "xxxxxxxxxx", "001111111x", "00xxxxxxxx",
"01111111x1", "01xxxxxxxx", "xx11111110", "xx111111x1", "xxxxxxxxxx",
"0011111x1x", "00xxxxxxxx", "011111x1x1", "01xxxxxxxx", "xx111x11x1",
"xx111x11x1", "xxxxxxxxxx", "xxxxxxxxxx", "253", "255", "252", "256", "-1",
"0", "00111111xx", "xxxxxxxxxx", "01111111x0", "0xxxxxxxxx", "xx11111101",
"xx111111x0", "xxxxxxxxxx", "00111111xx", "xxxxxxxxxx", "01111111x0",
"0xxxxxxxxx", "xx11111101", "xx111111x0", "xxxxxxxxxx", "0011111xxx",
"xxxxxxxxxx", "011111x1x0", "0xxxxxxxxx", "xx111x11x0", "xx111x11x0",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "00000000xx", "111111111x",
"000000001x", "xxxxxxxxxx", "111111111x", "xxxxxxxxxx", "xxxxxxxxxx",
"0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx",
"0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxx1", "11000000x1",
"1xxxxxxxx0", "1100000xx0", "1xxxxxxxx1", "1xxxxxxxx0", "1xxxxxxxxx",
"1xxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxx0",
"xxxxxxxxxx", "1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx",
"xxxxxxxxx1", "xxxxxxxxx0", "xxxxxxxxxx", "1xxxxxxxxx", "1xxxxxxxxx",
"xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxx0", "xxxxxxxxxx",
"xxxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx",
"1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xx00000000",
"xx00000010", "xx11111111", "xx00000011", "xx00000000", "xx11111111",
"xx0000000x", "xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxxx", "xx00000000",
"xxxxxxxxx1", "xxxxxxxxxx", "xx0000000x", "xxxxxxxxxx", "xxxxxxxxx1",
"xxxxxxxxxx", "xx00000000", "xxxxxxxxx1", "xxxxxxxxxx", "xxxxxxxx0x",
"xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxx1",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxx1", "xx000000x1", "xxxxxxxxx0",
"xx00000xx0", "xxxxxxxxx1", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxx0", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx1",
"xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "00000000xx",
"111111111x", "000000001x", "xxxxxxxxxx", "111111111x", "xxxxxxxxxx",
"xxxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxx1",
"11000000x1", "1xxxxxxxx0", "1100000xx0", "1xxxxxxxx1", "1xxxxxxxx0",
"1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx1",
"xxxxxxxxx0", "xxxxxxxxxx", "1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxx0", "xxxxxxxxxx", "1xxxxxxxxx",
"1xxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx",
"xxxxxxxxxx", "1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xx00000000", "xx00000010", "xx11111111", "xx00000011", "xx00000000",
"xx11111111", "xx0000000x", "xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxxx",
"xx00000000", "xxxxxxxxx1", "xxxxxxxxxx", "xx0000000x", "xxxxxxxxxx",
"xxxxxxxxx1", "xxxxxxxxxx", "xx00000000", "xxxxxxxxx1", "xxxxxxxxxx",
"xxxxxxxx0x", "xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxxx", "xxxxxxxxx1",
"xxxxxxxxx1", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxx1", "xx000000x1",
"xxxxxxxxx0", "xx00000xx0", "xxxxxxxxx1", "xxxxxxxxx0", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx",
"xxxxxxxxx1", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxx0", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"0000000xxx", "xxxxxxxx1x", "0000000x1x", "xxxxxxxxxx", "xxxxxxxx1x",
"xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx",
"0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "0xxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "0xxxxxxxxx", "xxxxxxxxxx",
"0xxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"1xxxxxxxx1", "110000x0x1", "1xxxxxxxx0", "110000xxx0", "1xxxxxxxx1",
"1xxxxxxxx0", "1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx",
"xxxxxxxxx1", "xxxxxxxxx0", "xxxxxxxxxx", "1xxxxxxxxx", "1xxxxxxxxx",
"xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxx0", "xxxxxxxxxx",
"1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx0",
"xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx",
"1xxxxxxxxx", "xxxxxxxxxx", "1xxxxxxxxx", "1xxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxx1", "xx000x00x1", "xxxxxxxxx0", "xx000x0xx0",
"xxxxxxxxx1", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx",
"xxxxxxxxx0", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxx1",
"xx000x00x1", "xxxxxxxxx0", "xx000x0xx0", "xxxxxxxxx1", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx1",
"xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxxx1", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxxx", "xxxxxxxxx0", "xxxxxxxxx0",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx",
"xxxxxxxxxx", "xxxxxxxxxx", "xxxxxxxxxx"
    ]) do |strs,res|
        # puts("#{strs[0]} - #{strs[1]} = #{strs[0] - strs[1]} ... "); 
        print "#"
        if (strs[0] - strs[1]).to_s != res then
            print("   \n #{strs[0]} - #{strs[1]} = #{strs[0] - strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end

print "\nTesting shl... \n   "
begin
    STRs.product(STRs).zip([ "2", "0", "4", "0",
"57896044618658097711785492504343953926634992332820282019728792003956564819968",
"28948022309329048855892746252171976963317496166410141009864396001978282409984",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "-2", "-1", "-4", "-1",
"-57896044618658097711785492504343953926634992332820282019728792003956564819968",
"-28948022309329048855892746252171976963317496166410141009864396001978282409984",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "4", "1", "8", "0",
"115792089237316195423570985008687907853269984665640564039457584007913129639936",
"57896044618658097711785492504343953926634992332820282019728792003956564819968",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "-4", "-1", "-8", "-1",
"-115792089237316195423570985008687907853269984665640564039457584007913129639936",
"-57896044618658097711785492504343953926634992332820282019728792003956564819968",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "510", "127", "1020", "63",
"14763491377757814916505300588607708251291923044869171915030841961008924029091840",
"7381745688878907458252650294303854125645961522434585957515420980504462014545920",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "508", "127", "1016", "63",
"14705595333139156818793515096103364297365288052536351633011113169004967464271872",
"7352797666569578409396757548051682148682644026268175816505556584502483732135936",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "00000000z0", "00000000",
"00000000z00", "0000000",
"00000000z000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"00000000z00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "0zzzzzzzz0", "0zzzzzzz",
"0zzzzzzzz00", "0zzzzzz",
"0zzzzzzzz000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"0zzzzzzzz00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "1000000z00", "1000000z",
"1000000z000", "1000000",
"1000000z0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"1000000z000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "1zzzzzzzz0", "1zzzzzzz",
"1zzzzzzzz00", "1zzzzzz",
"1zzzzzzzz000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"1zzzzzzzz00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "z000000010", "z0000000",
"z0000000100", "z000000",
"z00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"z0000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "z000000z00", "z000000z",
"z000000z000", "z000000",
"z000000z0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"z000000z000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "zzzzzzzzz0", "zzzzzzzz",
"zzzzzzzzz00", "zzzzzzz",
"zzzzzzzzz000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"zzzzzzzzz00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "00000000x0", "00000000",
"00000000x00", "0000000",
"00000000x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"00000000x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "0xxxxxxxx0", "0xxxxxxx",
"0xxxxxxxx00", "0xxxxxx",
"0xxxxxxxx000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"0xxxxxxxx00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "1000000x00", "1000000x",
"1000000x000", "1000000",
"1000000x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"1000000x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "1xxxxxxxx0", "1xxxxxxx",
"1xxxxxxxx00", "1xxxxxx",
"1xxxxxxxx000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"1xxxxxxxx00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "x000000010", "x0000000",
"x0000000100", "x000000",
"x00000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"x0000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "x000000x00", "x000000x",
"x000000x000", "x000000",
"x000000x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"x000000x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxxx0", "xxxxxxxx",
"xxxxxxxxx00", "xxxxxxx",
"xxxxxxxxx000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxxx00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "000000z0x0", "000000z0",
"000000z0x00", "000000z",
"000000z0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"000000z0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "0xzxxxxzx0", "0xzxxxxz",
"0xzxxxxzx00", "0xzxxxx",
"0xzxxxxzx000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"0xzxxxxzx00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "10000x0z00", "10000x0z",
"10000x0z000", "10000x0",
"10000x0z0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"10000x0z000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "1xxzzzxzx0", "1xxzzzxz",
"1xxzzzxzx00", "1xxzzzx",
"1xxzzzxzx000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"1xxzzzxzx00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "z000z00x00", "z000z00x",
"z000z00x000", "z000z00",
"z000z00x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"z000z00x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "x000z00x00", "x000z00x",
"x000z00x000", "x000z00",
"x000z00x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"x000z00x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "zxxxzzzxx0", "zxxxzzzx",
"zxxxzzzxx00", "zxxxzzz",
"zxxxzzzxx000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"zxxxzzzxx00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxzzzxx0", "xxxxzzzx",
"xxxxzzzxx00", "xxxxzzz",
"xxxxzzzxx000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxzzzxx00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx"
    ]) do |strs,res|
        # puts("#{strs[0]} << #{strs[1]} = #{strs[0] << strs[1]} ... "); 
        print "#"
        if (strs[0] << strs[1]).to_s != res then
            print("   \n #{strs[0]} << #{strs[1]} = #{strs[0] << strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end

print "\nTesting shr... \n   "
begin
    STRs.product(STRs).zip([ "0", "2", "0", "4", "0", "0",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "-1", "-2", "-1", "-4", "-1",
"-1", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "1", "4", "0", "8", "0", "0",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "-1", "-4", "-1", "-8", "-1",
"-1", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "127", "510", "63", "1020",
"0", "0", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "127", "508", "63",
"1016", "0", "0", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "00000000",
"00000000z0", "0000000", "00000000z00", "00", "00", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "0zzzzzzz", "0zzzzzzzz0", "0zzzzzz", "0zzzzzzzz00",
"00", "00", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "1000000z",
"1000000z00", "1000000", "1000000z000", "00", "00", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "1zzzzzzz", "1zzzzzzzz0", "1zzzzzz", "1zzzzzzzz00",
"00", "00", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "z0000000",
"z000000010", "z000000", "z0000000100", "00", "00", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "z000000z", "z000000z00", "z000000", "z000000z000",
"00", "00", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "zzzzzzzz",
"zzzzzzzzz0", "zzzzzzz", "zzzzzzzzz00", "00", "00", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "00000000", "00000000x0", "0000000", "00000000x00",
"00", "00", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "0xxxxxxx",
"0xxxxxxxx0", "0xxxxxx", "0xxxxxxxx00", "00", "00", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "1000000x", "1000000x00", "1000000", "1000000x000",
"00", "00", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "1xxxxxxx",
"1xxxxxxxx0", "1xxxxxx", "1xxxxxxxx00", "00", "00", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "x0000000", "x000000010", "x000000", "x0000000100",
"00", "00", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "x000000x",
"x000000x00", "x000000", "x000000x000", "00", "00", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxxx0", "xxxxxxx", "xxxxxxxxx00",
"00", "00", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "000000z0",
"000000z0x0", "000000z", "000000z0x00", "00", "00", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "0xzxxxxz", "0xzxxxxzx0", "0xzxxxx", "0xzxxxxzx00",
"00", "00", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "10000x0z",
"10000x0z00", "10000x0", "10000x0z000", "00", "00", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "1xxzzzxz", "1xxzzzxzx0", "1xxzzzx", "1xxzzzxzx00",
"00", "00", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "z000z00x",
"z000z00x00", "z000z00", "z000z00x000", "00", "00", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "x000z00x", "x000z00x00", "x000z00", "x000z00x000",
"00", "00", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "zxxxzzzx",
"zxxxzzzxx0", "zxxxzzz", "zxxxzzzxx00", "00", "00", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxzzzx", "xxxxzzzxx0", "xxxxzzz", "xxxxzzzxx00",
"00", "00", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx",
"xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx", "xxxxxxxx"
    ]) do |strs,res|
        # puts("#{strs[0]} >> #{strs[1]} = #{strs[0] >> strs[1]} ... "); 
        print "#"
        if (strs[0] >> strs[1]).to_s != res then
            print("   \n #{strs[0]} >> #{strs[1]} = #{strs[0] >> strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end

print "\nTesting eq... \n   "
begin
    STRs.product(STRs).zip([ "1", "0", "0", "0", "0", "0",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "0", "1", "0", "0", "0",
"0", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "0", "0", "1", "0",
"0", "0", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "0", "0",
"0", "1", "0", "0", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "0",
"0", "0", "0", "1", "0", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"0", "0", "0", "0", "0", "1", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx"
    ]) do |strs,res|
        # puts("#{strs[0]} == #{strs[1]} = #{strs[0] == strs[1]} ... "); 
        print "#"
        if (strs[0] == strs[1]).to_s != res then
            print("   \n #{strs[0]} == #{strs[1]} = #{strs[0] == strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end

print "\nTesting lt... \n   "
begin
    STRs.product(STRs).zip([ "0", "0", "1", "0", "1", "1", 
"00", "xx", "00", "00", "xx", "xx", "xx", "00", "xx", "00", "00", "xx", "xx",
"xx", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx", "1", "0", "1", "0", "1",
"1", "01", "01", "00", "00", "xx", "xx", "xx", "01", "01", "00", "00", "xx",
"xx", "xx", "01", "01", "00", "00", "xx", "xx", "xx", "xx", "0", "0", "0", "0",
"1", "1", "00", "xx", "00", "00", "xx", "xx", "xx", "00", "xx", "00", "00",
"xx", "xx", "xx", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx", "1", "1",
"1", "0", "1", "1", "01", "01", "00", "xx", "xx", "xx", "xx", "01", "01", "00",
"xx", "xx", "xx", "xx", "01", "01", "00", "xx", "xx", "xx", "xx", "xx", "0",
"0", "0", "0", "0", "0", "00", "00", "00", "00", "xx", "xx", "xx", "00", "00",
"00", "00", "xx", "xx", "xx", "00", "00", "00", "00", "xx", "xx", "xx", "xx",
"0", "0", "0", "0", "1", "0", "00", "xx", "00", "00", "xx", "xx", "xx", "00",
"xx", "00", "00", "xx", "xx", "xx", "00", "xx", "00", "00", "xx", "xx", "xx",
"xx", "xx", "00", "01", "00", "xx", "01", "xx", "xx", "00", "00", "xx", "xx",
"xx", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx", "xx", "00", "00", "xx",
"xx", "xx", "xx", "xx", "00", "xx", "00", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "01", "01", "01", "01", "01", "01", "01", "01",
"xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01",
"01", "xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "01", "xx", "01", "01",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "00", "01", "00", "xx", "01", "xx", "xx", "00", "00", "xx",
"xx", "xx", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx", "xx", "00", "00",
"xx", "xx", "xx", "xx", "xx", "00", "xx", "00", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "01", "01", "01", "01", "01", "01", "01",
"01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx",
"01", "01", "xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "01", "xx", "01",
"01", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "00", "xx", "00", "xx", "xx", "xx", "xx", "00", "00",
"xx", "xx", "xx", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx", "xx", "00",
"00", "xx", "xx", "xx", "xx", "xx", "00", "xx", "00", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "01", "01", "01", "01", "01", "01",
"01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx",
"xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "01", "xx",
"01", "01", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx"
    ]) do |strs,res|
        # puts("#{strs[0]} < #{strs[1]} = #{strs[0] < strs[1]} ... "); 
        print "#"
        if (strs[0] < strs[1]).to_s != res then
            print("   \n #{strs[0]} < #{strs[1]} = #{strs[0] < strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end

print "\nTesting gt... \n   "
begin
    STRs.product(STRs).zip([ "0", "1", "0", "1", "0", "0", 
"xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx",
"xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "0", "0", "0", "1", "0",
"0", "00", "00", "01", "xx", "xx", "xx", "xx", "00", "00", "01", "xx", "xx",
"xx", "xx", "00", "00", "01", "xx", "xx", "xx", "xx", "xx", "1", "1", "0", "1",
"0", "0", "01", "xx", "01", "01", "xx", "xx", "xx", "01", "xx", "01", "01",
"xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "0", "0",
"0", "0", "0", "0", "00", "00", "01", "xx", "xx", "xx", "xx", "00", "00", "01",
"xx", "xx", "xx", "xx", "00", "00", "01", "xx", "xx", "xx", "xx", "xx", "1",
"1", "1", "1", "0", "1", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx",
"01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx",
"1", "1", "1", "1", "0", "0", "01", "xx", "01", "01", "xx", "xx", "xx", "01",
"xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx",
"xx", "00", "01", "00", "01", "00", "00", "xx", "xx", "01", "xx", "xx", "xx",
"xx", "xx", "xx", "01", "xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "xx",
"xx", "xx", "xx", "xx", "01", "xx", "01", "00", "xx", "xx", "xx", "01", "xx",
"xx", "xx", "xx", "xx", "xx", "01", "xx", "xx", "xx", "xx", "xx", "xx", "01",
"xx", "xx", "xx", "xx", "xx", "00", "00", "00", "00", "00", "00", "00", "xx",
"xx", "xx", "xx", "xx", "xx", "00", "xx", "xx", "xx", "xx", "xx", "xx", "00",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "00", "00", "00", "xx", "00", "00",
"00", "xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "xx", "xx", "xx", "xx",
"xx", "00", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "00", "01", "00", "01", "00", "00", "xx", "xx", "01", "xx", "xx",
"xx", "xx", "xx", "xx", "01", "xx", "xx", "xx", "xx", "xx", "xx", "01", "xx",
"xx", "xx", "xx", "xx", "xx", "01", "xx", "01", "00", "xx", "xx", "xx", "01",
"xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "xx", "xx", "xx", "xx", "xx",
"01", "xx", "xx", "xx", "xx", "xx", "00", "00", "00", "00", "00", "00", "00",
"xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "xx", "xx", "xx", "xx", "xx",
"00", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "00", "00", "00", "xx", "00",
"00", "00", "xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "xx", "xx", "xx",
"xx", "xx", "00", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "01", "xx", "01", "00", "00", "xx", "xx", "01", "xx",
"xx", "xx", "xx", "xx", "xx", "01", "xx", "xx", "xx", "xx", "xx", "xx", "01",
"xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "01", "00", "xx", "xx", "xx",
"01", "xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "xx", "xx", "xx", "xx",
"xx", "01", "xx", "xx", "xx", "xx", "xx", "00", "00", "00", "00", "00", "00",
"00", "xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "xx", "xx", "xx", "xx",
"xx", "00", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "00", "00", "00", "xx",
"00", "00", "00", "xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "xx", "xx",
"xx", "xx", "xx", "00", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx"
    ]) do |strs,res|
        # puts("#{strs[0]} > #{strs[1]} = #{strs[0] > strs[1]} ... "); 
        print "#"
        if (strs[0] > strs[1]).to_s != res then
            print("   \n #{strs[0]} > #{strs[1]} = #{strs[0] > strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end

print "\nTesting le... \n   "
begin
    STRs.product(STRs).zip([ "1", "0", "1", "0", "1", "1",
"xx", "xx", "00", "00", "xx", "xx", "xx", "xx", "xx", "00", "00", "xx", "xx",
"xx", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx", "1", "1", "1", "0", "1",
"1", "01", "01", "00", "xx", "xx", "xx", "xx", "01", "01", "00", "xx", "xx",
"xx", "xx", "01", "01", "00", "xx", "xx", "xx", "xx", "xx", "0", "0", "1", "0",
"1", "1", "00", "xx", "00", "00", "xx", "xx", "xx", "00", "xx", "00", "00",
"xx", "xx", "xx", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx", "1", "1",
"1", "1", "1", "1", "01", "01", "00", "xx", "xx", "xx", "xx", "01", "01", "00",
"xx", "xx", "xx", "xx", "01", "01", "00", "xx", "xx", "xx", "xx", "xx", "0",
"0", "0", "0", "1", "0", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx", "xx",
"00", "00", "xx", "xx", "xx", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx",
"0", "0", "0", "0", "1", "1", "00", "xx", "00", "00", "xx", "xx", "xx", "00",
"xx", "00", "00", "xx", "xx", "xx", "xx", "xx", "00", "00", "xx", "xx", "xx",
"xx", "01", "00", "01", "00", "01", "01", "xx", "xx", "00", "xx", "xx", "xx",
"xx", "xx", "xx", "00", "xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "xx",
"xx", "xx", "xx", "xx", "00", "xx", "00", "01", "xx", "xx", "xx", "00", "xx",
"xx", "xx", "xx", "xx", "xx", "00", "xx", "xx", "xx", "xx", "xx", "xx", "00",
"xx", "xx", "xx", "xx", "xx", "01", "01", "01", "01", "01", "01", "01", "xx",
"xx", "xx", "xx", "xx", "xx", "01", "xx", "xx", "xx", "xx", "xx", "xx", "01",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "01", "01", "01", "xx", "01", "01",
"01", "xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "xx", "xx", "xx", "xx",
"xx", "01", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "01", "00", "01", "00", "01", "01", "xx", "xx", "00", "xx", "xx",
"xx", "xx", "xx", "xx", "00", "xx", "xx", "xx", "xx", "xx", "xx", "00", "xx",
"xx", "xx", "xx", "xx", "xx", "00", "xx", "00", "01", "xx", "xx", "xx", "00",
"xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "xx", "xx", "xx", "xx", "xx",
"00", "xx", "xx", "xx", "xx", "xx", "01", "01", "01", "01", "01", "01", "01",
"xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "xx", "xx", "xx", "xx", "xx",
"01", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "01", "01", "01", "xx", "01",
"01", "01", "xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "xx", "xx", "xx",
"xx", "xx", "01", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "00", "xx", "00", "01", "01", "xx", "xx", "00", "xx",
"xx", "xx", "xx", "xx", "xx", "00", "xx", "xx", "xx", "xx", "xx", "xx", "00",
"xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "00", "01", "xx", "xx", "xx",
"00", "xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "xx", "xx", "xx", "xx",
"xx", "00", "xx", "xx", "xx", "xx", "xx", "01", "01", "01", "01", "01", "01",
"01", "xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "xx", "xx", "xx", "xx",
"xx", "01", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "01", "01", "01", "xx",
"01", "01", "01", "xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "xx", "xx",
"xx", "xx", "xx", "01", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx"
    ]) do |strs,res|
        # puts("#{strs[0]} <= #{strs[1]} = #{strs[0] <= strs[1]} ... "); 
        print "#"
        if (strs[0] <= strs[1]).to_s != res then
            print("   \n #{strs[0]} <= #{strs[1]} = #{strs[0] <= strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end

print "\nTesting ge... \n   "
begin
    STRs.product(STRs).zip([ "1", "1", "0", "1", "0", "0",
"01", "xx", "01", "01", "xx", "xx", "xx", "01", "xx", "01", "01", "xx", "xx",
"xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "0", "1", "0", "1", "0",
"0", "00", "00", "01", "01", "xx", "xx", "xx", "00", "00", "01", "01", "xx",
"xx", "xx", "00", "00", "01", "01", "xx", "xx", "xx", "xx", "1", "1", "1", "1",
"0", "0", "01", "xx", "01", "01", "xx", "xx", "xx", "01", "xx", "01", "01",
"xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "0", "0",
"0", "1", "0", "0", "00", "00", "01", "xx", "xx", "xx", "xx", "00", "00", "01",
"xx", "xx", "xx", "xx", "00", "00", "01", "xx", "xx", "xx", "xx", "xx", "1",
"1", "1", "1", "1", "1", "01", "01", "01", "01", "xx", "xx", "xx", "01", "01",
"01", "01", "xx", "xx", "xx", "01", "01", "01", "01", "xx", "xx", "xx", "xx",
"1", "1", "1", "1", "0", "1", "01", "xx", "01", "01", "xx", "xx", "xx", "01",
"xx", "01", "01", "xx", "xx", "xx", "01", "xx", "01", "01", "xx", "xx", "xx",
"xx", "xx", "01", "00", "01", "xx", "00", "xx", "xx", "01", "01", "xx", "xx",
"xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx",
"xx", "xx", "xx", "xx", "01", "xx", "01", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "00", "00", "00", "00", "00", "00", "00", "00",
"xx", "xx", "xx", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx", "xx", "00",
"00", "xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "00", "xx", "00", "00",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "01", "00", "01", "xx", "00", "xx", "xx", "01", "01", "xx",
"xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01",
"xx", "xx", "xx", "xx", "xx", "01", "xx", "01", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "00", "00", "00", "00", "00", "00", "00",
"00", "xx", "xx", "xx", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx", "xx",
"00", "00", "xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "00", "xx", "00",
"00", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "01", "xx", "01", "xx", "xx", "xx", "xx", "01", "01",
"xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01",
"01", "xx", "xx", "xx", "xx", "xx", "01", "xx", "01", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "00", "00", "00", "00", "00", "00",
"00", "00", "xx", "xx", "xx", "xx", "xx", "00", "00", "xx", "xx", "xx", "xx",
"xx", "00", "00", "xx", "xx", "xx", "xx", "xx", "xx", "00", "xx", "00", "xx",
"00", "00", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx"
    ]) do |strs,res|
        # puts("#{strs[0]} >= #{strs[1]} = #{strs[0] >= strs[1]} ... "); 
        print "#"
        if (strs[0] >= strs[1]).to_s != res then
            print("   \n #{strs[0]} >= #{strs[1]} = #{strs[0] >= strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end

print "\nTesting cp... \n   "
begin
    STRs.product(STRs).zip([ "0", "1", "-1", "1", "-1", "-1",
"xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx",
"xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "-1", "0", "-1", "1",
"-1", "-1", "11", "11", "01", "xx", "xx", "xx", "xx", "11", "11", "01", "xx",
"xx", "xx", "xx", "11", "11", "01", "xx", "xx", "xx", "xx", "xx", "1", "1",
"0", "1", "-1", "-1", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx",
"01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx",
"-1", "-1", "-1", "0", "-1", "-1", "11", "11", "01", "xx", "xx", "xx", "xx",
"11", "11", "01", "xx", "xx", "xx", "xx", "11", "11", "01", "xx", "xx", "xx",
"xx", "xx", "1", "1", "1", "1", "0", "1", "01", "xx", "01", "01", "xx", "xx",
"xx", "01", "xx", "01", "01", "xx", "xx", "xx", "01", "xx", "01", "01", "xx",
"xx", "xx", "xx", "1", "1", "1", "1", "-1", "0", "01", "xx", "01", "01", "xx",
"xx", "xx", "01", "xx", "01", "01", "xx", "xx", "xx", "01", "xx", "01", "01",
"xx", "xx", "xx", "xx", "xx", "01", "11", "01", "xx", "11", "xx", "xx", "01",
"01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx",
"01", "01", "xx", "xx", "xx", "xx", "xx", "01", "xx", "01", "xx", "xx", "xx",
"xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx",
"xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "11", "11", "11", "11", "11",
"11", "11", "11", "xx", "xx", "xx", "xx", "xx", "11", "11", "xx", "xx", "xx",
"xx", "xx", "11", "11", "xx", "xx", "xx", "xx", "xx", "xx", "11", "xx", "11",
"xx", "11", "11", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "01", "11", "01", "xx", "11", "xx", "xx",
"01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx",
"xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01", "xx", "01", "xx", "xx",
"xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx",
"xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "11", "11", "11", "11",
"11", "11", "11", "11", "xx", "xx", "xx", "xx", "xx", "11", "11", "xx", "xx",
"xx", "xx", "xx", "11", "11", "xx", "xx", "xx", "xx", "xx", "xx", "11", "xx",
"11", "xx", "11", "11", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "01", "xx", "01", "xx", "xx", "xx",
"xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx",
"xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01", "xx", "01", "xx",
"xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "xx", "01", "01", "xx",
"xx", "xx", "xx", "xx", "01", "01", "xx", "xx", "xx", "xx", "11", "11", "11",
"11", "11", "11", "11", "11", "xx", "xx", "xx", "xx", "xx", "11", "11", "xx",
"xx", "xx", "xx", "xx", "11", "11", "xx", "xx", "xx", "xx", "xx", "xx", "11",
"xx", "11", "xx", "11", "11", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx",
"xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx", "xx"
    ]) do |strs,res|
        # puts("#{strs[0]} <=> #{strs[1]} = #{strs[0] <=> strs[1]} ... "); 
        print "#"
        if (strs[0] <=> strs[1]).to_s != res then
            print("   \n #{strs[0]} <=> #{strs[1]} = #{strs[0] <=> strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end

print "\nTesting mul... \n   "
begin
    STRs.product(STRs).zip( [ "1", "-1", "2", "-2", "255", "254",
"0000000000000000x", "000000000xxxxxxxx", "111111111000000x0",
"111111111xxxxxxxx", "xxxxxxxxx00000001", "xxxxxxxxx000000x0",
"xxxxxxxxxxxxxxxxx", "0000000000000000x", "000000000xxxxxxxx",
"111111111000000x0", "111111111xxxxxxxx", "xxxxxxxxx00000001",
"xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxxx", "00000000000000x0x",
"000000000xxxxxxxx", "1111111110000x0x0", "111111111xxxxxxxx",
"xxxxxxxxx000x00x0", "xxxxxxxxx000x00x0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "-1", "1", "-2", "2", "-255", "-254", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxx11111111", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxx11111111", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "2", "-2", "4",
"-4", "510", "508", "000000000000000x0", "00000000xxxxxxxx0",
"11111111000000x00", "11111111xxxxxxxx0", "xxxxxxxx000000010",
"xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0", "000000000000000x0",
"00000000xxxxxxxx0", "11111111000000x00", "11111111xxxxxxxx0",
"xxxxxxxx000000010", "xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0",
"0000000000000x0x0", "00000000xxxxxxxx0", "111111110000x0x00",
"11111111xxxxxxxx0", "xxxxxxxx000x00x00", "xxxxxxxx000x00x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "-2", "2", "-4", "4", "-510", "-508",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "0000000xxxxxxxx00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx111111110", "xxxxxxxxxxxxxxx00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0",
"0000000xxxxxxxx00", "xxxxxxxxxxxxxxxx0", "xxxxxxxx111111110",
"xxxxxxxxxxxxxxx00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxx00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxx00", "xxxxxxxxxxxxxxx00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "255", "-255", "510", "-510", "65025", "64770",
"000000000xxxxxxxx", "0xxxxxxxxxxxxxxxx", "1000000xxxxxxxxx0",
"1xxxxxxxxxxxxxxxx", "xxxxxxxxx11111111", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "000000000xxxxxxxx", "0xxxxxxxxxxxxxxxx",
"1000000xxxxxxxxx0", "1xxxxxxxxxxxxxxxx", "xxxxxxxxx11111111",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "000000xxxxxxxxxxx",
"0xxxxxxxxxxxxxxxx", "1000xxxxxxxxxxxx0", "1xxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "254", "-254", "508", "-508", "64770", "64516",
"000000000xxxxxxx0", "0xxxxxxxxxxxxxxx0", "10000001xxxxxxx00",
"1xxxxxxxxxxxxxxx0", "xxxxxxxx011111110", "xxxxxxxxxxxxxxx00",
"xxxxxxxxxxxxxxxx0", "000000000xxxxxxx0", "0xxxxxxxxxxxxxxx0",
"10000001xxxxxxx00", "1xxxxxxxxxxxxxxx0", "xxxxxxxx011111110",
"xxxxxxxxxxxxxxx00", "xxxxxxxxxxxxxxxx0", "000000xxxxxxxxxx0",
"0xxxxxxxxxxxxxxx0", "1000xxxxxxxxxxx00", "1xxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxx00", "xxxxxxxxxxxxxxx00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "0000000000000000x", "xxxxxxxxxxxxxxxxx",
"000000000000000x0", "xxxxxxxxxxxxxxxx0", "000000000xxxxxxxx",
"000000000xxxxxxx0", "0000000000000000x", "000000000xxxxxxxx",
"xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxx0000000x",
"xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxxx", "0000000000000000x",
"000000000xxxxxxxx", "xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxx0000000x", "xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxxx",
"00000000000000x0x", "000000000xxxxxxxx", "xxxxxxxxx0000x0x0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxx000x00x0", "xxxxxxxxx000x00x0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "000000000xxxxxxxx",
"xxxxxxxxxxxxxxxxx", "00000000xxxxxxxx0", "xxxxxxxxxxxxxxxx0",
"0xxxxxxxxxxxxxxxx", "0xxxxxxxxxxxxxxx0", "000000000xxxxxxxx",
"0xxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"000000000xxxxxxxx", "0xxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "000000xxxxxxxxxxx", "0xxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"111111111000000x0", "xxxxxxxxxxxxxxxx0", "11111111000000x00",
"xxxxxxxxxxxxxxx00", "1000000xxxxxxxxx0", "10000001xxxxxxx00",
"xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxx0", "xxxxxxxx000000x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx1000000x0", "xxxxxxxx000000x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxx1000000x0",
"xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxx0000x0x0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx0000x0x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx000x00x00", "xxxxxxxx000x00x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"11111111xxxxxxxx0", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxx00000001",
"xxxxxxxxx11111111", "xxxxxxxx000000010", "xxxxxxxx111111110",
"xxxxxxxxx11111111", "xxxxxxxx011111110", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "x111111x1000000x0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxx00000001", "xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "x111111x1000000x0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxx00000001", "xxxxxxxxx000000x0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"x1111x1x10000x0x0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxx000x00x0",
"xxxxxxxxx000x00x0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxx0", "xxxxxxxx000000x00",
"xxxxxxxxxxxxxxx00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxx00",
"xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxx0", "xxxxxxxx000000x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxx000000x0", "xxxxxxxx000000x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxx000000x0",
"xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxx0000x0x0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx0000x0x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx000x00x00", "xxxxxxxx000x00x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "0000000000000000x",
"xxxxxxxxxxxxxxxxx", "000000000000000x0", "xxxxxxxxxxxxxxxx0",
"000000000xxxxxxxx", "000000000xxxxxxx0", "0000000000000000x",
"000000000xxxxxxxx", "xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxx0000000x", "xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxxx",
"0000000000000000x", "000000000xxxxxxxx", "xxxxxxxxx000000x0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxx0000000x", "xxxxxxxxx000000x0",
"xxxxxxxxxxxxxxxxx", "00000000000000x0x", "000000000xxxxxxxx",
"xxxxxxxxx0000x0x0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxx000x00x0",
"xxxxxxxxx000x00x0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"000000000xxxxxxxx", "xxxxxxxxxxxxxxxxx", "00000000xxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "0xxxxxxxxxxxxxxxx", "0xxxxxxxxxxxxxxx0",
"000000000xxxxxxxx", "0xxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "000000000xxxxxxxx", "0xxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "000000xxxxxxxxxxx",
"0xxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "111111111000000x0", "xxxxxxxxxxxxxxxx0",
"11111111000000x00", "xxxxxxxxxxxxxxx00", "1000000xxxxxxxxx0",
"10000001xxxxxxx00", "xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxx1000000x0",
"xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxx000000x0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx1000000x0", "xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxx0000x0x0", "xxxxxxxxxxxxxxxx0", "xxxxxxxx0000x0x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx000x00x00", "xxxxxxxx000x00x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "11111111xxxxxxxx0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxx00000001", "xxxxxxxxx11111111", "xxxxxxxx000000010",
"xxxxxxxx111111110", "xxxxxxxxx11111111", "xxxxxxxx011111110",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "x111111x1000000x0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxx00000001", "xxxxxxxxx000000x0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"x111111x1000000x0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxx00000001",
"xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "x1111x1x10000x0x0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxx000x00x0", "xxxxxxxxx000x00x0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx000000x00", "xxxxxxxxxxxxxxx00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxx00", "xxxxxxxxx000000x0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxx000000x0",
"xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxx000000x0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxx000000x0", "xxxxxxxx000000x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxx0000x0x0", "xxxxxxxxxxxxxxxx0", "xxxxxxxx0000x0x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx000x00x00", "xxxxxxxx000x00x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"00000000000000x0x", "xxxxxxxxxxxxxxxxx", "0000000000000x0x0",
"xxxxxxxxxxxxxxxx0", "000000xxxxxxxxxxx", "000000xxxxxxxxxx0",
"00000000000000x0x", "000000xxxxxxxxxxx", "xxxxxxxxx0000x0x0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxx00000x0x", "xxxxxxxxx0000x0x0",
"xxxxxxxxxxxxxxxxx", "00000000000000x0x", "000000xxxxxxxxxxx",
"xxxxxxxxx0000x0x0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxx00000x0x",
"xxxxxxxxx0000x0x0", "xxxxxxxxxxxxxxxxx", "000000000000xxx0x",
"000000xxxxxxxxxxx", "xxxxxxxxx00xxx0x0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxx0x0xx0x0", "xxxxxxxxx0x0xx0x0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "000000000xxxxxxxx", "xxxxxxxxxxxxxxxxx",
"00000000xxxxxxxx0", "xxxxxxxxxxxxxxxx0", "0xxxxxxxxxxxxxxxx",
"0xxxxxxxxxxxxxxx0", "000000000xxxxxxxx", "0xxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "000000000xxxxxxxx",
"0xxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"000000xxxxxxxxxxx", "0xxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "1111111110000x0x0",
"xxxxxxxxxxxxxxxx0", "111111110000x0x00", "xxxxxxxxxxxxxxx00",
"1000xxxxxxxxxxxx0", "1000xxxxxxxxxxx00", "xxxxxxxxx0000x0x0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx0000x0x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx10000x0x0", "xxxxxxxx0000x0x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxx0000x0x0", "xxxxxxxxxxxxxxxx0", "xxxxxxxx0000x0x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx10000x0x0", "xxxxxxxx0000x0x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxx00xxx0x0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx00xxx0x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxx0x0xx0x00",
"xxxxxxxx0x0xx0x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "11111111xxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxx000x00x0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx000x00x00", "xxxxxxxxxxxxxxx00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxx00", "xxxxxxxxx000x00x0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx000x00x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxx000x00x0",
"xxxxxxxx000x00x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxx000x00x0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx000x00x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxx000x00x0", "xxxxxxxx000x00x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxx0x0xx0x0", "xxxxxxxxxxxxxxxx0", "xxxxxxxx0x0xx0x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxx0xx00x00", "xxxxxxxxx0xx00x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "xxxxxxxxx000x00x0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx000x00x00", "xxxxxxxxxxxxxxx00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxx00", "xxxxxxxxx000x00x0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxx000x00x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxx000x00x0", "xxxxxxxx000x00x00", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxx000x00x0", "xxxxxxxxxxxxxxxx0", "xxxxxxxx000x00x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxx000x00x0", "xxxxxxxx000x00x00",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxx0x0xx0x0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxx0x0xx0x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxx0xx00x00",
"xxxxxxxxx0xx00x00", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxxx",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxx0", "xxxxxxxxxxxxxxxx0",
"xxxxxxxxxxxxxxxxx", "xxxxxxxxxxxxxxxxx"
    ]) do |strs,res|
        # puts("#{strs[0]} * #{strs[1]} = #{strs[0] * strs[1]} ... "); 
        print "#"
        if (strs[0] * strs[1]).to_s != res then
            print("   \n #{strs[0]} * #{strs[1]} = #{strs[0] * strs[1]} ... "); 
            print "Error: invalid numeric value, expecting #{res}.\n   "
            $success = false
        end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end

print "\nTesting div... \n   "
begin
    STRs.product(STRs).zip( [ "1", "-1", "0", "-1", "0", "0",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "-1", "1", "-1", "0", "-1",
"-1", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "2", "-2",
"1", "-1", "0", "0", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"-2", "2", "-1", "1", "-1", "-1", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "255", "-255", "127", "-128", "1", "1", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "254", "-254", "127", "-127", "0", "1", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx", "xxxxxxxxx",
"xxxxxxxxx"
    ]) do |strs,res|
        puts("#{strs[0]} / #{strs[1]} = #{strs[0] / strs[1]} ... "); 
        # print "#"
        # if (strs[0] / strs[1]).to_s != res then
        #     print("   \n #{strs[0]} / #{strs[1]} = #{strs[0] / strs[1]} ... "); 
        #     print "Error: invalid numeric value, expecting #{res}.\n   "
        #     $success = false
        # end
    end
rescue Exception => e
    puts "Error: unexpected exception raised ", e, e.backtrace
    $success = false
end
if $success then
    puts " Ok."
end
exit


if $success then
    puts "\nSuccess."
else
    puts "\nFailure."
end
