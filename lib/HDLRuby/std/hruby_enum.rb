
module HDLRuby::High::Std

  ##
  # Standard HDLRuby::High library: hardware enumerator generator.
  # The idea is to be able to have parallel enumerators in HDLRuby.
  # 
  ########################################################################



  # Module adding hardware enumerator functionalities to object including
  # the to_a method.
  module HEnumerable

    # Convert to an array.
    def h_to_a
      res = []
      self.heach {|e| res << e }
      return res
    end

    # Iterator on each of the elements in range +rng+.
    # *NOTE*: 
    #   - Stop iteration when the end of the range is reached or when there
    #     are no elements left
    #   - This is not a method from Ruby but one specific for hardware where
    #     creating a array is very expensive.
    def heach_range(rng,&ruby_block)
      return self.heach.each_range(rng,&ruby_block)
    end

    # Tell if all the elements respect a given criterion given either
    # as +arg+ or as block.
    def hall?(arg = nil, &ruby_block)
      if self.hsize < 1 then
        # Empty, so always true.
        return 1
      end
      comp = []
      if arg then
        # Compare each element to arg in parallel.
        comp = self.hmap do |elem|
          elem == arg
        end
      elsif ruby_block then
        # Use the ruby block in parallel.
        comp = self.hmap(&ruby_block)
      else
        # Nothing to check.
        return 1
      end
      # Reduce the result.
      return comp.reduce(&:&)
    end

    # Tell if any of the elements respects a given criterion given either
    # as +arg+ or as block.
    def hany?(arg = nil,&ruby_block)
      if self.hsize < 1 then
        # Empty, so always false.
        return 0
      end
      comp = []
      if arg then
        # Compare each element to arg in parallel.
        comp = self.hmap do |elem|
          elem == arg
        end
      elsif ruby_block then
        # Use the ruby block in parallel.
        comp = self.hmap(&ruby_block)
      else
        # Nothing to check.
        return 0
      end
      # Reduce the result.
      return comp.reduce(&:|)
    end

    # Returns an HEnumerator generated from current enumerable and +arg+
    def hchain(arg)
      # return self.heach + arg
      return self.hto_a + arg.hto_a
    end

    # HW implementation of the Ruby chunk.
    # NOTE: to do, or may be not.
    def hchunk(*args,&ruby_block)
      raise "hchunk is not supported yet."
    end

    # HW implementation of the Ruby chunk_while.
    # NOTE: to do, or may be not.
    def hchunk_while(*args,&ruby_block)
      raise "hchunk_while is not supported yet."
    end

    # Returns a HEnumerable containing the execution result of the given 
    # block on each element. If no block is given, return an HEnumerator.
    def hmap(&ruby_block)
      # No block given? Generate a new wrapper enumerator for smap.
      if !ruby_block then
        return HEnumeratorWrapper.new(self,:hmap)
      end
      # A block given? Create the result HEnumerable (a Ruby array).
      res = []
      self.heach { |e| res << ruby_block.call(e) }
      return res
    end

    # HW implementation of the Ruby flat_map.
    def hflat_map(&ruby_block)
      # No block given? Generate a new wrapper enumerator for smap.
      if !ruby_block then
        return HEnumeratorWrapper.new(self,:hmap)
      end
      # A block given? Create the result HEnumerable (a Ruby array).
      # return self.heach.flat_map(&ruby_block)
      return self.hto_a.flat_map(&ruby_block)
    end

    # HW implementation of the Ruby compact.
    def hcompact
      raise "hcompact is not supported yet."
    end


    # HW implementation of the Ruby count.
    def hcount(arg = nil, &ruby_block)
      if self.hsize < 1 then
        # Empty, so always false.
        return 0
      end
      comp = []
      if arg then
        # Compare each element to arg in parallel.
        comp = self.hmap do |elem|
          elem == arg
        end
      elsif ruby_block then
        # Use the ruby block in parallel.
        comp = self.hmap(&ruby_block)
      else
        # Nothing to check, return the size.
        return self.hsize
      end
      # Reduce the result.
      return comp.reduce(&:+)
    end

    # HW implementation of the Ruby cycle.
    def hcycle(n = nil,&ruby_block)
      raise "hcycle is not supported yet."
    end

    # HW implementation of the Ruby find.
    # NOTE: contrary to Ruby, by default ifnone is 0 and not nil.
    def hfind(ifnone = proc { 0 }, &ruby_block)
      # No block given? Generate a new wrapper enumerator for sfind.
      if !ruby_block then
        return HEnumeratorWrapper.new(self,:hfind,ifnone)
      end
      if self.hsize < 1 then
        # Empty, so always not found.
        return ifnone.call
      end
      # Convert to an array.
      ar = self.hto_a
      # Use the ruby block in parallel.
      comp = ar.map { |elem| ruby_block.call(elem) }
      # Generate the look up circuit.
      res = HDLRuby::High.top_user.mux(comp[-1],ifnone.call,ar[-1])
      (self.hsize-1).times do |i|
        res = HDLRuby::High.top_user.mux(comp[-i-2],res,ar[-i-2])
      end
      return res
    end

    # HW implementation of the Ruby drop.
    def hdrop(n)
      # return self.heach.drop(n)
      res = []
      size = self.hsize
      self.heach do |e|
        break if n == size
        n += 1
        res << e
      end
      return res
    end

    # HW implementation of the Ruby drop_while.
    def hdrop_while(&ruby_block)
      raise "hdrop_while is not supported yet."
    end

    # HW implementation of the Ruby each_cons
    def heach_cons(n,&ruby_block)
      # No block given? Generate a new wrapper enumerator for heach_cons.
      if !ruby_block then
        return HEnumeratorWrapper.new(self,:heach_cons,n)
      end
      # return self.heach.each_cons(n,&ruby_block)
      return self.hto_a.each_cons(n,&ruby_block)
    end

    # HW implementation of the Ruby each_entry.
    # NOTE: to do, or may be not.
    def heach_entry(*args,&ruby_block)
      raise "heach_entry is not supported yet."
    end

    # HW implementation of the Ruby each_slice
    def heach_slice(n,&ruby_block)
      # No block given? Generate a new wrapper enumerator for heach_slice.
      if !ruby_block then
        return HEnumeratorWrapper.new(self,:heach_slice,n)
      end
      # return self.heach.each_slice(n,&ruby_block)
      return self.hto_a.each_slice(n,&ruby_block)
    end

    # HW implementation of the Ruby each_with_index.
    def heach_with_index(*args,&ruby_block)
      # No block given? Generate a new wrapper enumerator for
      # heach_with_index.
      if !ruby_block then
        return HEnumeratorWrapper.new(self,:heach_with_index)
      end
      # self.heach.each_with_index(*args,&ruby_block)
      idx = 0
      self.heach do |e|
        ruby_block.call(*args,e,idx)
        idx += 1
      end
    end

    # HW implementation of the Ruby each_with_object.
    def heach_with_object(obj,&ruby_block)
      # No block given? Generate a new wrapper enumerator for
      # heach_with_object.
      if !ruby_block then
        return HEnumeratorWrapper.new(self,:heach_with_object)
      end
      # self.heach.with_object(obj,&ruby_block)
      self.heach { |e| ruby_block.call(e,obj,&ruby_block) }
    end

    # # HW implementation of the Ruby to_a.
    # def hto_a
    #   return self.heach.to_a
    # end

    def hto_a
      res = []
      self.heach { |e| res << e }
      return res
    end

    # HW implementation of the Ruby select.
    def hselect(&ruby_block)
      raise "hselect is not supported yet."
    end

    # HW implementation of the Ruby find_index.
    def hfind_index(obj = nil, &ruby_block)
      # No block given nor obj? Generate a new wrapper enumerator for
      # hfind.
      if !ruby_block && !obj then
        return HEnumeratorWrapper.new(self,:hfind)
      end
      if self.hsize < 1 then
        # Empty, so always not found.
        return -1
      end
      # If there is an objet, look for it.
      ruby_block = proc { |e| e == obj } if obj
      # Convert to an array.
      ar = self.hto_a
      size =ar.size
      # Use the ruby block in parallel.
      comp = self.hmap { |elem| ruby_block.call(elem) }
      # Generate the look up circuit.
      res = HDLRuby::High.top_user.mux(comp[-1],-1,size-1)
      (self.hsize-1).times do |i|
        res = HDLRuby::High.top_user.mux(comp[-i-2],res,size-i-2)
      end
      return res
    end

    # HW implementation of the Ruby first.
    def hfirst(n=1)
      # return self.heach.first(n)
      res = []
      self.heach do |e|
        break if n == 0
        res << e
        n -= 1
      end
      return res
    end

    # HW implementation of the Ruby grep.
    # NOTE: to do, or may be not.
    def hgrep(*args,&ruby_block)
      raise "hgrep is not supported yet."
    end

    # HW implementation of the Ruby grep_v.
    # NOTE: to do, or may be not.
    def hgrep_v(*args,&ruby_block)
      raise "hgrep_v is not supported yet."
    end

    # HW implementation of the Ruby group_by.
    # NOTE: to do, or may be not.
    def hgroup_by(*args,&ruby_block)
      raise "hgroup_by is not supported yet."
    end

    # HW implementation of the Ruby include?
    def hinclude?(obj)
      return self.hany?(obj)
    end

    # HW implementation of the Ruby inject.
    def hinject(*args, &ruby_block)
      # return self.heach.inject(*args,&ruby_block)
      return self.hto_a.inject(*args,&ruby_block)
    end

    alias_method :hreduce, :hinject

    # Specific to HDLRuby: inject with no default value through the call
    # operator.
    def call(*args, &ruby_block)
      return self.hinject(*args,&ruby_block)
    end

    # HW implementation of the Ruby lazy.
    # NOTE: to do, or may be not.
    def hlazy(*args, &ruby_block)
      raise "hlazy is not supported yet."
    end

    # HW implementation of the Ruby max.
    def hmax(n = nil, &ruby_block)
      unless n then
        n = 1
        scalar = true
      end
      if self.hsize < 1 or n < 1 then
        # Empty, no max.
        return 0
      end
      unless ruby_block then
        # The default comparator.
        ruby_block = proc { |a,b| a > b }
      end
      # The 2-value max unit.
      max2 = proc {|a,b| HDLRuby::High.top_user.mux(ruby_block.call(a,b),b,a) }
      # The single max hearch.
      m = self.hreduce(&max2)
      res = [m]
      if n > 1 then
        raise "hmax not supported for more than one max element."
      end
      # # The other max hearch.
      # ar = self.to_a
      # sign = self.type.signed?
      # (n-1).times do
      #   # Exclude the previous max.
      #   ar = ar.map do |a|
      #     if sign then
      #       HDLRuby::High.top_user.mux(a == m, a, HDLRuby::High.cur_system.send("_b1#{"0" * (a.type.width-1)}"))
      #     else
      #       HDLRuby::High.top_user.mux(a == m, a, HDLRuby::High.cur_system.send("_b0#{"0" * (a.type.width-1)}"))
      #     end
      #   end
      #   puts "#2 ar.size=#{ar.size}"
      #   m = ar.reduce(&max2)
      # puts "#3"
      #   res << m
      # puts "#4"
      # end
      # puts "#5"
      if scalar then
        # Scalar result case.
        return m
      else
        # Array result case.
        return res
      end
    end

    # HW implementation of the Ruby max_by.
    def hmax_by(n = nil, &ruby_block)
      # No block given? Generate a new wrapper enumerator for smax_by.
      if !ruby_block then
        return HEnumeratorWrapper.new(self,:hmax_by,n)
      end
      # A block is given, use smax with a proc that applies ruby_block
      # before comparing.
      # return hmax(n) { |a,b| ruby_block.call(a) <=> ruby_block.call(b) }
      return hmax(n) { |a,b| ruby_block.call(a) > ruby_block.call(b) }
    end

    # HW implementation of the Ruby min.
    def hmin(n = nil, &ruby_block)
      unless n then
        n = 1
        scalar = true
      end
      if self.hsize < 1 or n < 1 then
        # Empty, no min.
        return 0
      end
      if !ruby_block then
        # The default comparator.
        ruby_block = proc { |a,b| a > b }
      end
      # The 2-value max unit.
      min2 = proc {|a,b| HDLRuby::High.top_user.mux(ruby_block.call(a,b),a,b) }
      # The single max hearch.
      m = self.hreduce(&min2)
      res = [m]
      if n > 1 then
        raise "hmin not supported for more than one max element."
      end
      # # The other max hearch.
      # ar = self.to_a
      # sign = self.type.signed?
      # (n-1).times do
      #   # Exclude the previous max.
      #   ar = ar.hmap do |a| 
      #     if sign then
      #       HDLRuby::High.top_user.mux(a == m, a, HDLRuby::High.cur_system.send("_0#{"1" * (a.type.width-1)}"))
      #     else
      #       HDLRuby::High.top_user.mux(a == m, a, HDLRuby::High.cur_system.send("_1#{"1" * (a.type.width-1)}"))
      #     end
      #   end
      #   m = ar.reduce(&min2)
      #   res << m
      # end
      if scalar then
        # Scalar result case.
        return m
      else
        # Array result case.
        return res
      end
    end

    # HW implementation of the Ruby min_by.
    def hmin_by(n = nil, &ruby_block)
      # No block given? Generate a new wrapper enumerator for smin_by.
      if !ruby_block then
        return HEnumeratorWrapper.new(self,:hmin_by,n)
      end
      # A block is given, use smin with a proc that applies ruby_block
      # before comparing.
      # return hmin(n) { |a,b| ruby_block.call(a) <=> ruby_block.call(b) }
      return hmin(n) { |a,b| ruby_block.call(a) > ruby_block.call(b) }
    end

    # HW implementation of the Ruby minmax.
    def hminmax(&ruby_block)
      res = []
      # Computes the min.
      res[0] = self.hmin(&ruby_block)
      # Computes the max.
      res[1] = self.hmax(&ruby_block)
      # Return the result.
      return res
    end

    # HW implementation of the Ruby minmax_by.
    def hminmax_by(&ruby_block)
      res = []
      # Computes the min.
      res[0] = self.hmin_by(&ruby_block)
      # Computes the max.
      res[1] = self.hmax_by(&ruby_block)
      # Return the result.
      return res
    end

    # Tell if none of the elements respects a given criterion given either
    # as +arg+ or as block.
    def hnone?(arg = nil, &ruby_block)
      if self.hsize < 1 then
        # Empty, so always true.
        return 1
      end
      comp = []
      if arg then
        # Compare each element to arg in parallel.
        comp = self.hmap do |elem|
          elem == arg
        end
      elsif ruby_block then
        # Use the ruby block in parallel.
        comp = self.hmap(&ruby_block)
      else
        # Nothing to check.
        return 1
      end
      # Reduce the result.
      return comp.reduce(&:|) != 1
    end

    # Tell if one and only one of the elements respects a given criterion
    # given either as +arg+ or as block.
    def hone?(arg = nil,&ruby_block)
      if self.hsize < 1 then
        # Empty, so always false.
        return 0
      end
      # Count the occurences.
      cnt = self.hcount(arg,&ruby_block)
      # Check if count is 1.
      return cnt == 1
    end

    # HW implementation of the Ruby partition.
    # NOTE: to do, or may be not.
    def hpartition(*args,&ruby_block)
      raise "spartition is not supported yet."
    end

    # HW implementatiob of the Ruby reject.
    def hreject(&ruby_block)
      return hselect {|elem| ~ruby_block.call(elem) }
    end

    # HW implementatiob of the Ruby reverse_each.
    def hreverse_each(*args,&ruby_block)
      # No block given? Generate a new wrapper enumerator for 
      # sreverse_each.
      if !ruby_block then
        return HEnumeratorWrapper.new(self,:hreverse_each,*args)
      end
      return self.to_a.reverse_each(&ruby_block)
    end

    # HW implementation of the Ruby slice_after.
    # NOTE: to do, or may be not.
    def hslice_after(pattern = nil,&ruby_block)
      raise "hslice_after is not supported yet."
    end

    # HW implementation of the Ruby slice_before.
    # NOTE: to do, or may be not.
    def hslice_before(*args,&ruby_block)
      raise "hslice_before is not supported yet."
    end

    # HW implementation of the Ruby slice_when.
    # NOTE: to do, or may be not.
    def hslice_when(*args,&ruby_block)
      raise "hslice_before is not supported yet."
    end

    # # HW implementation of the Ruby sort.
    # def hsort(&ruby_block)
    #   unless ruby_block then
    #     # The default comparator.
    #     ruby_block = proc { |a,b| a < b }
    #   end
    #   if(self.hsize <= 1) then
    #     # Not enough elements: already sorted.
    #     return self
    #   end
    #   # Sort two elements.
    #   sort2 = proc do |a,b|
    #     if b then
    #       HDLRuby::High.top_user.mux(ruby_block.call(a,b), [ b, a] , [a, b])
    #     else
    #       [a]
    #     end
    #   end
    #   # Generate the merge sort.
    #   res = self.hto_a
    #   size = self.hsize
    #   size.width.times do |i|
    #     aux = []
    #     step = 1 << (i+1)
    #     subsize = size/step
    #     # Generate the parts to merge two by two
    #     parts = res.each_slice(subsize).to_a
    #     # Merge.
    #     aux = parts.each_slice(2).map do |(p0,p1)|
    #       p0.zip(p1).map {|a,b| sort2.call(a,b).hto_a }
    #     end.flatten
    #     res = aux
    #   end
    #   return res
    # end

    # HW implementation of the Ruby sort using the bitonic sort method.
    # NOTE: dummy is the dummy value used for filling the holes in the
    # comparison network if the number of elements is not a power of 2.
    def hsort(dummy = self.type.base.max.as(self.type.base), &ruby_block)
      # The size to sort
      size = self.hsize
      # The type of the base elements
      typ = self.type.base
      if(size <= 1) then
        # Not enough elements: already sorted.
        return self
      end
      # The power of 2 size.
      size2 = 2 ** ((size-1).width)
      # Generate the comparator.
      unless ruby_block then
        # The default comparator.
        ruby_block = proc { |a,b| a > b }
      end
      # Generate the compare and swap of two elements.
      compswap = proc do |a,b|
        if b then
          HDLRuby::High.top_user.mux(ruby_block.call(a,b), [ b, a] , [a, b])
        else
          [a]
        end
      end
      # Create the input stage of the sorter.
      stages = [self.hto_a + [dummy] * (size2-size) ]
      # Generate the bitonic sorter.
      k = 2
      while(k <= size2) do
        j = k / 2
        while(j > 0) do
          # puts "New stage"
          # Create the new intermediate stage.
          stage = size2.times.map {|i| typ.inner(HDLRuby.uniq_name) }
          stages << stage
          size2.times do |i|
            # Determin the swapcomp positions.
            l = i ^ j
            # puts "size2=#{size2} i=#{i} j=#{j} l=#{l} k=#{k}"
            if l > i then
              if i & k == 0 then
                # puts "swap #{i} and #{l}"
                [stages[-1][l],stages[-1][i]] <=
                  compswap.(stages[-2][i],stages[-2][l])
              else
                # puts "antiswap #{i} and #{l}"
                [stages[-1][i],stages[-1][l]] <=
                  compswap.(stages[-2][i],stages[-2][l])
              end
            end
          end
          j /= 2
        end
        k *= 2
      end
      # puts "Done"
      return stages[-1][0..(size-1)]
    end

    # HW implementation of the Ruby sort.
    # NOTE: dummy is the dummy value used for filling the holes in the
    # comparison network if the number of elements is not a power of 2.
    def hsort_by(dummy = self.type.base.max.as(self.type.base),
                 &ruby_block)
      # No block given? Generate a new wrapper enumerator for smin_by.
      if !ruby_block then
        return HEnumeratorWrapper.new(self,:hsort_by,n)
      end
      # A block is given, use smin with a proc that applies ruby_block
      # before comparing.
      return hsort(dummy) {|a,b| ruby_block.call(a) > ruby_block.call(b) }
    end

    # HW implementation of the Ruby sum.
    def hsum(initial_value = nil,&ruby_block)
      aux = self
      # Apply the ruby block of each element if any.
      aux = aux.hmap(&ruby_block) if ruby_block
      # Do the sum.
      if initial_value then
        return aux.hinject(initial_value,&:+)
      else
        return aux.hinject(&:+)
      end
    end

    # The HW implementation of the Ruby take.
    def htake(n)
      return self[0..n-1]
    end

    # The HW implementation of the Ruby take_while.
    def htake_while(&ruby_block)
      raise "htake_while is not supported yet."
    end

    # HW implementation of the Ruby tally.
    # NOTE: to do, or may be not.
    def htally(h = nil)
      raise "htally is not supported yet."
    end

    # HW implementation of the Ruby to_h.
    # NOTE: to do, or may be not.
    def hto_h(h = nil)
      raise "hto_h is not supported yet."
    end

    # HW implementation of the Ruby uniq.
    def huniq(&ruby_block)
      raise "huniq is not supported yet."
    end

    # HW implementation of the Ruby zip.
    # NOTE: for now szip is deactivated untile tuples are properly
    #       handled by HDLRuby.
    def hzip(obj,&ruby_block)
      size = self.hsize
      ar = obj.hto_a
      if ar.size > 0 then
        typ = ar[0].type
      else
        typ = self.type.base
      end
      # Fills the obj array with 0 until its size match self's.
      ar << 0.to_expr.as(typ) while ar.size < size
      if ruby_block then
        # There is a block to apply.
        return self.hto_a.zip(ar,&ruby_block)
      else
        # There is no block to apply generate an two level array.
        return self.hto_a.zip(ar)
      end
    end

    # Iterator on the +num+ next elements.
    # *NOTE*:
    #   - Stop iteration when the end of the range is reached or when there
    #     are no elements left
    #   - This is not a method from Ruby but one specific for hardware where
    #     creating a array is very expensive.
    def heach_nexts(num,&ruby_block)
      raise "heach_nexts is not supported yet."
    end

  end


  # Describes hardware enumerator classes that allows to
  # generate HW iteration over HW or SW objects.

  # This is the abstract Enumerator class.
  class HEnumerator
    include Enumerable
    include HEnumerable

    # The methods that need to be defined.
    [:size, :type, :clone, :hto_a].each do |name|
       define_method(:name) do
         raise "Method '#{name}' must be defined for a valid sequencer enumerator."
       end
     end

    # Iterate on each element.
    def heach(&ruby_block)
      # No block given, returns self.
      return self unless ruby_block
      # return self.hto_a.each(&ruby_block)
      if self.respond_to?(:[]) then
        return self.size.times do |i|
          ruby_block.call(self[i])
        end
      else
        return self.hto_a.each(&ruby_block)
      end
    end

    alias_method :each, :heach

    # Iterator on each of the elements in range +rng+.
    # *NOTE*: 
    #   - Stop iteration when the end of the range is reached or when there
    #     are no elements left
    #   - This is not a method from Ruby but one specific for hardware where
    #     creating a array is very expensive.
    def heach_range(rng,&ruby_block)
      # No block given, returns a new enumerator.
      return HEnumeratorWrapper.new(self,:heach_range) unless ruby_block
      return self.to_a.each_range(rng,&ruby_block)
    end

    # Iterate on each element with arbitrary object +obj+.
    def heach_with_object(val,&ruby_block)
      return self.with_object(val,&ruby_block)
    end

    # Iterates with an index.
    def with_index(&ruby_block)
      # No block given, returns a new enumerator.
      return HEnumeratorWrapper.new(self,:with_index) unless ruby_block
      # return self.hto_a.each_with_index(&ruby_block)
      i = 0
      return self.heach do |e|
        res = ruby_block.call(e,i)
        i += 1
        res
      end
    end

    # Return a new HEnumerator with an arbitrary arbitrary object +obj+.
    def with_object(obj)
      # No block given, returns a new enumerator.
      return HEnumeratorWrapper.new(self,:with_object) unless ruby_block
      # return self.hto_a.each_with_object(&ruby_block)
      return self.heach do |e|
        ruby_block.call(e,obj)
      end
    end

    # Return a new HEnumerator going on iteration over enumerable +obj+
    def +(obj)
      return self.hto_a + obj.hto_a
    end
  end


  # This is the wrapper Enumerator over an other one for applying an 
  # other interation method over the first one.
  class HEnumeratorWrapper < HEnumerator

    # Create a new HEnumerator wrapper over +enum+ with +iter+ iteration
    # method and +args+ argument.
    def initialize(enum,iter,*args)
      if enum.is_a?(HEnumerator) then
        @enumerator = enum.clone
      else
        @enumerator = enum.heach
      end
      @iterator  = iter.to_sym
      @arguments = args
    end

    # The directly delegate methods.
    def size
      return @enumerator.size
    end
    alias_method :hsize, :size

    def type
      return @enumerator.type
    end

    # Iterator on each of the elements in range +rng+.
    # *NOTE*: 
    #   - Stop iteration when the end of the range is reached or when there
    #     are no elements left
    #   - This is not a method from Ruby but one specific for hardware where
    #     creating a array is very expensive.
    def heach_range(rng,&ruby_block)
      return @enumerator.heach_range(rng,&ruby_block)
    end

    # Clones the enumerator.
    def clone
      return HEnumeratorWrapper.new(@enumerator,@iterator,*@arguments)
    end

    # Iterate over each element.
    def heach(&ruby_block)
      # No block given, returns self.
      return self unless ruby_block
      # A block is given, iterate.
      return @enumerator.send(@iterator,*@arguments,&ruby_block)
    end
  end


  # module HDLRuby::High::HRef
  module HDLRuby::High::HExpression
    # # Enhance the HRef module with sequencer iteration.
    # # Properties of expressions are also required
    # def self.included(klass)
    #   klass.class_eval do
    #     include HEnumerable
    #     puts "current class=#{klass}"

    #     # Iterate over the elements.
    #     #
    #     # Returns an enumerator if no ruby block is given.
    #     def heach(&ruby_block)
    #       # No ruby block? Return an enumerator.
    #       # return to_enum(:each) unless ruby_block
    #       return self unless ruby_block
    #       # A block? Apply it on each element.
    #       self.type.range.heach do |i|
    #         yield(self[i])
    #       end
    #     end

    #     # Size.
    #     def hsize
    #       self.type.size
    #     end
    #   end
    # end

    # Iterate over the elements.
    #
    # Returns an enumerator if no ruby block is given.
    def heach(&ruby_block)
      # No ruby block? Return an enumerator.
      # return to_enum(:each) unless ruby_block
      return self unless ruby_block
      # A block? Apply it on each element.
      self.type.range.heach do |i|
        yield(self[i])
      end
    end

    # Size.
    def hsize
      self.type.size
    end

    # Also adds the methods of HEnumerable.
    HEnumerable.instance_methods.each do |meth|
      define_method(meth,HEnumerable.instance_method(meth))
    end
  end


  module HDLRuby::High::HExpression
    # Enhance the HExpression module with sequencer iterations.

    # HW times iteration.
    def htimes(&ruby_block)
      unless self.respond_to?(:to_i) then
        raise "htimes unsupported for such an expression: #{self}."
      end
      return self.to_i.htimes(&ruby_block)
    end

    # HW upto iteration.
    def hupto(val,&ruby_block)
      unless self.respond_to?(:to_i) then
        raise "hupto unsupported for such an expression: #{self}."
      end
      return self.to_i.hupto(val,&ruby_block)
    end

    # HW downto iteration.
    def sdownto(val,&ruby_block)
      unless self.respond_to?(:to_i) then
        raise "hupto unsupported for such an expression: #{self}."
      end
      return self.to_i.hdownto(val,&ruby_block)
    end
  end

  # class HDLRuby::High::Value
  #   # Enhance the HRef module with sequencer iteration.
  #   # Properties of expressions are also required
  #   def self.included(klass)
  #     klass.class_eval do
  #       include HEnumerable
  #     end
  #   end

  #   # Convert to an array.
  #   alias_method :hto_a, :to_a

  #   # Size.
  #   def hsize
  #     self.type.size
  #   end
  # end


  module ::Enumerable
    # Enhance the Enumerable module with sequencer iteration.

    # Conversion to array.
    alias_method :hto_a, :to_a

    # Size.
    def hsize
      self.to_a.size
    end

    # Also adds the methods of HEnumerable.
    HEnumerable.instance_methods.each do |meth|
      define_method(meth,HEnumerable.instance_method(meth))
    end
  end


  class ::Array
    alias :heach :each

    alias :hto_a :to_a
  end


  class ::Range
    # Enhance the Range class with sequencer iteration.
    include HEnumerable

    # # Conversion to array.
    # def hto_a
    #   res = []
    #   self.heach { |i| res << i }
    #   return res
    # end

    # Redefinition of heach to support also HDLRuby Values.
    def heach(&ruby_block)
      if self.first.is_a?(Value) or self.last.is_a?(Value) then
        # Value range case.
        # No block given.
        return self unless ruby_block
        # A block is given, iterate on each element of the range
        # converted to values of the right type.
        if first.is_a?(Value) then
          typ = self.first.type
        else
          typ = self.last.type
        end
        first = self.first.to_i
        last = self.last.to_i
        if first <= last then
          (first..last).each do |i|
            ruby_block.call(i.as(typ))
          end
        else
          (last..first).reverse_each do |i|
            ruby_block.call(i.as(typ))
          end
        end
      else
        # Other range cases.
        if self.first <= self.last then
          return self.each(&ruby_block)
        else
          return (self.last..self.first).reverse_each(&ruby_block)
        end
      end
    end

    # Size.
    alias_method :hsize, :size
  end



  class ::Integer
    # Enhance the Integer class with sequencer iterations.

    # HW times iteration.
    alias_method :htimes, :times

    # HW upto iteration.
    alias_method :hupto, :upto

    # HW downto iteration.
    alias_method :hdownto, :downto
  end

end
