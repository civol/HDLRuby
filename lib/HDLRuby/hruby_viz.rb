# An IC netlist mrdel and SVG-based vizualizer for HDLRuby 

require 'stackprof'


module HDLRuby::Viz

  # Directions/sides encoding: left=1, up=2, right=4, down=8, blocked=16
  LEFT    = 1
  UP      = 2
  RIGHT   = 4
  DOWN    = 8
  BLOCKED = 16


  # An IC Port
  class Port
    attr_reader :name
    attr_reader :ic
    attr_reader :type
    attr_accessor :direction
    attr_reader :targets
    attr_accessor :side
    attr_accessor :xpos, :ypos

    # Create a new port for +ic+ with direction +direction+.
    def initialize(name,ic,direction,type = :signal)
      @name = name.to_s
      @ic = ic
      @direction = direction
      @type = type
      @targets = []
    end
  end


  # An IC block
  class IC

    EPSILON = 0.01

    attr_reader :name, :type, :parent, :children, :branches
    attr_reader :ports, :lports, :uports, :rports, :dports
    attr_accessor :xpos, :ypos, :width, :height
    attr_reader :box
    attr_reader :matrix, :rheights, :cwidths
    attr_reader :route_width, :route_height, :route_matrix
    attr_reader :routes
    attr_reader :port_width
    attr_reader :scale

    attr_reader :system # The instanciated system if it is an instance.

    def initialize(name, type, parent = nil, system = nil)
      @name = name.to_s
      @type = type.to_sym
      @parent = parent
      @parent.children << self if @parent
      @system = system
      @children = []
      @branches = []
      @ports = []
      @lports = []; @uports = []; @rports = []; @dports = []
      @xpos   = 0
      @ypos   = 0
      @width  = 0      # Width in number of routes
      @height = 0      # Height in number of routes
      @matrix   = [[]] # The matrix separting the children
      @retries = 100   # Number of resize of matrix and retry of route.
      @rheigths = []   # The heights of each in number of routes
      @cwidths  = []   # The widths of each column in number of routes
      # @border   = 2    # The IC border size for routing to external ports.
      @border   =  4   # The IC border size for routing to external ports.
      @cell_border = 4 # The cell border size
      @routes   = []   # The connection routes.
      @port_width = 3  # The width in tiles for a port
      @scale = 1.0     # The scale for SVG generation
    end

    # Set the scale for SVG generation.
    def scale=(scale)
      @scale = scale.to_f
    end

    # Add a new port.
    def add_port(name,direction, type=:signal)
      port = Port.new(name,self,direction,type)
      @ports << port
      return port
    end

    # Tell if the IC has a port named +name+
    def port?(name)
      name = name.to_s
      return @ports.any? {|p| p.name == name }
    end

    # Get a port by index.
    def [](idx)
      return @ports[idx]
    end

    # Connect two ports +p0+ and +p1+
    def connect(p0,p1)
      puts "connect #{p0.name} of #{p0.ic.name} to #{p1.name} of #{p1.ic.name}"
      p0.targets << p1
      p1.targets << p0
    end


    # Give the size of the IC in number of statements.
    def number_statements
      # Get the number from the branches.
      snum = @branches.reduce(0) do |sum,branch|
        sum + branch.number_statements
      end
      # Recurse on the child IC.
      snum += @children.reduce(0) do |sum,child|
        sum + child.number_statements
      end
    end


    # Quickly pre-place the children in a diagonal with coordinates < 0.5
    def preplace_children
      # num = @children.size * 2
      # @children.each_with_index do |child,i|
      #   child.xpos = i.to_f / num
      #   child.ypos = i.to_f / num
      # end
      num = 0
      num += 1 while num*num < @children.size
      idx = 0
      num.times do |j|
        num.times do |i|
          child = @children[j*num+i]
          return unless child # The end of the preplacement.
          child.xpos = i.to_f / num
          child.ypos = j.to_f / num
        end
      end
    end

    # Get the adjacent IC
    def adjacents
      return @ports.map {|p| p.targets.map {|t| t.ic } }.flatten
    end

    # # Get the charge of the IC
    # def charge
    #   return @ports.size
    # end

    # Compute the distance between to IC.
    def distance(ic0,ic1)
      res = Math.sqrt((ic0.xpos-ic1.xpos)**2+(ic0.ypos-ic1.ypos)**2)
      # res = (ic0.xpos-ic1.xpos).abs+(ic0.ypos-ic1.ypos).abs
      return res
    end

    def xrate(ic0,ic1)
      d = distance(ic0,ic1)
      # Ensure d is not 0 to avoid infinity.
      d = EPSILON if d < EPSILON
      res = (ic0.xpos-ic1.xpos)/d
      # puts "ic0.xpos=#{ic0.xpos} ic1.xpos=#{ic1.xpos} xrate=#{res}"
      return res
    end

    def yrate(ic0,ic1)
      d = distance(ic0,ic1)
      # Ensure d is not 0 to avoid infinity.
      d = EPSILON if d < EPSILON
      res = (ic0.ypos-ic1.ypos)/d
      return res
    end

    # Compute the X force applied on a (assumed) child +ic+.
    def forceX(ic, t=0.0)
      k = Math.sqrt(1.0/@children.size)
      # Repulive force.
      repulsive = @children.reduce(0.0) do |sum,child|
        # Skip ic as repulsive contribution.
        next sum if child == ic
        d = distance(ic,child)
        # Ensure d is not 0 to avoid infinity.
        d = EPSILON if d < EPSILON
        sum + ((k**2) / d) * xrate(ic,child)
      end
      # Limit repulsive to avoid explosion.
      puts "repulsive X=#{repulsive}"
      # Attractive force.
      attractive = (ic.adjacents).reduce(0.0) do |sum,adj|
        # Skip world as adjacent.
        next sum if adj == self
        # puts "ic=#{ic.name} adj=#{adj.name}"
        # Compute the attractive contribution of adj.
        d = distance(ic,adj)
        force = -(xrate(ic,adj)*d**2)/k
        sum + force
      end
      puts "attractive X=#{attractive}"
      # Returns the resulting force.
      return (repulsive + attractive)*Math.exp(-t)
    end

    # Compute the Y force applied on a (assumed) child +ic+.
    def forceY(ic, t=0.0)
      k = Math.sqrt(1.0/@children.size)
      # Repulive force.
      repulsive = @children.reduce(0.0) do |sum,child|
        # Skip ic as repulsive contribution
        next sum if child == ic
        d = distance(ic,child)
        # Ensure d is not 0 to avoid infinity.
        d = EPSILON if d < EPSILON
        sum + ((k**2) / d) * yrate(ic,child)
      end
      puts "repulsive Y=#{repulsive}"
      # Attractive force.
      attractive = (ic.adjacents).reduce(0.0) do |sum,adj|
        # Skip world as adjacent.
        next sum if adj == self
        # Compute the attractive contribution of adj.
        d = distance(ic,adj)
        force = -(yrate(ic,adj)*d**2)/k
        sum + force
      end
      puts "attractive Y=#{attractive}"
      # Returns the resulting force.
      # return (repulsive + attractive).round(@children.size)
      # return repulsive + attractive
      return (repulsive + attractive)*Math.exp(-t)
    end

    # Place the children.
    def place_children
      # epoch = @children.size*100
      epoch = 100
      delta = 1.0/@children.size
      epoch.times do |i|
        puts "epoch=#{i}"
        # Move the children according to the forces, 
        # # but make the first one to be on fixed position to avoid drift.
        # children[1..-1].each do |child|
        children.each do |child|
          puts "for child=#{child.name}"
          dx = delta * forceX(child,i.to_f)
          dy = delta * forceY(child,i.to_f)
          dx = 1.0 if dx > 1.0
          dx = -1.0 if dx < -1.0
          dy = 1.0 if dy > 1.0
          dy = -1.0 if dy < -1.0
          child.xpos += dx
          child.ypos += dy
          puts "Now child.xpos=#{child.xpos}"
          puts "Now child.ypos=#{child.ypos}"
        end
      end
    end


    # Select the side of the ports of the current IC according to the
    # position of their targets but limiting the input ports to
    # the left or up and output ports to the right or down.
    def side_ports
      # Resets the port sides.
      @lports.clear
      @uports.clear
      @rports.clear
      @dports.clear
      @ports.each do |port|
        if port.targets.empty? then
          puts "Dangling port: #{port.name} (of #{port.ic.name})"
          # Not connected port, put it on the side with the less ports.
          if port.direction == :input then
            if lports.size <= uports.size then
              port.side = LEFT
            else
              port.side = UP
            end
          else
            if rports.size <= dports.size then
              port.side = RIGHT
            else
              port.side = DOWN
            end
          end
        else
          # The port is connected.
          if port.direction == :input then
            # For now, use the first target only for deciding.
            d_left  = port.targets[0].ic.xpos - @box[0]
            d_up    = @box[3] - 
              port.targets[0].ic.ypos + port.targets[0].ic.height
            if d_left <= d_up then
              port.side = LEFT
            else
              port.side = UP
            end
          else
            d_right = @box[2] - 
              port.targets[0].ic.xpos + port.targets[0].ic.width
            d_down  = port.targets[0].ic.ypos - @box[1]
            if d_right <= d_down then
              port.side = RIGHT
            else
              port.side = DOWN
            end
          end
        end

        # Update the content of the sides of the children.
        case port.side
        when LEFT
          @lports << port
        when UP
          @uports << port
        when RIGHT
          @rports << port
        when DOWN
          @dports << port
        end
      end
    end


    # Select the side of the ports of the children according to the
    # position of their targets.
    def side_children
      @children.each do |child|
        puts "side_children for child=#{child.name} with #{child.ports.size} ports"
        # Resets the port sides.
        child.lports.clear
        child.uports.clear
        child.rports.clear
        child.dports.clear
        # Tell is a side is specifically used for input or output.
        # (Information used for certain types of IC).
        left_for, up_for, right_for, down_for = nil, nil, nil, nil
        # Recompute the ports sides.
        cx = child.xpos
        cy = child.ypos
        child.ports.each do |port|
          puts "For port: #{port.name} (of #{port.ic.name})"
          unless left_for || up_for || right_for || down_for then
            # The side is not forced.
            if port.targets.empty? then
              # Dangling port, put it on the side with the less ports.
              puts "Dangling port: #{port.name} (of #{port.ic.name})"
              pside_by_size = [[child.lports,LEFT],
                               [child.uports,UP],
                               [child.rports,RIGHT],
                               [child.dports,DOWN]].sort do |s0,s1| 
                                 s0[0].size <=> s1[0].size
                               end
              port.side = pside_by_size[0][1]
              # pside_by_size[0][0] << port
            else
              # For now, use the first target only for deciding.
              # Note: if the target is the top circuit (self) the the
              # sides are reversed.
              this_port = port.targets[0].ic == self
              if this_port then
                # Current IC, do not use its position, but the side.
                case port.targets[0].side
                when LEFT
                  tx = cx + 1.0
                  ty = cy
                when UP
                  tx = cx
                  ty = -cy - 1.0
                when RIGHT
                  tx = -cx - 1.0
                  ty = cy
                when DOWN
                  tx = cx
                  ty = cy + 1.0
                end
              else
                tx = port.targets[0].ic.xpos
                ty = port.targets[0].ic.ypos
              end
              dx = cx-tx
              dy = cy-ty
              if dx > 0 then
                if dy > 0 then
                  if dx > dy then
                    port.side = this_port ? RIGHT : LEFT
                  else
                    port.side = this_port ? UP : DOWN
                  end
                else
                  if dx > -dy then
                    port.side = this_port ? RIGHT : LEFT
                  else
                    port.side = this_port ? DOWN : UP
                  end
                end
              else
                if dy > 0 then
                  if -dx > dy then
                    port.side = this_port ? LEFT : RIGHT
                  else
                    port.side = this_port ? UP : DOWN
                  end
                else
                  if -dx > -dy then
                    port.side = this_port ? LEFT : RIGHT
                  else
                    port.side = this_port ? DOWN : UP
                  end
                end
              end
            end
          end
          # Case of IC of type assign or register if a side is used for
          # output, the opposite must be used for input, and vice versa.
          if child.type == :assign or child.type == :register then
            # puts "left_for=#{left_for} up_for=#{up_for} right_for=#{right_for} down_for=#{down_for}"
            if left_for then
              if port.direction == left_for then
                port.side = LEFT
              else
                port.side = RIGHT
              end
            elsif up_for then
              if port.direction == up_for then
                port.side = UP
              else
                port.side = DOWN
              end
            elsif right_for then
              if port.direction == right_for then
                port.side = RIGHT
              else
                port.side = LEFT
              end
            elsif down_for then
              if port.direction == down_for then
                port.side = DOWN
              else
                port.side = UP
              end
            end
            # Indicate a side is decided.
            case port.side
            when LEFT
              left_for = port.direction
            when UP
              up_for = port.direction
            when RIGHT
              right_for = port.direction
            when DOWN
              down_for = port.direction
            end
          end
          puts "Chosen side=#{port.side}"
          # Update the content of the sides of the children.
          case port.side
          when LEFT
            child.lports << port
          when UP
            child.uports << port
          when RIGHT
            child.rports << port
          when DOWN
            child.dports << port
          end
        end
      end
    end

    # Compute the bounding box of the current placement.
    def bounding_children
      x0 = 1/0.0
      x1 = -1/0.0
      y0 = 1/0.0
      y1 = -1/0.0
      @children.each do |child|
        x0 = child.xpos if child.xpos < x0
        x1 = child.xpos+child.width if child.xpos+child.width > x1
        y0 = child.ypos if child.ypos < y0
        y1 = child.ypos+child.height if child.ypos+child.height > y1
      end
      @box = [x0,y0,x1,y1]
      return @box
    end

    # Centers the global position of the current placement.
    def center_children
      x0,y0,x1,y1 = @box
      if x0 < x1 then
        dx = -x0 - (x1-x0) / 2.0
      else
        dx = -x1 - (x0-x1) / 2.0
      end
      if y0 < y1 then
        dy = -y0 - (y1-y0) / 2.0
      else
        dy = -y1 - (y0-y1) / 2.0
      end
      @children.each do |child| 
        child.xpos += dx
        child.ypos += dy
      end
    end

    # Compute the global height of the current placement.
    def height_children
      y0 = 1/0.0
      y1 = -1/0.0
      @children.each do |child|
        y0 = child.ypos if child.ypos < y0
        y1 = child.ypos if child.ypos > y1
      end
      return y1-y0
    end

    # Rotate the current placement by +t+ radiant
    def rotate_children(t)
      c = Math.cos(t)
      s = Math.sin(t)
      @children.each do |child|
        xpos = child.xpos
        ypos = child.ypos
        child.xpos = xpos*c + ypos*s
        child.ypos = -xpos*s + ypos*c
      end
    end

    # Rotate the current placement to minimize its global height.
    def minimize_height_children
      dt = 0.01
      t = dt
      minh = 1/0.0
      mint = t
      while t < 2*Math::PI do
        h = self.height_children
        if minh > h then
          mint = t
          minh = h
        end
        rotate_children(dt)
        t += dt
      end
      rotate_children(mint+dt)
    end


    # Compute the matrix that isolate each children in current placement.
    def matrix_children
      if @children.size == 1 then
        # Only one child.
        @matrix = [ [@children[0]] ]
        return @matrix
      end
      x0,y0,x1,y1 = @box
      # puts "box=#{@box}"
      width = x1-x0
      height = y1-y0
      nrows = 1
      ncols = 1
      @matrix = nil
      dir = :x
      separate = false
      while !separate do
        @matrix = []
        nrows.times { @matrix << [] }
        xstep = width / nrows
        ystep = height / ncols
        # puts "ncols=#{ncols} nrows=#{nrows} xstep=#{xstep} ystep=#{ystep}"
        separate = true
        @children.each do |child|
          col = ((child.xpos - x0) / xstep).floor
          col = ncols-1 if col >= ncols
          row = ((child.ypos - y0) / ystep).floor
          row = nrows-1 if row >= nrows
          # puts "xpos=#{child.xpos} ypos=#{child.ypos} col=#{col} row=#{row}"
          if matrix[row][col] then
            separate = false
            break
          else
            matrix[row][col] = child
          end
        end
        if dir == :x then
          ncols += 1
          dir = :y
        else
          nrows += 1
          dir = :x
        end
      end
      # Ensures the matrix rows are of identical size.
      ncols = @matrix.map {|row| row.size}.max
      @matrix.each {|row| row[ncols-1] = nil unless row[ncols-1] }

      # Compress the matrix by mergin colums and rows when possible
      # (i.e. not more than one children per cell.
      # For the rows.
      compressed= []
      nrows = @matrix.size
      ncols = @matrix[0].size
      puts "Before compression: nrows=#{nrows} ncols=#{ncols}"
      cidx = 0
      while(cidx < nrows) do
        # Add a new compressed row.
        compressed << @matrix[cidx].clone
        # Try to merge following rows to it.
        nidx = cidx + 1
        while (nidx < nrows) do
          if ncols.times.any? {|i| compressed[-1][i] and @matrix[nidx][i] } then
            # Cannot merge, stop compression of current row here.
            # (subtract 1 since cidx is increased after loop).
            cidx = nidx-1
            break
          else
            # Can merge, compress, and try to merge again.
            @matrix[nidx].each.with_index do |child,i|
              compressed[-1][i] = child if child
            end
            nidx += 1
            cidx += 1
          end
        end
        cidx += 1
      end
      # Update the matrix with the compression result.
      @matrix = compressed
      # Now compress for the columns.
      nrows = @matrix.size
      compressed= []
      nrows.times { compressed << [] }
      cidx = 0
      while(cidx < ncols) do
        # Add a new compressed column.
        @matrix.each_with_index {|row,i| compressed[i] << row[cidx] }
        # Try to merge following columns to it.
        nidx = cidx + 1
        while (nidx < ncols) do
          if nrows.times.any? {|i| compressed[i][-1] and @matrix[i][nidx] } then
            # Cannot merge, stop compression of current column here.
            # (subtract 1 since cidx is increased after loop).
            cidx = nidx-1
            break
          else
            # Can merge, compress, and try to merge again.
            @matrix.each.with_index do |row,i|
              child = row[nidx]
              compressed[i][-1] = child if child
            end
            nidx += 1
            cidx += 1
          end
        end
        cidx += 1
      end
      # Update the matrix with the compression result.
      @matrix = compressed

      puts "After compression: nrows=#{nrows} ncols=#{ncols}"

      # Returns the resulting matrix.
      return @matrix
    end

    # Compute the width and height in number of routes for each children 
    # in current placement and ports position.
    def size_children
      @children.each do |child|
        nl = child.lports.size * @port_width
        nu = child.uports.size * @port_width
        nr = child.rports.size * @port_width
        nd = child.dports.size * @port_width
        child.height = nl > nr ? nl : nr
        child.width  = nu > nd ? nu : nd
        puts "First width=#{child.width} height=#{child.height} [#{child.lports.size},#{child.uports.size},#{child.rports.size},#{child.dports.size}]"
        # Ensure IC have some thickness.
        if child.type != :register then
          # For general IC.
          # First at least one-port wide.
          child.height = @port_width if child.height < @port_width
          child.width = @port_width if child.width < @port_width
          # But enlarge if more than one port horizontally or
          # vertically for easier routing and readability.
          if child.lports.size + child.rports.size > 1 and
              child.height == @port_width and
              child.width == @port_width then
            child.width *= 2
          end
          if child.uports.size + child.dports.size > 1 and 
              child.width == @port_width and
              child.height == @port_width then
            child.height *= 2
          end
          # Also ensure the chip is wide enough.
          if child.type == :assign then
            # For an ALU case.
            if child.lports.size > 0 and child.height < 5 then
              child.height = 5
            end
            if child.uports.size > 0 and child.width < 5 then
              child.width = 5
            end
          elsif child.type == :memory then
            # For a memory case: it is square (it is a matrix).
            if child.width > child.height then
              child.height = child.width
            else
              child.width = child.height
            end
          else
            # For the other cases.
            if child.height + child.width < (@port_width+1)*2 then
              child.height += @port_width
            # Also enlarge if area too small.
            end
          end
        else
          # Register are thinner in their representation
          if child.ports.size <= 2 then
            # if they have no sub ports very thin.
            child.height = 2 if child.height < @port_width
            child.width = 2 if child.width < @port_width
          else
            # Otherwise wide enough to write the sub ports.
            child.height = 3 if child.height < @port_width
            child.width = 3 if child.width < @port_width
          end
          puts "for register: #{child.name} ports.size=#{child.ports.size}, width=#{child.width} height=#{child.height}"
        end

      end
    end

    # Normalize the size of the children so than children with
    # same number of statements have the same area, if
    # they are of the same kind, they have the same shape,
    # if the areas of the children are in the same order as their
    # number of statements.
    # However, registers and memory are not processed here (yet?).
    def normalize_size_children
      # Group the non-register and non-memory children by number of 
      # statements.
      by_stmnts = Hash.new {|h,k| h[k] = [] }
      @children.each do |child|
        if child.type != :register and child.type != :memory then
          by_stmnts[child.number_statements] << child
        end
      end
      area = 1     # Current area
      iW, iH = 1,1 # Current width and height of instance.
      pW, pH = 1,1 # Current width and height of process.
      # Ensure that these children of a group have the same area greater
      # than min_area, and the same shape if they are of the same kind.
      by_stmnts.each_key.sort.each do |num|
        ics = by_stmnts[num]
        puts "With number of statements: #{num} are base area=#{area}"
        # First compute the target area, and width and height of each type.
        ics.each do |ic|
          # Update the target area.
          n_area = ic.width * ic.height
          area = n_area if n_area > area
          # Depending on the type, update the target width and height.
          if ic.type == :instance then
            iW = ic.width if ic.width > iW
            iH = ic.height if ic.height > iH
            # Ensure the target area is reached.
            while iW*iH < area do
              # For instances, increase squarely.
              if iW <= iH then
                iW += 1
              else
                iH += 1
              end
            end
            # Reupdate the area.
            area = iW*iH
          else
            pW = ic.width if ic.width > pW
            pH = ic.height if ic.height > pH
            # Ensure the target area is reached.
            if ic.branches[0].type == :par then
              # For par processes, increase squarely.
              if pW <= pH then
                pW += 1
              else
                pH += 1
              end
            else
              # For non par processes, increase vertically.
              while pW*pH < area do
                pH += 1
              end
            end

            # Reupdate the area.
            area = pW*pH
          end
        end
        # Update the size of the ics.
        ics.each do |ic|
          if ic.type == :instance then
            ic.width = iW
            ic.height = iH
          else
            puts "For process #{ic.name} setting size from #{ic.width},#{ic.height} to #{pW},#{pH}"
            ic.width = pW
            ic.height = pH
          end
        end
        # Ensure the area increase when the number of statements is larger.
        area += 1
        puts "Now area=#{area}"
      end
    end

    # Compute the sizes of the matrix cells in number of routes,
    # then update the size of current IC for matching the matrix.
    def size_matrix
      # Compute the sizes that fits perfectly the children.
      @rheights = [ 0 ] * @matrix.size
      @cwidths = [ 0 ] * @matrix[0].size
      @matrix.each_with_index do |row,i|
        row.each_with_index do |child,j|
          next unless child
          rh = @rheights[i]
          cw = @cwidths[j]
          @cwidths[j]  = child.width if child.width > cw
          @rheights[i] = child.height if child.height > rh
        end
      end 
      # Increase the space to allow placing the routes.
      nrows = @matrix.size
      ncols = @matrix[0].size
      # @rheights.map! {|h| h + nrows*@cell_border*2 }
      @rheights.map! {|h| h + @cell_border*2 }
      @rheights[0] += @border
      @rheights[-1] += @border
      # @cwidths.map!  {|w| w + ncols*@cell_border*2 }
      @cwidths.map!  {|w| w + @cell_border*2 }
      @cwidths[0] += @border
      @cwidths[-1] += @border
      # Update the size of the current IC.
      @width = @cwidths.reduce(:+) 
      @height = @rheights.reduce(:+)
    end

    # Tune the placing of the children according to their size and
    # the matrix.
    def place_children_matrix
      # Auth: place the children in the center of their respective
      # cells.
      ypos = 0
      @matrix.each_with_index do |row,i|
        xpos = 0
        row.each_with_index do |child,j|
          if child then
            child.xpos = xpos + (@cwidths[j]-child.width) / 2
            child.ypos = ypos + (@rheights[i]-child.height) / 2
          end
          xpos += @cwidths[j]
        end
        ypos += @rheights[i]
      end
    end


    # Compute the position of the ports of each children according to
    # the position matrix, and also the ports of current IC.
    def place_ports_matrix
      # Preplace the ports, without optimization.
      (@children + [self]).each do |child|
        xpos = child.xpos
        ypos = child.ypos
        width = child.width
        height = child.height
        # The left ports.
        if child.type == :assign and child.lports.size == 1 then
          port = child.lports[0]
          # For assign types, the single ports are placed at the center.
          port.xpos = xpos
          port.ypos = ypos + height/2
        elsif child.lports.any? then
          step = child.height / child.lports.size
          child.lports.each_with_index do |port,i|
            puts "Preplace left port=#{port.name}"
            port.xpos = xpos
            port.ypos = ypos + i*step + step/2
          end
        end
        # The up ports.
        if child.type == :assign and child.uports.size == 1 then
          port = child.uports[0]
          # For assign types, the single ports are placed at the center.
          port.xpos = xpos + width/2
          port.ypos = ypos + height - 1
        elsif child.uports.any? then
          step = child.width / child.uports.size
          child.uports.each_with_index do |port,i|
            puts "Preplace up port=#{port.name}"
            port.xpos = xpos + i*step + step/2
            port.ypos = ypos + height - 1
          end
        end
        # The right ports.
        if child.type == :assign and child.rports.size == 1 then
          port = child.rports[0]
          # For assign types, the single ports are placed at the center.
          port.xpos = xpos + width - 1
          port.ypos = ypos + height/2
        elsif child.rports.any? then
          step = child.height / child.rports.size
          child.rports.each_with_index do |port,i|
            puts "Preplace right port=#{port.name}"
            port.xpos = xpos + width - 1
            port.ypos = ypos + i*step + step/2
          end
        end
        # The down ports.
        if child.type == :assign and child.dports.size == 1 then
          port = child.dports[0]
          # For assign types, the single ports are placed at the center.
          port.xpos = xpos + width/2
          port.ypos = ypos
        elsif child.dports.any? then
          step = child.width / child.dports.size
          child.dports.each_with_index do |port,i|
            puts "Preplace down port=#{port.name}"
            port.xpos = xpos + i*step + step/2
            port.ypos = ypos
          end
        end
      end

      # Optimize the place.
      @children.each do |child|
        xpos = child.xpos
        ypos = child.ypos
        width = child.width
        height = child.height

        # The left ports.
        if child.lports.size > 1 then
          step = child.height / child.lports.size
          lefts = child.lports.clone
          
          # Sort the ports by reverse order y difference with their
          # targets.
          lefts.sort! do |p0,p1| 
            p0.targets.uniq {|t| t.ic }.reduce(0) {|sum,t| sum + t.ypos - p0.ypos } <=>
            p1.targets.uniq {|t| t.ic }.reduce(0) {|sum,t| sum + t.ypos - p1.ypos }
          end
          # Apply the order.
          lefts.each_with_index do |port,i|
            port.xpos = xpos
            port.ypos = ypos + i*step + step/2
          end
        end

        # The up ports.
        if child.uports.size > 1 then
          step = child.width / child.uports.size
          ups = child.uports.clone
          
          # Sort the ports by reverse order x difference with their
          # targets.
          ups.sort! do |p0,p1| 
            p0.targets.uniq {|t| t.ic }.reduce(0) {|sum,t| sum + t.xpos - p0.xpos } <=>
            p1.targets.uniq {|t| t.ic }.reduce(0) {|sum,t| sum + t.xpos - p1.xpos }
          end
          # Apply the order.
          ups.each_with_index do |port,i|
            port.xpos = xpos + i*step + step/2
            port.ypos = ypos + height - 1
          end
        end

        # The right ports.
        if child.rports.size > 1 then
          step = child.height / child.rports.size
          rights = child.rports.clone

          # Sort the ports by reverse order y difference with their
          # targets.
          rights.sort! do |p0,p1| 
            # puts "p0=#{p0.name} p1=#{p1.name}"
            p0.targets.uniq {|t| t.ic }.reduce(0) {|sum,t| sum + t.ypos - p0.ypos } <=>
            p1.targets.uniq {|t| t.ic }.reduce(0) {|sum,t| sum + t.ypos - p1.ypos }
          end
          # Apply the order.
          rights.each_with_index do |port,i|
            port.xpos = xpos + width - 1
            port.ypos = ypos + i*step + step/2
          end
        end

        # The down ports.
        if child.dports.size > 1 then
          step = child.width / child.dports.size
          downs = child.dports.clone

          # Sort the ports by reverse order x difference with their
          # targets.
          downs.sort! do |p0,p1| 
            p0.targets.uniq {|t| t.ic }.reduce(0) {|sum,t| sum + t.xpos - p0.xpos } <=>
            p1.targets.uniq {|t| t.ic }.reduce(0) {|sum,t| sum + t.xpos - p1.xpos }
          end
          # Apply the order.
          downs.each_with_index do |port,i|
            port.xpos = xpos + i*step + step/2
            port.ypos = ypos
          end
        end
      end
    end

    # Fine-tune the placement of the ICs to increase alignment of connected
    # ports.
    # Also fine-place the ports of the current IC to also increase the
    # aligment of connected ports.
    def place_children_port_matrix
      # xpos, ypos = 0, 0
      # @matrix.each_with_index do |row,i|
      #   xpos = 0
      #   mypos = ypos + @rheights[i]
      #   row.each_with_index do |child,j|
      #     mxpos = xpos + @cwidths[j]
      #     if child then
      #       # Tune x position.
      #       # Find the best delta.
      #       bdx = 0       # Best y delta
      #       bcost = 1/0.0 # Best score
      #       xpos_in_cell = child.xpos - xpos  # Initial position in cell
      #       xpos_in_cell -= @border if j == 0 # Do not go inside the border
      #       (@cwidths[j]-child.width).times do |dx|
      #         dx = dx - xpos_in_cell # Adjust delta x to the initial position
      #         cost = child.ports.reduce(0) do |sum,port|
      #           pxpos = port.xpos + dx
      #           sum + port.targets.reduce(0) do |subsum,tport|
      #             # There is cost when the port is not align with the target.
      #             if (port.side == LEFT and tport.side == RIGHT) or
      #                 (port.side == UP and tport.side == UP) then
      #               # For left to right or up yo up connections, 
      #               # the first side should be 2 tiles on the left for
      #               # straight wire or avoiding routing conjestion.
      #               subsum + (pxpos-tport.xpos-2) != 0 ? 1 : 0
      #             elsif (port.side == RIGHT and tport.side == LEFT) or
      #                 (port.side == DOWN and tport.side == DOWN) then
      #               # For right to left or down to down connections,
      #               # the first side should be 2 tiles on the right for
      #               # straight wire or avoiding routing conjestion.
      #               subsum + (pxpos-tport.xpos+2) != 0 ? 1 : 0
      #             else
      #               # Otherwise, perfect aligment is the best.
      #               subsum + (pxpos-tport.xpos) != 0 ? 1 : 0
      #             end
      #           end
      #         end
      #         if cost < bcost then
      #           bcost = cost
      #           bdx = dx
      #         end
      #       end
      #       # Ensure the child does not goes out of its cell.
      #       if child.xpos + bdx < xpos then
      #         bdx = xpos - child.xpos
      #       elsif child.xpos + child.width + bdx >= mxpos then
      #         bdx = mxpos - child.xpos - child.width - 1
      #       end
      #       # Apply the best delta.
      #       child.xpos += bdx
      #       # Update the ports position.
      #       child.ports.each {|port| port.xpos += bdx }

      #       # Tune y position.
      #       puts "for child=#{child.name}"
      #       # Find the best delta.
      #       bdy = 0       # Best x delta
      #       bcost = 1/0.0 # Best score
      #       ypos_in_cell = child.ypos - ypos  # Initial position in cell
      #       ypos_in_cell -= @border if i == 0 # Do not go to the outer border
      #       (@rheights[i]-child.height).times do |dy|
      #         dy = dy - ypos_in_cell # Adjust dela y with initial position
      #         cost = child.ports.reduce(0) do |sum,port|
      #           pypos = port.ypos + dy
      #           sum + port.targets.reduce(0) do |subsum,tport|
      #             # There is cost when the port is not align with the target.
      #             if (port.side == UP and tport.side == DOWN) or
      #                 (port.side == RIGHT and tport.side == RIGHT) then
      #               # For up to down or right to right connections,
      #               # the first side should be 2 tiles on the right for
      #               # straight wire or avoiding routing conjestion.
      #               subsum + (pypos-tport.ypos+2) != 0 ? 1 : 0
      #             elsif (port.side == DOWN and tport.side == UP) or
      #                 (port.side == LEFT and tport.side == LEFT) then
      #               # For down to up or left to left connections,
      #               # the forst side should be 2 tiles on the down for
      #               # straight wire or avoiding routing conjestion.
      #               subsum + (pypos-tport.ypos-2) != 0 ? 1 : 0
      #             else
      #               subsum + (pypos-tport.ypos) != 0 ? 1 : 0 
      #             end
      #           end
      #         end
      #         if cost < bcost then
      #           bcost = cost
      #           bdy = dy
      #         end
      #       end
      #       # puts "mypos=#{mypos} child.ypos=#{child.ypos} bdy=#{bdy}"
      #       # Ensure the child does not goes out of its cell.
      #       if child.ypos + bdy < ypos then
      #         bdy = ypos - child.ypos 
      #       elsif child.ypos + child.height + bdy >= mypos then
      #         bdy = mypos - child.ypos - child.height - 1
      #       end
      #       # Apply the best delta.
      #       child.ypos += bdy
      #       # Update the ports position.
      #       child.ports.each {|port| port.ypos += bdy }
      #     end
      #     xpos += @cwidths[j]
      #   end
      #   ypos += @rheights[i]
      # end

      # First prepare the algorthims: sort the children for
      # vertical and horizontal processing and locate their
      # respective row and column intervals.
      # Sort the children by decreasing number of left and right ports, 
      # for placing the one with more freedom last.
      vert_sorted = @children.sort do |c0,c1|
        ([c1.lports.size,c1.rports.size]).max <=> 
        ([c0.lports.size,c0.rports.size]).max
      end
      hori_sorted = @children.sort do |c0,c1|
        ([c1.uports.size,c1.dports.size]).max <=> 
        ([c0.uports.size,c0.dports.size]).max
      end
      # Get the matrix row and column intervals for each children in order.
      rRange = []
      cRange = []
      xpos, ypos = 0, 0
      @matrix.each_with_index do |row,i|
        xpos = 0
        mypos = ypos + @rheights[i]
        row.each_with_index do |child,j|
          mxpos = xpos + @cwidths[j]
          if child then
            iV = vert_sorted.index(child)
            iH = hori_sorted.index(child)
            fxpos = xpos == 0 ? xpos + @border/2 : xpos + @cell_border/2
            fypos = ypos == 0 ? ypos + @border/2 : ypos + @cell_border/2
            lxpos = mxpos - @cell_border/2
            lypos = mypos - @cell_border/2
            rRange[iV] = fypos..lypos
            cRange[iH] = fxpos..lxpos
            # puts "For child=#{child.name} iV=#{iV} iH=#{iH} rRange=#{rRange[iV]} cRange=#{cRange[iH]}"
          end
          xpos += @cwidths[j]
        end
        ypos += @rheights[i]
      end

      # Tune the vertical placement of each child.
      vert_sorted.each_with_index do |child,i|
        # Tune y position.
        # puts "for child=#{child.name} child.ypos=#{child.ypos} vertical idx=#{i} rRange[i]=#{rRange[i]}"
        # Find the best delta.
        bdy = 0       # Best y delta
        bcost = 1/0.0 # Best score
        mypos = rRange[i].last
        ypos = rRange[i].first
        ypos_in_cell = child.ypos - ypos  # Initial position in cell
        # ypos_in_cell -= @border if i == 0 # Do not go to the outer border
        # (@rheights[i]-child.height).times do |dy|
        (rRange[i].size-child.height).times do |dy|
          # puts "dy=#{dy}"
          dy = dy - ypos_in_cell # Adjust detla y with initial position
          cost = child.ports.reduce(0) do |sum,port|
            pypos = port.ypos + dy
            sum + port.targets.reduce(0) do |subsum,tport|
              # There is cost when the port is not align with the target.
              if (port.side == UP and tport.side == DOWN) or
                  (port.side == RIGHT and tport.side == RIGHT) then
                # For up to down or right to right connections,
                # the first side should be 2 tiles on the right for
                # straight wire or avoiding routing conjestion.
                subsum + (pypos-tport.ypos+2) != 0 ? 1 : 0
              elsif (port.side == DOWN and tport.side == UP) or
                (port.side == LEFT and tport.side == LEFT) then
                # For down to up or left to left connections,
                # the forst side should be 2 tiles on the down for
                # straight wire or avoiding routing conjestion.
                subsum + (pypos-tport.ypos-2) != 0 ? 1 : 0
              else
                subsum + (pypos-tport.ypos) != 0 ? 1 : 0 
              end
            end
          end
          if cost < bcost then
            bcost = cost
            bdy = dy
          end
        end
        # puts "mypos=#{mypos} child.ypos=#{child.ypos} bdy=#{bdy}"
        # Ensure the child does not goes out of its cell.
        if child.ypos + bdy < ypos then
          bdy = ypos - child.ypos 
        elsif child.ypos + child.height + bdy >= mypos then
          bdy = mypos - child.ypos - child.height - 1
        end
        # Apply the best delta.
        child.ypos += bdy
        # puts "child new ypos=#{child.ypos} (bdy=#{bdy})"
        # Update the ports position.
        child.ports.each {|port| port.ypos += bdy }
      end
      
      # Tune the horizontal placement of each child.
      hori_sorted.each_with_index do |child,i|
        # puts "for child=#{child.name} child.xpos=#{child.ypos} horizontal idx=#{i} cRange[i]=#{cRange[i]}"
        # Tune x position.
        # puts "for child=#{child.name}"
        # Find the best delta.
        bdx = 0       # Best x delta
        bcost = 1/0.0 # Best score
        xpos = cRange[i].first
        mxpos = cRange[i].last
        xpos_in_cell = child.xpos - xpos  # Initial position in cell
        xpos_in_cell -= @border if i == 0 # Do not go to the outer border
        # (@cwidths[i]-child.width).times do |dx|
        (cRange[i].size-child.width).times do |dx|
          dx = dx - xpos_in_cell # Adjust dela x with initial position
          cost = child.ports.reduce(0) do |sum,port|
            pxpos = port.xpos + dx
            sum + port.targets.reduce(0) do |subsum,tport|
              # There is cost when the port is not align with the target.
              if (port.side == LEFT and tport.side == RIGHT) or
                  (port.side == UP and tport.side == UP) then
                # For left to right or up yo up connections, 
                # the first side should be 2 tiles on the left for
                # straight wire or avoiding routing conjestion.
                subsum + (pxpos-tport.xpos-2) != 0 ? 1 : 0
              elsif (port.side == RIGHT and tport.side == LEFT) or
                (port.side == DOWN and tport.side == DOWN) then
                # For right to left or down to down connections,
                # the first side should be 2 tiles on the right for
                # straight wire or avoiding routing conjestion.
                subsum + (pxpos-tport.xpos+2) != 0 ? 1 : 0
              else
                # Otherwise, perfect aligment is the best.
                subsum + (pxpos-tport.xpos) != 0 ? 1 : 0
              end
            end
          end
          if cost < bcost then
            bcost = cost
            bdx = dx
          end
        end
        # puts "mxpos=#{mxpos} child.xpos=#{child.ypos} bdx=#{bdx}"
        # Ensure the child does not goes out of its cell.
        if child.xpos + bdx < xpos then
          bdx = xpos - child.xpos 
        elsif child.xpos + child.width + bdx >= mxpos then
          bdx = mxpos - child.xpos - child.width - 1
        end
        # Apply the best delta.
        child.xpos += bdx
        # puts "child new xpos=#{child.xpos} (bdx=#{bdx})"
        # Update the ports position.
        child.ports.each {|port| port.xpos += bdx }
      end

      # Also place the ports of the current IC.
      poses = []
      @lports.each do |lport|
        lport.ypos = lport.targets[0].ypos
        lport.ypos += 1 if lport.targets[0].side == UP
        lport.ypos -= 1 if lport.targets[0].side == DOWN
        # Ensure ports do not overlap.
        while poses[lport.ypos] do
          lport.ypos += 1
          lport.ypos = 0 if lport.ypos >= @height
        end
        poses[lport.ypos] = lport
      end
      poses = []
      @uports.each do |uport|
        uport.xpos = uport.targets[0].xpos
        uport.xpos -= 1 if uport.targets[0].side == LEFT
        uport.xpos += 1 if uport.targets[0].side == RIGHT
        puts "Now uport.xpos=#{uport.xpos}"
        # Ensure ports do not overlap.
        while poses[uport.xpos] do
          uport.xpos += 1
          uport.xpos = 0 if uport.xpos >= @width
        end
        poses[uport.xpos] = uport
      end
      poses = []
      @rports.each do |rport|
        rport.ypos = rport.targets[0].ypos
        rport.ypos += 1 if rport.targets[0].side == UP
        rport.ypos -= 1 if rport.targets[0].side == DOWN
        # Ensure ports do not overlap.
        while poses[rport.ypos] do
          rport.ypos += 1
          rport.ypos = 0 if rport.ypos >= @height
        end
        poses[rport.ypos] = rport
      end
      poses = []
      @dports.each do |dport|
        dport.xpos = dport.targets[0].xpos
        dport.xpos -= 1 if dport.targets[0].side == LEFT
        dport.xpos += 1 if dport.targets[0].side == RIGHT
        # Ensure ports do not overlap.
        while poses[dport.xpos] do
          dport.xpos += 1
          dport.xpos = 0 if dport.xpos >= @width
        end
        poses[dport.xpos] = dport
      end
    end

    # # Increase the rows heights by +dh+ of the matrix and update all the 
    # # ICs and ports position accordingling.
    # def increase_matrix_rows(dh)
    #   acc = 0
    #   @matrix.each_with_index do |row,i|
    #     # Update the row width.
    #     rheights[i] += dh
    #     # Update the position of the children of this row, and their ports.
    #     row.each do |child|
    #       next unless child
    #       puts "For child=#{child.name} before increase ypos=#{child.ypos}"
    #       child.ypos += acc
    #       puts "After increase ypos=#{child.ypos}"
    #       child.ports.each {|p| p.ypos += acc }
    #     end
    #     acc += dh
    #   end
    #   # And update the world height.
    #   @height = @rheights.reduce(:+) 
    # end

    # # Increase the columns width by +dw+ of the matrix and update all the
    # # ICs and ports position accordingling.
    # def increase_matrix_cols(dw)
    #   acc = 0
    #   @cwidths.size.times do |j|
    #     # Update the column width.
    #     cwidths[j] += dw
    #     # Update the position of the children of this column, and their
    #     # ports.
    #     @matrix.each do |row|
    #       child = row[j]
    #       if child then
    #         puts "For child=#{child.name} before increase xpos=#{child.xpos}"
    #         child.xpos += acc
    #         puts "After increase xpos=#{child.xpos}"
    #         child.ports.each {|p| p.xpos += acc }
    #       end
    #     end
    #     acc += dw
    #   end
    #   # And update the world width.
    #   @width = @cwidths.reduce(:+) 
    # end

    # Now for the routing.

    # A routing tile.
    class Tile
      attr_reader :routes
      attr_accessor :ic

      attr_reader :wires # The wires to draw on the tile.
      attr_reader :dots  # The dots to draw on the tile.

      def initialize
        @routes = []
        @ic = nil
        @wires = []
        @dots = []
      end

      # Give the direction of the route from +port+ if any.
      def dir(port)
        return BLOCKED if ic
        @routes.each do |p0,p1,dir|
          return dir if p0 == port
        end
        return nil
      end

      # Tell if the tile is free for a +port+ route from up.
      # def free_from_up?(port)
      def free_from_up?(port0,port1)
        # puts "up? in ic: #{ic.name}..." if ic
        # IC tile, not free.
        return false if ic
        # Are there any conflicting routes.
        @routes.each do |p0,p1,dir|
          # puts "up? port0=#{port0.name} port1=#{port1.name} p0=#{p0.name} p1=#{p1.name}"
          # next if p0 == port or p1 == port
          next if p0 == port0 or p1 == port0 or p0 == port1 or p1 == port1
          # puts "No skip"
          return false if (dir & (UP|DOWN) != 0)
        end
        return true
      end

      # Tell if the tile is free for a +port+ route from left.
      # def free_from_left?(port)
      def free_from_left?(port0,port1)
        # puts "left? in ic: #{ic.name}..." if ic
        # IC tile, not free.
        return false if ic
        # Are there any conflicting routes.
        @routes.each do |p0,p1,dir|
          # puts "left? port0=#{port0.name} port1=#{port1.name} p0=#{p0.name} p1=#{p1.name}"
          # next if p0 == port or p1 == port
          next if p0 == port0 or p1 == port0 or p0 == port1 or p1 == port1
          # puts "No skip"
          return false if (dir & (LEFT|RIGHT) != 0)
        end
        return true
      end

      # Tell if the tile is free for a +port+ route from right.
      alias_method :free_from_right?, :free_from_left?

      # Tell if the tile is free for a +port+ route from down.
      alias_method :free_from_down?, :free_from_up?

      # # Tell if the routes on tile fork for connection between ports
      # # +port0+ and +port1+.
      # def fork?(port0,port1)
      #   has_left  = false
      #   has_up    = false
      #   has_right = false
      #   has_down  = false
      #   self.routes.each do |p0,p1,dir|
      #     if p0 == port0 or p0 == port1 then
      #       case dir
      #       when LEFT
      #         has_left = true
      #       when UP
      #         has_up = true
      #       when RIGHT
      #         has_right = true
      #       when DOWN
      #         has_down = true
      #       end
      #     end
      #   end
      #   return [has_left, has_up, has_right, has_down].count {|d| d } > 2
      # end
    end

    # A route.
    class Route
      attr_reader :ports, :path

      def initialize(*ports)
        @ports = ports
        @path = []
      end
    end

    # Create the global routing matrix.
    def init_route
      # Build the matrix.
      @route_height = @rheights.reduce(:+)
      @route_width  = @cwidths.reduce(:+)
      @route_matrix = []
      @route_height.times do
        row = []
        @route_matrix << row
        @route_width.times { row << Tile.new }
      end
      # Fill it with the ic.
      puts "@route_width=#{@route_width} @route_height=#{@route_height}"
      @children.each do |child|
        x0 = child.xpos
        y0 = child.ypos
        # puts "child=#{child.name} x0=#{x0} y0=#{y0} child.height=#{child.height} child.width=#{child.width}"
        child.height.times do |y|
          child.width.times do |x|
            @route_matrix[y0+y][x0+x].ic = child
          end
        end
      end
    end


    # Compute the taxi cab distance between +pos0+ and +pos1+
    def taxi_distance(pos0,pos1)
      return (pos0[0] - pos1[0]).abs + (pos0[1] - pos1[1]).abs
    end

    # Check if there is a port at location +pos+ in +side+ that conflict
    # with both +port0+ and +port1+.
    def ic_port_conflict(port0,port1,pos,side)
      return false unless @route_matrix[pos[1]]
      return false unless @route_matrix[pos[1]][pos[0]]
      ic = @route_matrix[pos[1]][pos[0]].ic
      return false unless ic # No IC here, so not possible port to conflict
      # There is an IC get the port at pos from side if any.
      p = nil
      case side
      when LEFT
        port = ic.lports.find {|p| p.xpos==pos[0] && p.ypos==pos[1] }
      when UP
        port = ic.uports.find {|p| p.xpos==pos[0] && p.ypos==pos[1] }
      when RIGHT
        port = ic.rports.find {|p| p.xpos==pos[0] && p.ypos==pos[1] }
      when DOWN
        port = ic.dports.find {|p| p.xpos==pos[0] && p.ypos==pos[1] }
      end
      if port and port != port0 and port != port1 then
        return true
      else
        return false
      end
    end

    # Get the neighbor free positions for port.
    # def free_neighbors(port,cpos)
    def free_neighbors(port0,port1,cpos)
      res = []
      # Left neighbor.
      lpos = [cpos[0]-1,cpos[1]]
      if lpos[0] >= 0 then
        elem = @route_matrix[lpos[1]][lpos[0]]
        # res << lpos if elem.free_from_right?(port)
        res << lpos if elem.free_from_right?(port0,port1) and
          !ic_port_conflict(port0,port1,[lpos[0]-1,lpos[1]],RIGHT)
      end
      # Up neighbor.
      upos = [cpos[0],cpos[1]+1]
      if upos[1] < @route_height then
        elem = @route_matrix[upos[1]][upos[0]]
        # res << upos if elem.free_from_down?(port)
        res << upos if elem.free_from_down?(port0,port1) and
          !ic_port_conflict(port0,port1,[upos[0],upos[1]+1],DOWN)
      end
      # Right neighbor.
      rpos = [cpos[0]+1,cpos[1]]
      if rpos[0] < @route_width then
        elem = @route_matrix[rpos[1]][rpos[0]]
        # res << rpos if elem.free_from_left?(port)
        res << rpos if elem.free_from_left?(port0,port1) and
          !ic_port_conflict(port0,port1,[rpos[0]+1,rpos[1]],LEFT)
      end
      # Down neighbor.
      dpos = [cpos[0],cpos[1]-1]
      if dpos[1] >= 0 then
        elem = @route_matrix[dpos[1]][dpos[0]]
        # res << dpos if elem.free_from_up?(port)
        res << dpos if elem.free_from_up?(port0,port1) and
          !ic_port_conflict(port0,port1,[dpos[0],dpos[1]-1],UP)
      end
      # Return the free neigbor positions.
      return res
    end

    # Compute the cost of a position +pos+ relatively to +port+.
    def cost_position(port,pos)
      elem = @route_matrix[pos[1]][pos[0]]
      return (elem == nil or elem == port) ? 0 : 1
    end

    # Reconstruct the path and make the connection from +port0+ to +port1+
    # using the +from+ table for back tracking from position +pos+
    def reconstruct_path(port0,port1,from,pos)
      # puts "reconstruct_path for #{port0} and #{port1}"
      # Create the resulting route.
      route = Route.new(port0,port1)
      # Reconstruct the path.
      path = route.path 
      path.unshift(pos)
      apos = pos
      while from.key?(pos) do
        pos = from[pos]
        if (pos == apos) then
          puts "Loop detected for path from #{port0.name} of #{port0.ic.name} to #{port1.name} of #{port1.ic.name}"
          exit
          break
        end
        apos = pos
        path.unshift(pos)
      end
      # Compute previous position: within IC since starting.
      ppos = []
      case port0.side
      when LEFT
        ppos = [pos[0]+1,pos[1]]
      when UP
        ppos = [pos[0],pos[1]-1]
      when RIGHT
        ppos = [pos[0]-1,pos[1]]
      when DOWN
        ppos = [pos[0],pos[1]+1]
      end
      # Write it into the route matrix.
      path.each do |pos|
        # Compute the direction when entering the tile (dir),
        # and the direction when leaving the previous tile (edir).
        if pos[0] > ppos[0] then
          dir = LEFT
          edir = RIGHT
        elsif pos[0] < ppos[0] then
          dir = RIGHT
          edir = LEFT
        elsif pos[1] > ppos[1] then
          dir = UP
          edir = DOWN
        else
          dir = DOWN
          edir = UP
        end
        # Update the route on the tile.
        @route_matrix[pos[1]][pos[0]].routes << [port0,port1,dir]
        # And on the previous tile.
        @route_matrix[ppos[1]][ppos[0]].routes << [port0,port1,edir]
        # Next step.
        ppos = pos
      end
      # Also return the path, it will be used for speeding up rendering.
      return route
    end

    # Tell if two positions touch each other (diagonal touch is not
    # considered valid).
    def touch?(pos0,pos1)
      return (((pos0[0]-pos1[0]).abs < 2 and pos0[1] == pos1[1]) or
              ((pos0[1]-pos1[1]).abs < 2 and pos0[0] == pos1[0]))
    end

    # Route from +port0+ to +port1.
    # NOTE: uses the A* algorithm with taxi cab distance.
    def connection_route(port0,port1)
      puts "From port: #{port0.name} (ic: #{port0.ic.name}) " + "to port: #{port1.name} (ic: #{port1.ic.name})"

      pos0 = [port0.xpos,port0.ypos]
      pos1 = [port1.xpos,port1.ypos]
      oset = [pos0]
      # oset = Set.new
      oset << pos0
      from = { }
      # gscore = Hash.new(1/0.0)
      # gscore[pos0] = 0
      gscore = Array.new(@route_matrix.size) { Array.new(@route_matrix[0].size) { 1/0.0 } }
      gscore[pos0[1]][pos0[0]] = 0
      # fscore = Hash.new(1/0.0)
      # fscore[pos0] = taxi_distance(pos0,pos1)
      fscore = Array.new(@route_matrix.size) { [] }
      fscore[pos0[1]][pos0[0]] = taxi_distance(pos0,pos1)
      while oset.any? do
        # Pick the position from oset with the minimum fscore.
        cpos = nil          # Current position
        mscore = 1/0.0      # Minimum score
        # oset.each do |pos|
        #   # score = fscore[pos]
        #   score = fscore[pos[1]][pos[0]]
        #   if score < mscore then
        #     mscore = score
        #     cpos = pos
        #   end
        # end
        # The best score is necessily at the end of oset.
        cpos = oset.pop
        # puts "cpos=#{cpos}"
        if touch?(cpos,pos1) then
          # The goal is reached.
          from[pos1] = cpos
          return reconstruct_path(port0,port1,from,pos1)
        end
        # oset.delete(cpos) # No need anymore since pop
        # Get the neighbor positions for port.
        # poses = free_neighbors(port0,cpos)
        poses = free_neighbors(port0,port1,cpos)
        poses.each do |pos|
          # Try it.
          # tscore = gscore[cpos] + cost_position(port0,pos)
          tscore = gscore[cpos[1]][cpos[0]] + cost_position(port0,pos)
          # if tscore < gscore[pos] then
          if tscore < gscore[pos[1]][pos[0]] then
            # This path to neigbor is better than any previous one, keep it.
            from[pos]   = cpos
            # gscore[pos] = tscore
            gscore[pos[1]][pos[0]] = tscore
            # fscore[pos] = tscore + taxi_distance(pos,pos1)
            fscore[pos[1]][pos[0]] = tscore + taxi_distance(pos,pos1)
            # oset << pos unless oset.include?(pos)
            idx = oset.bsearch_index {|p| fscore[p[1]][p[0]] <= fscore[pos[1]][pos[0]] }
            if idx then
              oset.insert(idx,pos)
            else
              oset << pos
            end
          end
        end
      end
      return false
    end

    # Perform the route for the placed children.
    # Return false in case of failure.
    def route_children
      # Gather the ports to route, in case of failure the list will be
      # reordered and routing will be tried again.
      to_route = []
      @children.each  do |child|
        child.ports.each do |port|
          # Route start from output or inout.
          next if port.direction == :input 
          to_route << port
        end
      end
      # Also for current IC for routes to external, but this time using
      # input or inout as starting point.
      @ports.each do |port|
        # Route start from input or inout.
        next if port.direction == :output
        to_route << port
      end
      # Also handle the same direction output ports joined together
      # (Supported by HDLRuby).
      @ports.each do |port|
        next if port.direction != :output
        if port.targets.all? { |p| !to_route.include?(p) } then
          to_route << port
        end
      end
      # Do the routing.
      failed = nil
      retried = Hash.new {|h,k| h[k] = 0 } # The count of already retried ports.
      # StackProf.run(mode: :cpu, out: 'stackprof-output.dump') do
      # to_route.size.times do |epoch|
      (to_route.size/2).times do |epoch|
        puts "Routing epoch=#{epoch}..."
        self.init_route    # Reinitialize the route matrix.
        routed_pairs = []  # The list of already routed pair of ports.
        @routes = []       # The list of created routes.
        # Do the routing.
        failed = nil
        to_route.each.each do |p0|
          p0.targets.each do |p1|
            next if routed_pairs.include?([p0,p1])
            path = connection_route(p0,p1)
            unless path
              failed = p0
              puts "Could not route from #{p0.name} (IC: #{p0.ic.name}) to #{p1.name}(IC: #{p1.ic.name})"
              break
            end
            routed_pairs << [p0,p1]
            @routes << path
            # And for the case of inouts:
            routed_pairs << [p1,p0] if p1.direction != :input 
          end
          break if failed
        end
        if failed then
          # Was it the first port that failed?
          if to_route.first == failed then
            # Yes, no need to go on.
            break
          end
          # Put the failed port at the head of the list to route and
          # try again.
          to_route.delete(failed)
          retried[failed] += 1
          if retried[failed] > 10 then
            # The failed port has already been retried twice,
            # no need to insist.
            break
          end
          to_route.unshift(failed)
        else
          # Success.
          break
        end
      end
      # end #Stackprof
      # Failure.
      if failed then
        return false
      else
        return true
      end
    end


    # Generate the wiring and connection content of the tiles.
    def wire_route_tiles
      # The table of route segments per tiles, used for determining the
      # connection points.
      tile_segs = Hash.new {|h,k| h[k] = [] }

      # Wire the routes.
      @routes.each do |route|
        port0 = route.ports[0] # The routed start port.
        port1 = route.ports[1] # The routed end port.
        # Add the start and end port position to the route.
        sport,eport = *route.ports
        if sport.ic != self then
          route.path.unshift([sport.xpos,sport.ypos])
        else
          case sport.side
          when LEFT
            route.path.unshift([sport.xpos-1,sport.ypos])
          when UP
            route.path.unshift([sport.xpos,sport.ypos+1])
          when RIGHT
            route.path.unshift([sport.xpos+1,sport.ypos])
          when DOWN
            route.path.unshift([sport.xpos,sport.ypos-1])
          end
        end
        if eport.ic != self then
          route.path.append([eport.xpos,eport.ypos])
        else
          case eport.side
          when LEFT
            route.path.append([eport.xpos-1,eport.ypos])
          when UP
            route.path.append([eport.xpos,eport.ypos+1])
          when RIGHT
            route.path.append([eport.xpos+1,eport.ypos])
          when DOWN
            route.path.append([eport.xpos,eport.ypos-1])
          end
        end
        route.path.each_cons(3).with_index do |((x0,y0),(x1,y1),(x2,y2)),i|
          # puts "x0,y0=#{x0},#{y0} x1,y1=#{x1},#{y1} x2,y2=#{x2},#{y2}"
          # puts "i=#{i} dir=#{dir}"
          dir = 0
          dir |= RIGHT if x0 > x1 || x1 < x2
          dir |= LEFT  if x0 < x1 || x1 > x2
          dir |= UP    if y0 > y1 || y1 < y2
          dir |= DOWN  if y0 < y1 || y1 > y2
          # Set the wire.
          @route_matrix[y1][x1].wires << dir
          # Update the list of segments. It will be used later for 
          # determining the connection points.
          # NOTE: if it is a head or tail of route, there is no dir.
          tile_segs[[x1,y1]] << dir if dir
        end
      end

      # Generate the connection points.
      tile_segs.each do |(x,y),segs|
        # Keep one uniq element per undirected direction.
        # segs = segs.map { |dir| UNDIRECTED[dir] }.uniq
        segs = segs.uniq
        # Determin the fork position if any.
        puts "segs=#{segs}" if segs.size > 1
        fork_pos = nil
        if    (segs & [ LEFT|RIGHT, LEFT|UP]).size == 2 then
          fork_pos = LEFT
        elsif (segs & [ LEFT|RIGHT, LEFT|DOWN]).size == 2 then
          fork_pos = LEFT
        elsif (segs & [ LEFT|UP, LEFT|DOWN]).size == 2 then
          fork_pos = LEFT
        elsif (segs & [ UP|DOWN, UP|LEFT]).size == 2 then
          fork_pos = UP
        elsif (segs & [ UP|DOWN, UP|RIGHT]).size == 2 then
          fork_pos = UP
        elsif (segs & [ UP|LEFT, UP|RIGHT]).size == 2 then
          fork_pos = UP
        elsif (segs & [ RIGHT|LEFT, RIGHT|UP]).size == 2 then
          fork_pos = RIGHT
        elsif (segs & [ RIGHT|LEFT, RIGHT|DOWN]).size == 2 then
          fork_pos = RIGHT
        elsif (segs & [ RIGHT|UP, RIGHT|DOWN]).size == 2 then
          fork_pos = RIGHT
        elsif (segs & [ DOWN|UP, DOWN|LEFT]).size == 2 then
          fork_pos = DOWN
        elsif (segs & [ DOWN|UP, DOWN|RIGHT]).size == 2 then
          fork_pos = DOWN
        elsif (segs & [ DOWN|LEFT, DOWN|RIGHT]).size == 2 then
          fork_pos = DOWN
        end
        if fork_pos then
          puts "x=#{x} y=#{y} segs=#{segs} fork_pos=#{fork_pos}"
          # Set the connection point.
          @route_matrix[y][x].dots << fork_pos
        end
      end
    end


      # Compress the route matrix and update the position of the objects
      # accordignly.
    def compress_route_tiles
      # First record the position of each port of current IC for
      # easily updating their position.
      lports_row = []
      self.lports.each {|p| lports_row[p.ypos] = p }
      uports_col = []
      self.uports.each {|p| uports_col[p.xpos] = p }
      rports_row = []
      self.rports.each {|p| rports_row[p.ypos] = p }
      dports_col = []
      self.dports.each {|p| dports_col[p.xpos] = p }

      # Remove the route matrix lines whose tiles are empty or contain
      # vertical wires only.
      dh = 0 # Total height reduction.
      @route_matrix.size.times do |y|
        row = @route_matrix[y-dh]
        # puts "y=#{y} dh=#{dh} y-dh=#{y-dh}, @route_matrix.size=#{@route_matrix.size}"
        # Check if the row is a canditate for deletion.
        del = row.none? do |tile|
          tile && (tile.ic || tile.wires.any? {|d| d!=UP|DOWN } )
        end
        # But maybe some IC will touch is each other or the border if the
        # row is deleted,
        # we want to avoid it.
        if del then
          if y-dh == 0 then
            del = false if @route_matrix[y-dh+1].any? { |tile| tile.ic }
          elsif y-dh == @route_matrix.size - 1 then 
            del = false if @route_matrix[y-dh-1].any? { |tile| tile.ic }
          else
            del = false if row.size.times.any? do |x|
              @route_matrix[y-dh-1][x].ic and @route_matrix[y-dh+1][x].ic
            end
          end
        end
        # Delete the row if possible.
        if del then
          @route_matrix.delete_at(y-dh)
          # Update the current IC ports array rows.
          lports_row.delete_at(y-dh)
          rports_row.delete_at(y-dh)
          dh += 1
        end
      end
      # Remove the route matrix column whose tiles are empty or contain
      # horizontal wires only.
      dw = 0
      self.width.times do |x|
        del = @route_matrix.none? do |row|
          tile = row[x-dw]
          tile && (tile.ic || tile.wires.any? {|d| d!=LEFT|RIGHT } )
        end
        # But maybe some IC will touch is each other or the border if the
        # row is deleted,
        # we want to avoid it.
        if del then
          if x-dw == 0 then
            del = false if @route_matrix.any? { |row| row[x-dw+1].ic }
          elsif x-dw == @route_matrix[0].size - 1 then 
            del = false if @route_matrix.any? { |row| row[x-dw-1].ic }
          else
            del = false if @route_matrix.size.times.any? do |y|
              @route_matrix[y][x-dw-1].ic and @route_matrix[y][x-dw+1].ic
            end
          end
        end
        if del then
          # Remove the column.
          @route_matrix.each {|row| row.delete_at(x-dw) }
          # Update the current IC ports array columns.
          uports_col.delete_at(x-dw)
          dports_col.delete_at(x-dw)
          dw += 1
        end
      end

      # # Readd border if an ic is touching a border.
      # if @route_matrix.any? {|row| row[0] && row[0].ic } then
      #   # An IC touch the left border, add an empty colum.
      #   dw -= 1
      #   @route_matrix.each { |row| row.unshift(Tile.new) }
      # end
      # if @route_matrix.any? {|row| row[-1] && row[-1].ic } then
      #   # An IC touch the right border, add an empty column.
      #   dw -= 1
      #   @route_matrix.each { |row| row.push(Tile.new) }
      # end
      
      puts "Compressed tiles result: width -#{dw}, height -#{dh}"
      
      # Update the position of the IC and their ports according to the
      # new matrix. For that purpose, scan the matrix for left to right
      # and down to up update the position of the encountered tile's ic
      # when encountered first.
      fixed = Set.new
      @route_matrix.each_with_index do |row,y|
        row.each_with_index do |tile,x|
          # Check if there is an IC to process.
          next unless (tile and tile.ic and !fixed.include?(tile.ic))
          # Yes, update its own and its ports' positions.
          dx = x - tile.ic.xpos
          dy = y - tile.ic.ypos
          tile.ic.xpos += dx
          tile.ic.ypos += dy
          tile.ic.ports.each do |port|
            port.xpos += dx
            port.ypos += dy
          end
          # Tell it is already fixed.
          fixed.add(tile.ic)
        end
      end

      # Update the size of the current IC and the position of its ports.
      self.width -= dw
      self.height -= dh
      # Position with border (since the IC has been resized).
      self.rports.each { |port| port.xpos -= dw }
      self.uports.each { |port| port.ypos -= dh }
      # Position in border.
      lports_row.each_with_index { |port,y| port.ypos = y if port }
      uports_col.each_with_index { |port,x| port.xpos = x if port }
      rports_row.each_with_index { |port,y| port.ypos = y if port }
      dports_col.each_with_index { |port,x| port.xpos = x if port }
    end


    # Do the full place and route.
    def place_and_route
      # Nothing to do if no children.
      if self.children.empty? then
        @route_matrix = []
        return
      end
      # Do the pre-placement.
      self.preplace_children

      puts "Pre-placement result: "
      # Display the result.
      self.children.each_with_index do |child|
        puts "#{child.name}: x=#{child.xpos} y=#{child.ypos}"
      end

      # Do the placement.
      self.place_children

      puts "Placement result: "
      # Display the result.
      self.children.each_with_index do |child|
        puts "#{child.name}: x=#{child.xpos} y=#{child.ypos}"
      end

      # Centers the result.
      self.bounding_children
      self.center_children

      # Minimize the height.
      self.bounding_children
      self.minimize_height_children

      # Centers the result.
      self.bounding_children
      self.center_children

      puts "Orientation result: "
      # Display the result.
      self.children.each do |child|
        puts "#{child.name}: x=#{child.xpos} y=#{child.ypos}"
      end

      # Compute the placement matrix.
      self.bounding_children
      matrix = self.matrix_children
      puts "matrix:"
      matrix.each { |row| puts "#{row.map{|ic| ic ? ic.name : "   " }}" }

      # Compute the side of the ports.
      self.bounding_children

      # For self.
      self.side_ports

      puts "Self ports side results:"
      self.ports.each_with_index do |port,j|
        if port.targets[0] then
          puts "#{self.name} port #{port.name} (to #{port.targets[0].ic.name}): #{port.side}"
        else
          puts "#{self.name} port #{port.name} (dangling): #{port.side}"
        end
      end

      # For the children.
      self.side_children

      puts "Children ports side results: "
      self.children.each_with_index do |child|
        child.ports.each_with_index do |port,j|
          if port.targets[0] then
            puts "#{child.name} port #{port.name} (to #{port.targets[0].ic.name}): #{port.side}"
          else
            puts "#{child.name} port #{port.name} (dangling): #{port.side}"
          end
        end
      end

      # Compute the size of the ICs.
      self.size_children
      self.normalize_size_children

      puts "Size results: "
      self.children.each do |child|
        puts "#{child.name}: width=#{child.width} height=#{child.height}"
      end

      routed = false
      @retries.times do |ret|
        puts "Route matrix sizing and route: try #{ret} (border=#{@border}, cell border=#{@cell_border})..."
        # Compute the size of the matrix cells.
        self.size_matrix
        puts "Self size: width=#{self.width} height=#{self.height}"

        puts "Cells sizes: "
        puts "  Columns' widths: #{self.cwidths}"
        puts "  Rows' heights:   #{self.rheights}"


        # Recompute the precise place of the ICs using the size of the matrix cells.
        self.place_children_matrix
        puts "Matrix-based placement result: "
        # Display the result.
        self.children.each do |child|
          puts "#{child.name}: x=#{child.xpos} y=#{child.ypos}"
        end

        # Place the ports using the matrix cells.
        self.place_ports_matrix
        puts "Matrix-base port placement result: "
        # Display the result.
        self.children.each do |child|
          puts "For #{child.name}([#{child.xpos},#{child.ypos}]):" +
            child.ports.map {|p| "#{p.name}: [#{p.side} #{p.xpos},#{p.ypos}]" }.join(", ")
        end
        puts "For self:" +
          self.ports.map {|p| "#{p.name}: [#{p.side} #{p.xpos},#{p.ypos}]" }.join(", ")

        # Fine-tune the placement.
        self.place_children_port_matrix
        puts "Matrix-base ic-port placement fine tuning result: "
        # Display the result.
        self.children.each do |child|
          puts "For #{child.name}:" +
            child.ports.map {|p| "#{p.name}: [#{p.side} #{p.xpos},#{p.ypos}]" }.join(", ")
        end
        puts "For self:" +
          self.ports.map {|p| "#{p.name}: [#{p.side} #{p.xpos},#{p.ypos}]" }.join(", ")

        # Route the ports' connections.
        routed = self.route_children
        break if routed # Success

        # @border *= 2
        # @cell_border *= 2
        # @port_width += 1
        @border *= 4
        @cell_border *= 4
        @port_width += 2
      end
      raise "Route failure." unless routed

      puts "Routes:"
      # Display the result.
      self.routes.each do |route|
        puts "#{route.ports.map {|p| p.name}.join(" to ")}:  #{route.path}"
      end

      # Generate the wiring and connection content of the tiles.
      self.wire_route_tiles

      # Compress the route matrix and update the position of the objects
      # accordignly.
      self.compress_route_tiles
    end


    # Deeply place and route.
    def place_and_route_deep
      # Place and route current IC.
      self.place_and_route
      # Recurse the place and route for the instance children.
      @children.each do |child|
        if child.type == :instance then
          # Case on instance: place and route its system.
          child.system.place_and_route_deep 
        else
          puts "Place and route node for ic=#{child.name}"
          # Otherwise recurse on the branches.
          child.branches.each { |branch| branch.place_and_route_deep }
        end
      end
    end


    # Generate a system description SVG text for +ic+
    def system_svg(ic)
      return "<rect fill=\"#fff\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/8.0}\" " +
        "x=\"#{ic.xpos*@scale}\" y=\"#{ic.ypos*@scale}\" " +
        "width=\"#{ic.width*@scale}\" "+
        "height=\"#{ic.height*@scale}\"/>\n"
    end

    # Generate an instance description SVG text for +ic+
    def instance_svg(ic)
      id = Viz.to_svg_id(ic.name)
      # The rectangle representing the instance.
      res = "<rect id=\"#{id}\" fill=\"#eee\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/12.0}\" " +
        "x=\"#{ic.xpos*@scale}\" y=\"#{ic.ypos*@scale}\" " +
        "width=\"#{ic.width*@scale}\" "+
        "height=\"#{ic.height*@scale}\"/>\n"
      # Its name.
      sy = (ic.lports.size.even? and ic.rports.size.even? ) ? 0 : -0.5 # Shift to avoid ports
      res += "<text id=\"text#{id}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(ic.xpos + ic.width/2.0)*@scale}\" "+
        "y=\"#{(ic.ypos + ic.height/2.0 + sy)*@scale}\">" +
        ic.name + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{id}",(ic.width-0.6)*@scale,
                               0.6*@scale)
      return res
    end

    # Generate a process description SVG text for +ic+
    def process_svg(ic)
      id = Viz.to_svg_id(ic.name)
      res = "<rect id=\"#{id}\" fill=\"#eee\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/16.0}\" " +
        "x=\"#{ic.xpos*@scale}\" y=\"#{ic.ypos*@scale}\" " +
        "rx=\"#{@scale}\" " +
        "width=\"#{ic.width*@scale}\" "+
        "height=\"#{ic.height*@scale}\"/>\n"
      # Its name.
      sy = (ic.lports.size.even? and ic.rports.size.even? ) ? 0 : -0.5 # Shift to avoid ports
      res += "<text id=\"text#{id}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(ic.xpos + ic.width/2.0)*@scale}\" "+
        "y=\"#{(ic.ypos + ic.height/2.0 + sy)*@scale}\">" +
        ic.name + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{id}",(ic.width-0.6)*@scale,
                               0.6*@scale)
      return res
    end

    # Generate a clocked process description SVG text for +ic+
    def clocked_process_svg(ic)
      id = Viz.to_svg_id(ic.name)
      res = "<rect fill=\"#ddd\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/32.0}\" " +
        "x=\"#{(ic.xpos-1/16.0)*@scale}\" y=\"#{(ic.ypos-1/16.0)*@scale}\" " +
        "rx=\"#{(1+1/16.0)*@scale}\" " +
        "width=\"#{(ic.width+1/8.0)*@scale}\" "+
        "height=\"#{(ic.height+1/8.0)*@scale}\"/>\n"
      res += "<rect id=\"#{id}\" fill=\"#ddd\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/32.0}\" " +
        "x=\"#{ic.xpos*@scale}\" y=\"#{ic.ypos*@scale}\" " +
        "rx=\"#{@scale}\" " +
        "width=\"#{ic.width*@scale}\" "+
        "height=\"#{ic.height*@scale}\"/>\n"
      # Its name.
      sy = (ic.lports.size.even? and ic.rports.size.even? ) ? 0 : -0.5 # Shift to avoid ports
      res += "<text id=\"text#{id}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(ic.xpos + ic.width/2.0)*@scale}\" "+
        "y=\"#{(ic.ypos + ic.height/2.0 + sy)*@scale}\">" +
        ic.name + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{id}",(ic.width-0.6)*@scale,
                               0.6*@scale)
      return res
    end

    # Generate a timed process description SVG text for +ic+
    def timed_process_svg(ic)
      id = Viz.to_svg_id(ic.name)
      res = "<rect id=\"#{id}\" fill=\"#bbb\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/8.0}\" " +
        "x=\"#{ic.xpos*@scale}\" y=\"#{ic.ypos*@scale}\" " +
        "rx=\"#{@scale}\" " +
        "width=\"#{ic.width*@scale}\" "+
        "height=\"#{ic.height*@scale}\"/>\n"
      # Its name.
      sy = (ic.lports.size.even? and ic.rports.size.even? ) ? 0 : -0.5 # Shift to avoid ports
      res += "<text id=\"text#{id}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(ic.xpos + ic.width/2.0)*@scale}\" "+
        "y=\"#{(ic.ypos + ic.height/2.0 + sy)*@scale}\">" +
        ic.name + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{id}",(ic.width-0.6)*@scale,
                               0.6*@scale)
      return res
    end

    # Generate a register description SVG text for +ic+
    def register_svg(ic)
      id = Viz.to_svg_id(ic.name)
      res = "<rect id=\"#{id}\" fill=\"#fff\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/16.0}\" " +
        "x=\"#{ic.xpos*@scale}\" y=\"#{ic.ypos*@scale}\" " +
        "rx=\"#{@scale/4}\" " +
        "width=\"#{ic.width*@scale}\" "+
        "height=\"#{ic.height*@scale}\"/>\n"
      # Its name.
      sy = (ic.lports.size <= 2 or ic.lports.size.even?) ? 0 : -0.5 # Shift to avoid ports (Note: register prots are symetrics, so check left only).
      res += "<text id=\"text#{id}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(ic.xpos + ic.width/2.0)*@scale}\" "+
        "y=\"#{(ic.ypos + ic.height/2.0+sy)*@scale}\">" +
        ic.name + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{id}",(ic.width-0.6)*@scale,
                               0.6*@scale)
      return res
    end

    # Generate a memory description SVG text for +ic+
    def memory_svg(ic)
      id = Viz.to_svg_id(ic.name)
      res = "<rect id=\"#{id}\" fill=\"#fff\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/16.0}\" " +
        "x=\"#{ic.xpos*@scale}\" y=\"#{ic.ypos*@scale}\" " +
        "rx=\"#{@scale/4}\" " +
        "width=\"#{ic.width*@scale}\" "+
        "height=\"#{ic.height*@scale}\"/>\n"
      res += "<rect fill=\"#fff\" stroke=\"#333\" " +
        "stroke-width=\"#{@scale/16.0}\" " +
        "x=\"#{(ic.xpos+1/4.0)*@scale}\" "+
        "y=\"#{(ic.ypos+1/4.0)*@scale}\" " +
        "width=\"#{(ic.width-1/2.0)*@scale}\" "+
        "height=\"#{(ic.height-1/2.0)*@scale}\"/>\n"
      res += "<line stroke=\"#333\" " +
        "stroke-width=\"#{@scale/16.0}\" " +
        "x1=\"#{(ic.xpos+1/4.0+1/8.0)*@scale}\" "+
        "y1=\"#{(ic.ypos+1/4.0)*@scale}\" " +
        "x2=\"#{(ic.xpos+1/4.0+1/8.0)*@scale}\" "+
        "y2=\"#{(ic.ypos+ic.height-1/4.0)*@scale}\"/>\n"
      res += "<line stroke=\"#333\" " +
        "stroke-width=\"#{@scale/16.0}\" " +
        "x1=\"#{(ic.xpos+1/4.0)*@scale}\" "+
        "y1=\"#{(ic.ypos+1/4.0+1/8.0)*@scale}\" " +
        "x2=\"#{(ic.xpos+ic.width-1/4.0)*@scale}\" "+
        "y2=\"#{(ic.ypos+1/4.0+1/8.0)*@scale}\"/>\n"
      # Its name.
      res += "<text id=\"text#{id}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(ic.xpos + ic.width/2.0 + 1/10.0)*@scale}\" "+
        "y=\"#{(ic.ypos + ic.height/2.0)*@scale}\">" +
        ic.name + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{id}",(ic.width-1.0)*@scale,
                               0.6*@scale)
      return res
    end

    # Generate an ALU description SVG text for +ic+
    def alu_svg(ic)
      id = Viz.to_svg_id(ic.name)
      # Determine the side of the inputs (and consequently of the outputs),
      # and the number of inputs.
      iside = LEFT # Default side: left
      inum = 0
      ic.ports.each do |port|
        if port.direction == :input then
          iside = port.side
          inum += 1
        end
      end
      # NOTE: inum is zero in case of a constant, force at least 1.
      inum = 1 if inum < 1
      # The length of a leg
      if iside == LEFT or iside == RIGHT then
        leg = ic.height / inum
      else
        leg = ic.width / inum
      end
      # Generate the resulting polygon.
      res = "<polygon id=\"#{id}\" fill=\"#eee\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/16.0}\" " +
        "points=\""
      # The result depends on the size of the input.
      case(iside)
      when LEFT
        # The left side
        res += "#{ic.xpos*@scale} #{(ic.ypos)*@scale} "
        (inum-1).times do |i|
          res += "#{(ic.xpos)*@scale} #{(ic.ypos+i*leg+0.25)*@scale} "
          res += "#{(ic.xpos)*@scale} #{(ic.ypos+(i+1)*leg-0.25)*@scale} "
          res += "#{(ic.xpos+0.25)*@scale} #{(ic.ypos+(i+1)*leg)*@scale} "
          res += "#{(ic.xpos)*@scale} #{(ic.ypos+(i+1)*leg+0.25)*@scale} "
        end
        res += "#{(ic.xpos)*@scale} #{(ic.ypos+inum*leg)*@scale} "
        # The up side
        # res += "#{(ic.xpos+ic.width)*@scale} #{(ic.ypos+inum*leg-1)*@scale} "
        res += "#{(ic.xpos+ic.width)*@scale} #{(ic.ypos+ic.height*0.7)*@scale} "
        # The right side.
        # res += "#{(ic.xpos+ic.width)*@scale} #{(ic.ypos+1)*@scale}"
        res += "#{(ic.xpos+ic.width)*@scale} #{(ic.ypos+ic.height*0.3)*@scale}"
        # The down side is not necessary, close the shape.
        res += "\"/>"
      when UP
        # The right side
        res += "#{(ic.xpos)*@scale} #{(ic.ypos+ic.height)*@scale} "
        (inum-1).times do |i|
          res += "#{(ic.xpos+i*leg+0.25)*@scale} #{(ic.ypos+ic.height)*@scale} "
          res += "#{(ic.xpos+(i+1)*leg-0.25)*@scale} #{(ic.ypos+ic.height)*@scale} "
          res += "#{(ic.xpos+(i+1)*leg)*@scale} #{(ic.ypos-0.25+ic.height)*@scale} "
          res += "#{(ic.xpos+(i+1)*leg+0.25)*@scale} #{(ic.ypos+ic.height)*@scale} "
        end
        res += "#{(ic.xpos+inum*leg)*@scale} #{(ic.ypos+ic.height)*@scale} "
        # The up side
        # res += "#{(ic.xpos+inum*leg-1)*@scale} #{(ic.ypos)*@scale} "
        res += "#{(ic.xpos+ic.width*0.7)*@scale} #{(ic.ypos)*@scale} "
        # The right side.
        # res += "#{(ic.xpos+1)*@scale} #{(ic.ypos)*@scale}"
        res += "#{(ic.xpos+ic.width*0.3)*@scale} #{(ic.ypos)*@scale}"
        # The down side is not necessary, close the shape.
        res += "\"/>"
      when RIGHT
        # The right side
        res += "#{(ic.xpos+ic.width)*@scale} #{(ic.ypos)*@scale} "
        (inum-1).times do |i|
          res += "#{(ic.xpos+ic.width)*@scale} #{(ic.ypos+i*leg+0.25)*@scale} "
          res += "#{(ic.xpos+ic.width)*@scale} #{(ic.ypos+(i+1)*leg-0.25)*@scale} "
          res += "#{(ic.xpos-0.25+ic.width)*@scale} #{(ic.ypos+(i+1)*leg)*@scale} "
          res += "#{(ic.xpos+ic.width)*@scale} #{(ic.ypos+(i+1)*leg+0.25)*@scale} "
        end
        res += "#{(ic.xpos+ic.width)*@scale} #{(ic.ypos+inum*leg)*@scale} "
        # The up side
        # res += "#{(ic.xpos)*@scale} #{(ic.ypos+inum*leg-1)*@scale} "
        res += "#{(ic.xpos)*@scale} #{(ic.ypos+ic.height*0.7)*@scale} "
        # The right side.
        # res += "#{(ic.xpos)*@scale} #{(ic.ypos+1)*@scale}"
        res += "#{(ic.xpos)*@scale} #{(ic.ypos+ic.height*0.3)*@scale}"
        # The down side is not necessary, close the shape.
        res += "\"/>"
      when DOWN
        # The down side
        res += "#{ic.xpos*@scale} #{(ic.ypos)*@scale} "
        (inum-1).times do |i|
          res += "#{(ic.xpos+i*leg+0.25)*@scale} #{(ic.ypos)*@scale} "
          res += "#{(ic.xpos+(i+1)*leg-0.25)*@scale} #{(ic.ypos)*@scale} "
          res += "#{(ic.xpos+(i+1)*leg)*@scale} #{(ic.ypos+0.25)*@scale} "
          res += "#{(ic.xpos+(i+1)*leg+0.25)*@scale} #{(ic.ypos)*@scale} "
        end
        res += "#{(ic.xpos+inum*leg)*@scale} #{(ic.ypos)*@scale} "
        # The up side
        # res += "#{(ic.xpos+inum*leg-1)*@scale} #{(ic.ypos+ic.height)*@scale} "
        res += "#{(ic.xpos+ic.width*0.7)*@scale} #{(ic.ypos+ic.height)*@scale} "
        # The right side.
        # res += "#{(ic.xpos+1)*@scale} #{(ic.ypos+ic.height)*@scale}"
        res += "#{(ic.xpos+ic.width*0.3)*@scale} #{(ic.ypos+ic.height)*@scale}"
        # The down side is not necessary, close the shape.
        res += "\"/>"
      else
        raise "Wrong side: #{iside}"
      end
      # Its name.
      # sy = (iside == UP || iside == DOWN) ? 0 : -0.5 # Shift to avoid ports
      sy = (iside == UP || iside == DOWN || inum.even?) ? 0 : -0.5 # Shift to avoid ports
      res += "<text id=\"text#{id}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(ic.xpos + ic.width/2.0)*@scale}\" "+
        "y=\"#{(ic.ypos + ic.height/2.0 + sy)*@scale}\">" +
        ic.name + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{id}",(ic.width-0.6)*@scale,
                               0.6*@scale)
      return res
    end

    # Generate a left port description SVG text.
    def left_port_svg(name,type,xpos,ypos,width,height)
      uX = width/16.0
      uY = height/16.0
      case type
      when :posedge
        res = "<rect fill=\"#88f\" stroke=\"#000\" " 
      when :negedge
        res = "<rect fill=\"#f88\" stroke=\"#000\" " 
      else
        res = "<rect fill=\"#ff0\" stroke=\"#000\" " 
      end
      res += "x=\"#{xpos}\" y=\"#{ypos}\" " + 
        "stroke-width=\"#{@scale/16.0}\" " +
        "width=\"#{width}\" height=\"#{height}\"/>\n"
      res += "<polygon fill=\"#000\" stroke=\"none\" " +
        "points=\"#{xpos},#{ypos+height/2.0} #{xpos+width},#{ypos} " +
        "#{xpos+width},#{ypos+height}\"/>\n"
      return res
    end

    # Generate a right port description SVG text.
    def right_port_svg(name,type,xpos,ypos,width,height)
      case type
      when :posedge
        res = "<rect fill=\"#88f\" stroke=\"#000\" " 
      when :negedge
        res = "<rect fill=\"#f88\" stroke=\"#000\" " 
      else
        res = "<rect fill=\"#ff0\" stroke=\"#000\" " 
      end
      res += "x=\"#{xpos}\" y=\"#{ypos}\" " + 
        "stroke-width=\"#{@scale/16.0}\" " +
        "width=\"#{width}\" height=\"#{height}\"/>\n"
      res += "<polygon fill=\"#000\" stroke=\"none\" " +
        "points=\"#{xpos},#{ypos} #{xpos+width},#{ypos+height/2.0} " +
        "#{xpos},#{ypos+height}\"/>\n"
      return res
    end

    # Generate a left-right port description SVG text.
    def left_right_port_svg(name,type,xpos,ypos,width,height)
      res = "<rect fill=\"#FF0\" stroke=\"#000\" " +
        "x=\"#{xpos}\" y=\"#{ypos}\" " + 
        "stroke-width=\"#{@scale/16.0}\" " +
        "width=\"#{width}\" height=\"#{height}\"/>\n"
      res += "<polygon fill=\"#000\" stroke=\"none\" " +
        "points=\"#{xpos},#{ypos+height/2} #{xpos+width},#{ypos} " +
        "#{xpos+width},#{ypos+height}\"/>\n"
      res += "<polygon fill=\"#000\" stroke=\"none\" " +
        "points=\"#{xpos},#{ypos} #{xpos+width},#{ypos+height/2.0} " +
        "#{xpos},#{ypos+height}\"/>\n"
      return res
    end

    # Generate an up port description SVG text.
    def up_port_svg(name,type,xpos,ypos,width,height)
      case type
      when :posedge
        res = "<rect fill=\"#88f\" stroke=\"#000\" " 
      when :negedge
        res = "<rect fill=\"#f88\" stroke=\"#000\" " 
      else
        res = "<rect fill=\"#ff0\" stroke=\"#000\" " 
      end
      res += "x=\"#{xpos}\" y=\"#{ypos}\" " + 
        "stroke-width=\"#{@scale/16.0}\" " +
        "width=\"#{width}\" height=\"#{height}\"/>\n"
      res += "<polygon fill=\"#000\" stroke=\"none\" " +
        "points=\"#{xpos},#{ypos} #{xpos+width/2.0},#{ypos+height} " +
        "#{xpos+width},#{ypos}\"/>\n"
      return res
    end

    # Generate a down port description SVG text.
    def down_port_svg(name,type,xpos,ypos,width,height)
      case type
      when :posedge
        res = "<rect fill=\"#88f\" stroke=\"#000\" " 
      when :negedge
        res = "<rect fill=\"#f88\" stroke=\"#000\" " 
      else
        res = "<rect fill=\"#ff0\" stroke=\"#000\" " 
      end
      res += "x=\"#{xpos}\" y=\"#{ypos}\" " + 
        "stroke-width=\"#{@scale/16.0}\" " +
        "width=\"#{width}\" height=\"#{height}\"/>\n"
      res += "<polygon fill=\"#000\" stroke=\"none\" " +
        "points=\"#{xpos+width/2.0},#{ypos} #{xpos},#{ypos+height} " +
        "#{xpos+width},#{ypos+height}\"/>\n"
      return res
    end

    # Generate an up-down port description SVG text.
    def up_down_port_svg(name,type,xpos,ypos,width,height)
      res = "<rect fill=\"#FF0\" stroke=\"#000\" " +
        "x=\"#{xpos}\" y=\"#{ypos}\" " + 
        "stroke-width=\"#{@scale/16.0}\" " +
        "width=\"#{width}\" height=\"#{height}\"/>\n"
      res += "<polygon fill=\"#000\" stroke=\"none\" " +
        "points=\"#{xpos},#{ypos} #{xpos+width/2},#{ypos+height} " +
        "#{xpos+width},#{ypos}\"/>\n"
      res += "<polygon fill=\"#000\" stroke=\"none\" " +
        "points=\"#{xpos+width/2.0},#{ypos} #{xpos},#{ypos+height} " +
        "#{xpos+width},#{ypos+height}\"/>\n"
      return res
    end

    # Tell if a port is a sub-port of a register.
    def sub_port?(port)
      return !port.name.sub(self.name,"").sub(/\$(I|O)/,"").empty?
    end

    # Generate the string representing a port for display in the SVG
    def port_str(port)
      # Generate the port name (strip everything before the last ".")
      name = port.name.sub(/^.*\./,"")
      # Strip the suffix $I and $O
      name = name.sub(/\$(I|O)$/,"")
      # Add a suffix for edge properties.
      case port.type
      when :posedge
        return name + " \u2197"
      when :negedge
        return name + " \u2198"
      else
        return name
      end
    end

    attr_reader :idC


    # Generate in SVG format the graphical representation of the IC.
    # +top+ tells if it is the top IC.
    # +tx+ is the x translation of the full description.
    # +ty+ is the y translation of the full description.
    # +width+ is the forced width of the full description if any.
    # +height+ is the forced height of the full description if any.
    def to_svg(top = true, tx=0, ty=0, width=nil, height=nil)
      # Compute the various sizes.
      x0,y0, x1,y1 = 0,0, @width*@scale, @height*@scale
      puts "x0,y0, x1,y1 = #{x0},#{y0}, #{x1}, #{y1}"
      bT = (@scale * 1.5)                # Border thickness
      pT = (bT / 5.0)                    # Port thickness
      wT = bT / 30.0                     # Wire thickness
      sF = @scale*0.4                    # Small font height
      mF = @scale*0.6                    # Medium font height
      lF = @scale*1.0                    # Large font height
      width  = (x1-x0)+bT*5 unless width
      height = (y1-y0)+bT*5 unless height
      stx = (width - (x1-x0)) / 2.0 # X translation of the top system
      sty = (height - (y1-y0)) / 2.0 # Y translation of the top system
      puts "bT=#{bT} pT=#{pT} wT=#{wT} width=#{width} height=#{height}"
      # The initial visibility.
      visibility = top ? "visible" : "hidden"
      # The string used as suffix for style class names.
      @idC = "-" + self.name.gsub(/[:$]/,"-")
      # Generate the SVG code.
      if top then
        # It is the top IC.
        # Generate the header.
        res = Viz.header_svg(self.name,x0,y0,width,height)
      else
        # It is not the top, no need of initialization.
        res = ""
      end

      # Sets the styles.
      res += "<style>\n"
      # Fonts
      res += ".small#{self.idC}  { font: #{sF}px sans-serif; }\n"
      res += ".medium#{self.idC} { font: #{mF}px sans-serif; }\n"
      res += ".large#{self.idC}  { font: #{lF}px sans-serif; }\n"
      res += "</style>\n"

      # Generate the group containing all the IC description.
      res += "<g id=\"#{self.name}\" visibility=\"#{visibility}\" " +
             "transform=\"translate(#{tx},#{ty})\">\n"
      # Generate the rectangle of the bounding box.
      res += "<rect fill=\"#bbb\" stroke=\"#555\" " +
        "stroke-width=\"#{@scale/4.0}\" " +
        # "x=\"#{x0-bT*2.5}\" y=\"#{y0-bT*2.5}\" "+
        "x=\"#{x0}\" y=\"#{y0}\" "+
        "width=\"#{width}\" height=\"#{height}\"/>\n"

      # Generate the group containing the top system and its contents.
      res += "<g transform=\"translate(#{stx},#{sty})\">\n"

      # Generate current IC's box.
      # The SVG object representing a system.
      res += system_svg(self)

      # Draw the routes and connection points.
      @route_matrix.each_with_index do |row,y|
        row.each_with_index do |tile,x|
          # # Draw the tiles contour for debug.
          # res += "<rect fill=\"none\" stroke=\"#00F\" " +
          #   "x=\"#{x*@scale}\" " +
          #   "y=\"#{y*@scale}\" " +
          #   "width=\"#{@scale}\" height=\"#{@scale}\"/>\n"
          #
          # Draw the wires.
          tile.wires.each do |wire_dir|
            # puts "wire_dir=#{wire_dir}"
            # Draw the wire (as a thin rectangle).
            case wire_dir
            when LEFT|RIGHT
              res += "<line stroke=\"#000\" stroke-width=\"#{wT}\" " +
                "stroke-linecap=\"round\" " +
                "x1=\"#{(x)*@scale}\" " +
                "y1=\"#{(y+0.5)*@scale}\" " +
                "x2=\"#{(x+1)*@scale}\" " +
                "y2=\"#{(y+0.5)*@scale}\" />\n"
            when RIGHT|DOWN
              res += "<line stroke=\"#000\" stroke-width=\"#{wT}\" " +
                "stroke-linecap=\"round\" " +
                "x1=\"#{(x+1)*@scale}\" " +
                "y1=\"#{(y+0.5)*@scale}\" " +
                "x2=\"#{(x+0.5)*@scale}\" " +
                "y2=\"#{(y)*@scale}\" />\n"
            when RIGHT|UP
              res += "<line stroke=\"#000\" stroke-width=\"#{wT}\" " +
                "stroke-linecap=\"round\" " +
                "x1=\"#{(x+1)*@scale}\" " +
                "y1=\"#{(y+0.5)*@scale}\" " +
                "x2=\"#{(x+0.5)*@scale}\" " +
                "y2=\"#{(y+1)*@scale}\" />\n"
            when LEFT|DOWN
              res += "<line stroke=\"#000\" stroke-width=\"#{wT}\" " +
                "stroke-linecap=\"round\" " +
                "x1=\"#{(x+0.5)*@scale}\" " +
                "y1=\"#{(y)*@scale}\" " +
                "x2=\"#{(x)*@scale}\" " +
                "y2=\"#{(y+0.5)*@scale}\" />\n"
            when LEFT|UP
              res += "<line stroke=\"#000\" stroke-width=\"#{wT}\" " +
                "stroke-linecap=\"round\" " +
                "x1=\"#{(x+0.5)*@scale}\" " +
                "y1=\"#{(y+1)*@scale}\" " +
                "x2=\"#{(x)*@scale}\" " +
                "y2=\"#{(y+0.5)*@scale}\" />\n"
            when UP|DOWN
              res += "<line stroke=\"#000\" stroke-width=\"#{wT}\" " +
                "stroke-linecap=\"round\" " +
                "x1=\"#{(x+0.5)*@scale}\" " +
                "y1=\"#{(y)*@scale}\" " +
                "x2=\"#{(x+0.5)*@scale}\" " +
                "y2=\"#{(y+1)*@scale}\" />\n"
            end
          end

          # Draw the connection points.
          tile.dots.each do |dot_pos|
            res += "<rect fill=\"#000\" stroke=\"#000\" " +
                   "stroke-width=\"#{wT}\" "
            case dot_pos
            when LEFT
              res += "x=\"#{(x+0.0)*@scale-wT*2}\" " + 
                "y=\"#{(y+0.5)*@scale-wT*2}\" "
            when UP
              res += "x=\"#{(x+0.5)*@scale-wT*2}\" " + 
                "y=\"#{(y+1.0)*@scale-wT*2}\" "
            when RIGHT
              res += "x=\"#{(x+1.0)*@scale-wT*2}\" " + 
                "y=\"#{(y+0.5)*@scale-wT*2}\" "
            when DOWN
              res += "x=\"#{(x+0.5)*@scale-wT*2}\" " + 
                "y=\"#{(y+0.0)*@scale-wT*2}\" "
            end
            res += "width=\"#{wT*4}\" height=\"#{wT*4}\"/>\n"
          end
        end
      end

      # Generate the children boxes.
      @children.each do |child|
        case child.type
        when :assign
          # The SVG object representing an ALU is to draw.
          res += alu_svg(child)
        when :process
          # The SVG object representing a process is to draw.
          res += process_svg(child)
        when :clocked_process
          # The SVG object representing a cloked process is to draw.
          res += clocked_process_svg(child)
        when :timed_process
          # The SVG object representing a timed process is to draw.
          res += timed_process_svg(child)
        when :register
          # The SVG object representing a register is to draw.
          res += register_svg(child)
        when :memory
          # The SVG object representing a memory is to draw.
          res += memory_svg(child)
        else
          # The SVG object representing an instance is to draw.
          res += instance_svg(child)
        end
      end

      # Generate the port boxes.
      ([ self ] + @children).each do |child|
        # puts "Drawing port for: #{child.name}"
        # Left ports
        child.lports.each_with_index do |port|
          # Draw the port symbol.
          case port.direction
          when :input
            res += self.right_port_svg(port.name,port.type,
                                       port.xpos*@scale-pT/2,
                                       (port.ypos+0.5)*@scale-pT/2,pT,pT)
          when :output
            res += self.left_port_svg(port.name,port.type,
                                      port.xpos*@scale-pT/2,
                                      (port.ypos+0.5)*@scale-pT/2,pT,pT)
          when :inout
            res += self.left_right_port_svg(port.name,port.type,
                                            port.xpos*@scale-pT/2,
                                            (port.ypos+0.5)*@scale-pT/2,pT,pT)
          end
          # And set its name if it is not a register, memory non-sub port,
          # or an undirected port.
          if (child.type != :register and child.type != :memory and
              port.direction != :none) or child.sub_port?(port) then
            if child == self then
              res += "<text class=\"small#{self.idC}\" style=\"text-anchor: end\" " +
                "x=\"#{(port.xpos)*@scale-pT}\" "+
                "y=\"#{(port.ypos+0.5)*@scale+sF/2.5}\">" + # port.name +
                self.port_str(port) + "</text>\n"
            else
              res += "<text class=\"small#{self.idC}\" x=\"#{(port.xpos)*@scale+pT}\" "+
                "y=\"#{(port.ypos+0.5)*@scale+sF/2.5}\">" + # port.name + 
                self.port_str(port) + "</text>\n"
            end
          end
        end
        # Up ports.
        child.uports.each_with_index do |port|
          # puts "uport: #{port.name} xpos=#{port.xpos} ypos=#{port.ypos}"
          case port.direction
          when :input
            res += self.down_port_svg(port.name,port.type,
                                      (port.xpos+0.5)*@scale-pT/2,
                                      (port.ypos+1)*scale-pT/2,pT,pT)
          when :output
            res += self.up_port_svg(port.name,port.type,
                                    (port.xpos+0.5)*@scale-pT/2,
                                    (port.ypos+1)*scale-pT/2,pT,pT)
          when :inout
            res += self.up_down_port_svg(port.name,port.type,
                                         (port.xpos+0.5)*@scale-pT/2,
                                         (port.ypos+1)*scale-pT/2,pT,pT)
          end
          # And set its name if it is not a register, memory non sub-port,
          # or an undirected port.
          if (child.type != :register and child.type != :memory and
              port.direction != :none) or child.sub_port?(port) then
            if child == self then
              res += "<text class=\"small#{self.idC}\" style=\"text-anchor: middle\" " +
                "x=\"#{(port.xpos+0.5)*@scale}\" "+
                "y=\"#{(port.ypos+1.0)*@scale+pT+sF/2}\">" + # port.name + 
                self.port_str(port) + "</text>\n"
            else
              res += "<text class=\"small#{self.idC}\" style=\"text-anchor: middle\" " +
                "x=\"#{(port.xpos+0.5)*@scale}\" "+
                "y=\"#{(port.ypos+1.0)*@scale-pT}\">" + # port.name +
                self.port_str(port) + "</text>\n"
            end
          end
        end
        # Right ports
        child.rports.each_with_index do |port|
          case port.direction
          when :input
            res += self.left_port_svg(port.name,port.type,
                                      (port.xpos+1)*@scale-pT/2,
                                      (port.ypos+0.5)*scale-pT/2,pT,pT)
          when :output
            res += self.right_port_svg(port.name,port.type,
                                       (port.xpos+1)*@scale-pT/2,
                                       (port.ypos+0.5)*scale-pT/2,pT,pT)
          when :inout
            res += self.left_right_port_svg(port.name,port.type,
                                            (port.xpos+1)*@scale-pT/2,
                                            (port.ypos+0.5)*scale-pT/2,pT,pT)
          end
          # And set its name if it is not a register, memory non sub-port,
          # or an undirected port.
          if (child.type != :register and child.type != :memory and
              port.direction != :none) or child.sub_port?(port) then
            if child == self then
              res += "<text class=\"small#{self.idC}\" " +
                "x=\"#{(port.xpos+1)*@scale+pT}\" " +
                "y=\"#{(port.ypos+0.5)*@scale+sF/2.5}\">" + # port.name +
                self.port_str(port) + "</text>\n"
            else
              res += "<text class=\"small#{self.idC}\" style=\"text-anchor: end\" " +
                "x=\"#{(port.xpos+1)*@scale-pT}\" "+
                "y=\"#{(port.ypos+0.5)*@scale+sF/2.5}\">" + # port.name + 
                self.port_str(port) + "</text>\n"
            end
          end
        end
        # Down ports.
        child.dports.each_with_index do |port|
          case port.direction
          when :input
            res += self.up_port_svg(port.name,port.type,
                                    (port.xpos+0.5)*@scale-pT/2,
                                    port.ypos*scale-pT/2,pT,pT)
          when :output
            res += self.down_port_svg(port.name,port.type,
                                      (port.xpos+0.5)*@scale-pT/2,
                                      port.ypos*scale-pT/2,pT,pT)
          when :inout
            res += self.up_down_port_svg(port.name,port.type,
                                         (port.xpos+0.5)*@scale-pT/2,
                                         port.ypos*scale-pT/2,pT,pT)
          end
          # And set its name if it is not a register, memory non sub-port,
          # or an undirected port.
          if (child.type != :register and child.type != :memory and
              port.direction != :none) or child.sub_port?(port) then
            if child == self then
              res += "<text class=\"small#{self.idC}\" style=\"text-anchor: middle\" " +
                "x=\"#{(port.xpos+0.5)*@scale}\" "+
                "y=\"#{(port.ypos)*@scale-pT}\">" + # port.name + 
                self.port_str(port) + "</text>\n"
            else
              res += "<text class=\"small#{self.idC}\" style=\"text-anchor: middle\" " +
                "x=\"#{(port.xpos+0.5)*@scale}\" "+
                # "y=\"#{(port.ypos)*@scale+pT+sF}\">" + # port.name + 
                "y=\"#{(port.ypos)*@scale+pT+sF/2.0}\">" + # port.name + 
                self.port_str(port) + "</text>\n"
            end
          end
        end
      end

      # Generate the children's inside if any.
      (@children+@branches).each do |child|
        target = nil
        # Determine the target element to represent.
        case child.type
        when :instance
          target = child.system
        when :assign, :process, :clocked_process, :timed_process
          target = child.branches[0]
        else
          target = child if child.is_a?(Node)
        end
        next unless target # No target? Skip.
        # Compute the child display width.
        cwidth = child.width-pT/@scale
        cheight = child.height-pT/@scale
        # Translate inside the instance.
        ctx = child.xpos + pT/(@scale*2.0)
        cty = child.ypos + pT/(@scale*2.0)
        # For the case of an assign IC (alu), reduce and tranlate a bit
        # on longer side, to accomodate the diagonal borders.
        if child.type == :assign then
          if child.lports.any? then
            cheight -= 2
            cty += 1
          else
            cwidth -= 2
            ctx += 1
          end
        end
        # For the case of a process, reduce and translate a bit on
        # the largest side to accomodate the round borders and usually long
        # dataflow represented.
        if [:process, 
            :clocked_process, :timed_process].include?(child.type) then
          if cwidth >= cheight then
            cwidth -= 2
            ctx += 1
          else
            cheight -= 2
            cty += 1
          end
        end
        # Leave a space for left or right ports if any.
        sl = child.ports.any? {|p| p.side == LEFT } ? 1.0 : 0.0
        sr = child.ports.any? {|p| p.side == RIGHT } ? 1.0 : 0.0
        # Recompute the scale.
        fit = [
          (target.width+sl+sr+(bT/@scale)) / (cwidth),
          (target.height+(bT/@scale)) / (cheight),
          3.0
        ].max
        target.scale = @scale / fit
        puts "fit=#{fit} target.scale=#{target.scale}"
        puts "child.xpos=#{child.xpos} child.ypos=#{child.ypos} ctx=#{ctx} cty=#{cty}"
        res += target.to_svg(false,ctx*@scale,cty*@scale,
                             cwidth*scale,cheight*scale)
        # Generate the closing button element.
        res += Viz.closing_svg(target.name + '_close',pT,(ctx+cwidth)*@scale-pT,cty*@scale)
      end

      # Close the group containing the top system and its content.
      res += "</g>\n"
      # Close the group containing the description of the IC.
      res += "</g>\n"

      # Generate the scripts for controlling the appearance of the
      # children' and contents' inside.
      (@children+@branches).each do |child|
        target = nil
        # Determine the target element to represent.
        case child.type
        when :instance
          target = child.system
        when :assign, :process, :clocked_process, :timed_process
          target = child.branches[0]
        else
          target = child if child.is_a?(Node)
        end
        next unless target # No target? Skip.
        res += <<~SCRIPT
<script>
diagram.getElementById('#{child.name}').addEventListener("click", (e) => {
    // For the element.
    let elem = diagram.getElementById('#{target.name}');
    elem.setAttribute('visibility','visible');
    // And its closing button.
    elem = diagram.getElementById('#{target.name}_close');
    elem.setAttribute('visibility','visible');
});
diagram.getElementById('#{target.name}_close').addEventListener("click", (e) => {
    // For the element.
    let elem = diagram.getElementById('#{target.name}');
    elem.setAttribute('visibility','hidden');
    // And its closing button.
    elem = diagram.getElementById('#{target.name}_close');
    elem.setAttribute('visibility','hidden');
});

</script>
          SCRIPT
      end

      if top then
        # It is the top so generate the help panel and close the SVG.
        res += Viz.help_svg(x0,y0,width,height)
        res += "</svg>\n"
      end
      return res
    end
  end


  # An Flow node block
  class Node

    attr_reader :type, :parent, :name, :successor, :branches, :arrows
    attr_accessor :xpos, :ypos, :width, :height
    attr_reader :box
    attr_reader :matrix
    attr_reader :routes
    attr_reader :port_width
    attr_reader :scale

    def initialize(type, parent = nil, name = nil)
      @type = type.to_sym
      if name then
        @name = name.to_s
      else
        @name = HDLRuby.uniq_name("node").to_s
      end
      @parent = parent
      @parent.branches << self if @parent
      @successor = nil
      @branches = []
      @xpos   = 0
      @ypos   = 0
      @width  = 10     # Width in number of IC routes
      @height = 2      # Height in number of IC routes
      @arrows = []     # The flow arrows (routes)
      @scale = 1.0     # The scale for SVG generation
    end

    # Sets the successor.
    def successor=(succ)
      @successor = succ
    end

    # Move deeply the position.
    def move_deep(dx,dy)
      @xpos += dx
      @ypos += dy
      @branches.each {|branch| branch.move_deep(dx,dy) }
      @arrows.map! do |coord|
        [coord[0]+dx, coord[1]+dy, coord[2]+dx, coord[3]+dy ]
      end
    end

    # Convert to a string.
    def to_s(spc = "")
      case type
      when :assign
        return spc + @branches[0].to_s + " &lt;= "  + @branches[1].to_s
      when :if
        res = spc + "if " + @branches[0].to_s
        return res
      when :case
        res = spc + "case " + @branches[0].to_s + "==" + @branches[1].to_s
        return res
      when :wait
        return spc + "wait(#{@branches[0].to_s})"
      when :repeat
        res = spc + "repeat " + @branches[0].to_s
        return res
      when :terminate
        return "terminate"
      when :value, :delay, :string
        return self.name
      when :print
        return spc + "print(#{@branches.map {|b| b.to_s}.join(",")})"
      when :cast
        return spc + "(" + self.name + ")" + "(" + branches[0].to_s + ")"
      when :concat
        return spc + "concat(" +@branches.map {|b| b.to_s }.join(",") + ")"
      when :[]
        if @branches.size == 2 then
          return spc + @branches[0].to_s + "[" + @branches[1].to_s + "]"
        else
          return spc + @branches[0].to_s + "[" +
            @branches[1].to_s + ".." + @branches[2].to_s + "]"
        end
      when :"." 
        if @branches[0] then
          return spc + @branches[0].to_s + "." + self.name
        else
          return spc + self.name
        end
      else
        case(@branches.size)
        when 0
          return spc + type.to_s
        when 1
          return spc + "(" + HDLRuby::Viz.to_svg_text(type.to_s) + 
            @branches[0].to_s + ")"
        when 2
          return spc + "(" + @branches[0].to_s + 
            HDLRuby::Viz.to_svg_text(type.to_s) +
            @branches[1].to_s + ")"
        else
          return spc + type.to_s + "(" + @branches.join(",") + ")"
        end
      end
    end

    # Convert to a string as a control flow, i.e., the successor is
    # also converted.
    def to_s_control
      res = self.to_s + ";"
      if @successor then
        res += @successor.to_s_control
      end
      return res
    end

    # Set the scale for SVG generation.
    def scale=(scale)
      @scale = scale.to_f
    end


    # Get the number of statements within and from current node.
    def number_statements
      # puts "number_statements from #{self.name} (#{self.type})"
      case self.type
      when :par, :seq
        # Recurse on branch.
        snum = @branches[0].number_statements
      when :if, :repeat
        # Recurse on the statement branches.
        snum = @branches[1..-1].reduce(1) do |sum,branch| 
          sum + branch.number_statements 
        end
      when :case
        # Recurse on the statement branches.
        snum = @branches[2..-1].reduce(1) do |sum,branch| 
          sum + branch.number_statements 
        end
      else
        # Other cases: count one.
        snum = 1
      end
      # And recurse on the successor.
      snum += self.successor.number_statements if self.successor
      return snum
    end


    # Place statements vertically from statement +stmnt+ at
    # position +x+, +y+.
    # # +cond_succ+ the upper conditional successor if any.
    # Returns the width and height of the enclosing block.
    def place_and_route_statement_vertically(stmnt,x,y,cond_succ=nil)
    # def place_and_route_statement_vertically(stmnt,x,y)
      puts "place_and_route_statement_vertically with type=#{stmnt.type} x=#{x} y=#{y}"
      # Set the current statement y position.
      stmnt.ypos = y
      stmnt.xpos = x
      w = x + stmnt.width + 1
      # Depending of the kind of statement.
      case stmnt.type
      when :seq
        cur_w, last_y = 
          place_and_route_statement_vertically(stmnt.branches[0],x,y)
        w = cur_w if cur_w > w
        # Ensure seq has an height
        last_y = y+3 if last_y <= y
        # Update the size of the block.
        stmnt.height = last_y - y - 1
        stmnt.width = w - x - 1
        # Update the y position.
        y = last_y
      when :par
        stmnt.place_and_route_par(x,y)
        last_y = stmnt.height + y + 2
        w = stmnt.width + x + 1
        # Update the y position.
        y = last_y-1
      when :if, :case, :repeat
        fs = stmnt.type != :case ? 1 : 2 # First statement position.
        last_y = y
        cur_x = x
        cur_w = w
        last_y += 3
        # The yes is left.
        branch = stmnt.branches[fs]
        cur_w, cur_y = place_and_route_statement_vertically(branch,
                                                            # cur_x+stmnt.width+2,y)
                                                            cur_w+2,y)
        # And connect it with an arrow.
        @arrows << [x+stmnt.width, y+stmnt.height/2, 
                    # cur_x+stmnt.width+2, y+stmnt.height/2]
                    cur_w-branch.width-1, y+stmnt.height/2]
        # And starts the connection it to the successor if any.
        # But maybe there is a new successor, check it.
        cond_succ = stmnt.successor if stmnt.successor 
        if cond_succ and stmnt.type != :repeat then
          @arrows << [cur_w-1, cur_y-stmnt.height/2,
                      cur_w,   cur_y-stmnt.height/2]
        end
        # The no and elsif are down
        fy = y + 2
        last_y = cur_y if cur_y > last_y
        w = cur_w if cur_w > w
        stmnt.branches[fs+1..-1].each do |branch|
          # Place and route the branch
          cur_w, cur_y = 
            place_and_route_statement_vertically(branch,x,cur_y,
                                                 stmnt.successor)
            # place_and_route_statement_vertically(branch,x,cur_y)
          # And connect it with an arrow.
          # @arrows << [x+stmnt.width/2, last_y-1, 
          @arrows << [x+stmnt.width/2, fy, 
                      x+stmnt.width/2, last_y]
          fy = last_y + 2
          # Update the width and height from the branch size.
          w = cur_w if cur_w > w
          last_y = cur_y if cur_y > last_y
          # if branch.type != :if and branch.type != :case then
          #   # End of if/case.
          #   last_y += 1
          # end
        end
        if fs+1 == stmnt.branches.size and stmnt.successor then
          # There were no "no" branches, add an arrow up to the successor.
          @arrows << [x+stmnt.width/2, fy, 
                      x+stmnt.width/2, last_y]
        end

        # Update the width and height from the branch size.
        w = cur_w if cur_w > w
        # cur_x += cur_w + 1
        cur_x += cur_w
        last_y = cur_y if cur_y > last_y
        # Prepare the next step. 
        y = last_y
      when :empty
         w -= 2
        # @arrows << [x+stmnt.width/2, y, 
        #             x+stmnt.width/2, y+3]
        # else
        # y += 3
        # end
      else
        unless stmnt.type == :assign or stmnt.type == :wait or 
            stmnt.type == :print or stmnt.type == :terminate then
          raise "Unknown statement: #{stmnt.type}"
        end
        y += 3
      end
      # Recurse on successor if any.
      if stmnt.successor then
        puts "For stmnt type: #{stmnt.type} Successor is #{stmnt.successor.name}"
        py = y
        nw, y = place_and_route_statement_vertically(stmnt.successor,x,y)
        w = nw if nw > w
        # And connect it with an arrow.
        # @arrows << [x + self.width/2, py-1, x + stmnt.width/2, py]
        @arrows << [x + self.width/2, py-1, x + self.width/2, py]
        # And connect it to the other branches if condition.
        if stmnt.type == :if or stmnt.type == :case then
          # @arrows << [w, stmnt.ypos+stmnt.height/2,
          @arrows << [w, stmnt.branches[fs].ypos+stmnt.branches[fs].height,
                      x+self.width, py+stmnt.successor.height/2]
        end
      end
      return [ w, y ]
    end


    # Do the full place and route for a seq block with initial position
    # +x+ and +y+.
    def place_and_route_seq(x = 1, y = 1)
      puts "place_and_route_seq for node: #{self.name} at x=#{x} y=#{y}"
      stmnt = @branches[0]
      w, h = self.place_and_route_statement_vertically(stmnt,x,y)
      puts "Result: width=#{w} height=#{h}"
      # Update the size of the block.
      @width = w
      @height = h + 1
    end

    # Find the next free position in the place matrix +matrix+.
    # +c0+ is the left-most column that can be used.
    # +r+ and +c+ are the current row and column.
    # Retuns the new rows and columns.
    def next_place_matrix(matrix,c0,r,c)
      puts "next_place_matrix: matrix[0].size=#{matrix[0].size} r=#{r} c=#{c}"
      while matrix[r][c] do
        c += 1
        if c >= matrix[0].size then
          c = c0
          r += 1
          if r >= matrix.size then
            # Need to increase the size of the matrix.
            matrix << ([nil] * matrix[0].size)
          end
        end
      end
      puts "r=#{r} c=#{c}"
      return r,c
    end

    # Find the next row free from column +c0+ starting for position
    # row +r+ in the place matrix +matrix+.
    # Retuns the new rows and columns.
    def next_row_matrix(matrix,c0,r)
      puts "next_row_matrix: matrix[0].size=#{matrix[0].size} r=#{r} c0=#{c0}"
      cM = matrix[0].size-1 # Max column.
      while (c0..cM).each.any? { |c| matrix[r][c] } do
        r += 1
        if r >= matrix.size then
          # Need to increase the size of the matrix.
          matrix << ([nil] * matrix[0].size)
        end
      end
      puts "r=#{r}"
      return r
    end

    # Fill the place matrix with statement +stmnt+ at position +r+,+c+
    # stretched by +w+,+h+
    def fill_place_matrix(matrix,stmnt,r,c,w,h)
      puts "fill_place_matrix for stmnt=#{stmnt.name} at r=#{r} c=#{c} w=#{w} h=#{h}"
      h.times do |y|
        while matrix.size <= r+y do
          # Need to increase the size of the matrix on y.
          matrix << ([nil] * matrix[0].size)
        end
        w.times do |x|
          while matrix[r+y].size <= c+x do
            # Need to increase the size of the matrix on x.
            matrix.each {|row| row << nil }
          end
          # Fill in.
          matrix[r+y][c+x] = stmnt
        end
      end
    end

    # Place statements in a matrix from statement +stmnt+ at
    # using +matrix+ as guide for current row +r+ and column +c+.
    # Returns the width and height to fill from current position.
    def place_and_route_statement_matrix(stmnt, matrix, r, c)
      # The initial area to fill from current statement.
      fW, fH = stmnt.width + 1, stmnt.height 
      puts "Placing stmnt=#{stmnt.name} type=#{stmnt.type} at #{r},#{c}"
      # Recurse Depending of the kind of statement.
      case stmnt.type
      when :if, :case # There no repeat in parallel blocks.
        fs = stmnt.type != :case ? 1 : 2 # First statement position.
        # First set the current statement in the matrix.
        self.fill_place_matrix(matrix,stmnt,r,c,stmnt.width+1,3)
        # Recurse on the branches.
        stmnt.branches[fs..-1].each do |branch|
          # Update the position in the matrix
          # Depending on the type of branch.
          if branch.type == :if or branch.type == :case then
            # If branch, go down
            cur_r = self.next_row_matrix(matrix,c,r)
            cur_c = c
            # Route to it downward.
            @arrows << [c + stmnt.width/2, r-1, c + stmnt.width/2, cur_r]
          else
            if stmnt.branches[fs] != branch then
              # # Not if/case branch and secondary branch,
              # # put a placeholder to forbid placing
              # # an element between the if/case and the else.
              # self.fill_place_matrix(matrix,stmnt,r,c,stmnt.width+1,
              #                        # stmnt.branches[fs].height-3)
              #                        fH-3)
              # # And Route to it with a long diagonal arrow.
              # @arrows << [c + stmnt.width/2, r-1,
              #             # c + stmnt.width+1, r+stmnt.branches[fs].height-1]
              #             c + stmnt.width+1, r+fH-1]
              #             # c + stmnt.width+1, fH-1]
              # # And update the row to start with.
              # # r += stmnt.branches[fs].height-2
              # r += fH-2
              # # r = fH-2
              # Else branch, go down
              cur_r = self.next_row_matrix(matrix,c,r)
              # put a placeholder to forbid placing
              # an element between the if/case and the else.
              self.fill_place_matrix(matrix,stmnt,r,c,stmnt.width+1,
                                     cur_r-r-1)
              # Route to it downward.
              @arrows << [c + stmnt.width/2, r-1, 
                          c + stmnt.width + 1, cur_r + 1]
              r = cur_r
            else
              # Route it with a short left arrow.
              @arrows << [c + stmnt.width, r+1, c + stmnt.width+1, r+1]
            end
            # And go left.
            cur_r = r
            cur_c = c + stmnt.width + 1
          end
          # Place and route the branch.
          nW, nH =self.place_and_route_statement_matrix(branch,matrix,cur_r,cur_c)
          # Update the total fill size.
          fW = nW + 1 if fW < nW + 1
          fH = nH if fH < nH
          # Update the current row.
          r = cur_r + 3
          # Update the size of the matrix if required.
          while r >= matrix.size do
            matrix << ([ nil ] * matrix[0].size)
          end
        end
        # Fill again all the place used by the if/case.
        # self.fill_place_matrix(matrix,stmnt,r,c,fW,fH-3)
      when :par
        # Recurse on the branches.
        stmnt.place_and_route_par(c,r)
        # Then set the current statement in the matrix.
        self.fill_place_matrix(matrix,stmnt,r,c,stmnt.width+1,stmnt.height+1)
        # Update the fill size.
        fW = stmnt.width+1 if fW < stmnt.width + 1
        fH = stmnt.height if fH < stmnt.height
      when :seq
        # Recurse on the branches.
        stmnt.place_and_route_seq(c,r)
        # Then set the current statement in the matrix.
        self.fill_place_matrix(matrix,stmnt,r,c,stmnt.width+1,stmnt.height+1)
        # Update the fill size.
        fW = stmnt.width+1 if fW < stmnt.width + 1
        fH = stmnt.height if fH < stmnt.height
      else
        # Just set the current statement in the matrix.
        self.fill_place_matrix(matrix,stmnt,r,c,stmnt.width+1,3)
      end
      # Update the position in the matrix.
      r,c = self.next_place_matrix(matrix,0,r,c)
      # Recurse on successor if any.
      if stmnt.successor then
        self.place_and_route_statement_matrix(stmnt.successor,matrix,r,c)
      end
      puts "matrix placed for statement: #{stmnt.name}"
      return fW,fH
    end

    # Do the full place and route for a par block with initial
    # position +x+ and +y+.
    def place_and_route_par(x = 0, y = 0)
      puts "place_and_route_par for node: #{self.name} at x=#{x} y=#{y}"
      @xpos = 0
      @ypos = 0
      # First compute the number of statements to place horizontally.
      snum = self.number_statements
      # Also compute the width of a statement.
      swidth = self.branches[0].width
      puts "snum=#{snum}"
      # With is the rounded square root of the number of statements.
      hnum = Math.sqrt(snum).round
      # Create the matrix for placing the statements.
      matrix = [ [ nil ] * (hnum * swidth) ]
      # Do the placement inside the matrix.
      stmnt = @branches[0]
      self.place_and_route_statement_matrix(stmnt,matrix,0,0)
      # Place the statements according to the matrix.
      placed = Set.new # Set of already placed statement (to handle stretched statements)
      max_r, max_c = 0,0
      matrix.each_with_index do |row,r|
        row.each_with_index do |stmnt,c|
          next unless stmnt
          # Increase the size of the enclosing block
          max_r = r if max_r < r
          max_c = c if max_c < c
          next if placed.include?(stmnt) # Statement position already done
          stmnt.xpos = c
          stmnt.ypos = r
          # puts "position for statement: #{stmnt.name} xpos=#{stmnt.xpos} ypos=#{stmnt.ypos}"
          placed.add(stmnt) # The statement is placed.
        end
      end
      # Update the position and size of the block.
      self.move_deep(x,y)
      @width = max_c
      @height = max_r
      # @height += 1 if matrix[-1].any?
    end


    # Deeply place and route.
    def place_and_route_deep
      # puts "place_and_route_deep @type=#{@type}"
      case @type
      when :par, :seq
        # Place and route current block.
        if @type == :seq
          self.place_and_route_seq
        else
          self.place_and_route_par
        end
        # Place and route each of its statements.
        stmnt = @branches[0]
        while stmnt
          stmnt.place_and_route_deep
          stmnt = stmnt.successor
        end
      end
    end


    attr_reader :idC

    # Generate an assign description SVG text for node +n+
    def assign_svg(n)
      # The shape representing the instance.
      res = "<path fill=\"#B0E2FF\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/12.0}\" " +
        # "d=\"M #{n.xpos*@scale} #{(n.ypos + n.height/2.0)*@scale} " +
        # "L #{(n.xpos + 1.0)*@scale} #{n.ypos*@scale} " + 
        # "L #{(n.xpos + n.width-n.height/2.0)*@scale} #{n.ypos*@scale} " + 
        # "A #{n.height/2.0*@scale} #{n.height/2.0*@scale} 0 0 1 " +
        # "#{(n.xpos + n.width-n.height/2.0)*@scale} #{(n.ypos+n.height)*@scale} " +
        # "L #{(n.xpos + 1.0)*@scale} #{(n.ypos+n.height)*@scale} " + 
        "d=\"M #{n.xpos*@scale} #{(n.ypos + n.height)*@scale} " +
        "L #{(n.xpos + 1.0)*@scale} #{n.ypos*@scale} " + 
        "L #{(n.xpos + n.width)*@scale} #{n.ypos*@scale} " + 
        "L #{(n.xpos + n.width-1.0)*@scale} #{(n.ypos+n.height)*@scale} " +
        "Z \" />\n"
      # Its text.
      res += "<text id=\"text#{n.name}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(n.xpos + n.width/2.0)*@scale}\" "+
        "y=\"#{(n.ypos + n.height/2.0)*@scale}\">" +
        n.to_s + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{n.name}",(n.width-2)*@scale,
                               0.6*@scale)
      return res
    end

    # Generate a block description SVG text for node +n+
    def block_svg(n)
      res = "<rect fill=\"#fff\" fill-opacity=\"0.4\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/10.0}\" " +
        "stroke-dasharray=\"#{@scale/10.0},#{@scale/10.0}\" " +
        # "x=\"#{n.xpos*@scale}\" y=\"#{n.ypos*@scale}\" " +
        # "rx=\"#{@scale*2.0}\" " +
        # "width=\"#{n.width*@scale}\" "+
        # "height=\"#{n.height*@scale}\"/>\n"
        "x=\"#{(n.xpos-0.3)*@scale}\" y=\"#{(n.ypos-0.3)*@scale}\" " +
        "rx=\"#{@scale*0.6}\" " +
        "width=\"#{(n.width+0.6)*@scale}\" "+
        "height=\"#{(n.height+0.6)*@scale}\"/>\n"
      return res
    end

    # Generate an operator description SVG text for node +n+
    def operator_svg(n)
      ICIICI
      res = "<rect fill=\"#eee\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/16.0}\" " +
        "x=\"#{ic.xpos*@scale}\" y=\"#{ic.ypos*@scale}\" " +
        "rx=\"#{@scale}\" " +
        "width=\"#{ic.width*@scale}\" "+
        "height=\"#{ic.height*@scale}\"/>\n"
      # Its name.
      res += "<text class=\"medium#{self.idC}\" " +
        "style=\"inline-size=#{ic.width*@scale}px; text-anchor: middle; " +
        "dominant-baseline: middle;\" " +
        "x=\"#{(ic.xpos + ic.width/2.0)*@scale}\" "+
        "y=\"#{(ic.ypos + ic.height/2.0)*@scale}\">" +
        ic.name + "</text>\n"
      return res
    end

    # Generate a terminal description SVG for node +n+
    def terminal_svg(n)
      ICIICI
      res = "<rect fill=\"#ddd\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/32.0}\" " +
        "x=\"#{(ic.xpos-1/16.0)*@scale}\" y=\"#{(ic.ypos-1/16.0)*@scale}\" " +
        "rx=\"#{(1+1/16.0)*@scale}\" " +
        "width=\"#{(ic.width+1/8.0)*@scale}\" "+
        "height=\"#{(ic.height+1/8.0)*@scale}\"/>\n"
      res += "<rect fill=\"#ddd\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/32.0}\" " +
        "x=\"#{ic.xpos*@scale}\" y=\"#{ic.ypos*@scale}\" " +
        "rx=\"#{@scale}\" " +
        "width=\"#{ic.width*@scale}\" "+
        "height=\"#{ic.height*@scale}\"/>\n"
      # Its name.
      res += "<text class=\"medium#{self.idC}\" " +
        "style=\"inline-size=#{ic.width*@scale}px; text-anchor: middle; " +
        "dominant-baseline: middle;\" " +
        "x=\"#{(ic.xpos + ic.width/2.0)*@scale}\" "+
        "y=\"#{(ic.ypos + ic.height/2.0)*@scale}\">" +
        ic.name + "</text>\n"
      return res
    end

    # Generate an if description SVG text for node +n+,
    # where +no+ tells if there is an else branch.
    def if_svg(n,no=false)
      # The shape representing the instance.
      res = "<path fill=\"#B0E2FF\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/12.0}\" " +
        "d=\"M #{(n.xpos)*@scale} #{(n.ypos+n.height/2.0)*@scale} " +
        "L #{(n.xpos+n.width/2.0)*@scale} #{(n.ypos+n.height)*@scale} " + 
        "L #{(n.xpos+n.width)*@scale} #{(n.ypos+n.height/2.0)*@scale} " +
        "L #{(n.xpos+n.width/2.0)*@scale} #{(n.ypos)*@scale} " + 
        "Z \" />\n"
      # Its text.
      res += "<text id=\"text#{n.name}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(n.xpos + n.width/2.0)*@scale}\" "+
        "y=\"#{(n.ypos + n.height/2.0)*@scale}\">" +
        n.to_s + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{n.name}",(n.width-3)*@scale,
                               0.6*@scale)
      # The yes text.
      res += "<text " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"#{@scale/2.0}px\" " +
        "x=\"#{(n.xpos + n.width+0.1)*@scale}\" "+
        "y=\"#{(n.ypos + n.height/2.0+0.5)*@scale}\">" +
        "Yes" + "</text>\n"
      # The no text if any.
      if no then
        res += "<text " +
          "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
          "font-family=\"monospace\" font-size=\"#{@scale/2.0}px\" " +
          "x=\"#{(n.xpos + n.width/2.0+0.7)*@scale}\" "+
          "y=\"#{(n.ypos + n.height+0.3)*@scale}\">" +
          "No" + "</text>\n"
      end
      return res
    end

    # Generate a case description SVG text for node +n+,
    # where +no+ tells if there is an else branch.
    def case_svg(n,no=false)
      # The shape representing the instance.
      res = "<path fill=\"#B0E2FF\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/12.0}\" " +
        "d=\"M #{(n.xpos)*@scale} #{(n.ypos+n.height/2.0)*@scale} " +
        "L #{(n.xpos+n.width/2.0)*@scale} #{(n.ypos+n.height)*@scale} " + 
        "L #{(n.xpos+n.width)*@scale} #{(n.ypos+n.height/2.0)*@scale} " +
        "L #{(n.xpos+n.width/2.0)*@scale} #{(n.ypos)*@scale} " + 
        "Z \" />\n"
      # Its text.
      res += "<text id=\"text#{n.name}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(n.xpos + n.width/2.0)*@scale}\" "+
        "y=\"#{(n.ypos + n.height/2.0)*@scale}\">" +
        n.to_s + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{n.name}",(n.width-3)*@scale,
                               0.6*@scale)
      # The yes text.
      res += "<text " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"#{@scale/2.0}px\" " +
        "x=\"#{(n.xpos + n.width+0.1)*@scale}\" "+
        "y=\"#{(n.ypos + n.height/2.0+0.5)*@scale}\">" +
        "Yes" + "</text>\n"
      # The no text if any.
      if no then
        res += "<text " +
          "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
          "font-family=\"monospace\" font-size=\"#{@scale/2.0}px\" " +
          "x=\"#{(n.xpos + n.width/2.0+0.7)*@scale}\" "+
          "y=\"#{(n.ypos + n.height+0.3)*@scale}\">" +
          "No" + "</text>\n"
      end
      return res
    end

    # Generate a wait description SVG text for node +n+
    def wait_svg(n)
      # The shape representing the instance.
      res = "<path fill=\"#B0E2FF\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/12.0}\" " +
        "d=\"M #{n.xpos*@scale} #{(n.ypos)*@scale} " +
        "L #{(n.xpos + n.width-n.height/2.0)*@scale} #{n.ypos*@scale} " + 
        "A #{n.height/2.0*@scale} #{n.height/2.0*@scale} 0 0 1 " +
        "#{(n.xpos + n.width-n.height/2.0)*@scale} #{(n.ypos+n.height)*@scale} " +
        "L #{(n.xpos)*@scale} #{(n.ypos+n.height)*@scale} " + 
        "Z \" />\n"
      # Its text.
      res += "<text id=\"text#{n.name}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(n.xpos + n.width/2.0)*@scale}\" "+
        "y=\"#{(n.ypos + n.height/2.0)*@scale}\">" +
        n.to_s + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{n.name}",(n.width-1)*@scale,
                               0.6*@scale)
      return res
    end

    # Generate a repeat description SVG text for node +n+
    def repeat_svg(n)
      # Just like an if.
      return if_svg(n)
    end

    # Generate a terminate description SVG text for node +n+
    def terminate_svg(n)
      # The shape representing the instance.
      res = "<ellipse fill=\"#CC0202\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/12.0}\" " +
        "cx=\"#{n.xpos*@scale+n.width*@scale/2.0}\" " +
        "cy=\"#{(n.ypos)*@scale+n.height*@scale/2.0}\" " +
        "rx=\"#{n.width*@scale/2.0}\" ry=\"#{n.height*@scale/2.0}\" " +
        "/>\n"
      # Its text.
      res += "<text id=\"text#{n.name}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "fill=\"white\" " +
        "x=\"#{(n.xpos + n.width/2.0)*@scale}\" " +
        "y=\"#{(n.ypos + n.height/2.0)*@scale}\">" +
        "Terminate" + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{n.name}",(n.width-1)*@scale,
                               0.6*@scale)
      return res
    end

    # Generate a print description SVG text for node +n+
    def print_svg(n)
      # The shape representing the instance.
      res = "<rect fill=\"#B0E2FF\" stroke=\"#000\" " +
        "stroke-width=\"#{@scale/12.0}\" " +
        "x=\"#{n.xpos*@scale}\" y=\"#{(n.ypos)*@scale}\" " +
        "width=\"#{n.width*@scale}\" height=\"#{n.height*@scale}\" " +
        "/>\n"
      # Its text.
      res += "<text id=\"text#{n.name}\" " +
        "style=\"text-anchor: middle; dominant-baseline: middle;\" " +
        "font-family=\"monospace\" font-size=\"1px\" " +
        "x=\"#{(n.xpos + n.width/2.0)*@scale}\" "+
        "y=\"#{(n.ypos + n.height/2.0)*@scale}\">" +
        n.to_s + "</text>\n"
      # Its text resizing.
      res += Viz.svg_text_fit("text#{n.name}",(n.width-1)*@scale,
                               0.6*@scale)
      return res
    end

    # Generate an arrow description SVG text for connection nodes.
    # +x0+, +y0+, +x1+ and +y1+ are the coordinates of the arrow.
    def arrow_svg(x0,y0,x1,y1)
      # Draw the line.
        # Vertical part
      res =  "<line stroke=\"#000\" " +
        "stroke-width=\"#{@scale/12.0}\" stroke-linecap=\"round\" " +
        "x1=\"#{x0*@scale}\" " +
        "y1=\"#{y0*@scale}\" " +
        "x2=\"#{x0*@scale}\" " +
        "y2=\"#{y1*@scale}\" " +
        "/>\n"
        # Horizontal part
      res += "<line stroke=\"#000\" " +
        "stroke-width=\"#{@scale/12.0}\" stroke-linecap=\"round\" " +
        "x1=\"#{x0*@scale}\" " +
        "y1=\"#{y1*@scale}\" " +
        "x2=\"#{x1*@scale}\" " +
        "y2=\"#{y1*@scale}\" " +
        "/>\n"
      # The head.
      if x0 == x1 then
        # Vertical case
        res += "<polygon fill=\"#000\" stroke=\"none\" " +
          "points=\"#{(x1-1/4.0)*@scale},#{(y1-1/2.0-1/8.0)*@scale} " +
          "#{(x1+1/4.0)*@scale},#{(y1-1/2.0-1/8.0)*@scale} " +
          "#{(x1)*@scale},#{(y1)*@scale}\"/>\n"
      elsif x0 < x1 then
        # Horizontal left case: always end horizontally.
        res += "<polygon fill=\"#000\" stroke=\"none\" " +
          "points=\"#{(x1-1/2.0)*@scale},#{(y1-1/4.0)*@scale} " +
          "#{(x1-1/2.0)*@scale},#{(y1+1/4.0)*@scale} " +
          "#{(x1+1/8.0)*@scale},#{(y1)*@scale}\"/>\n"
      else
        # Horizontal right case: always end horizontally.
        res += "<polygon fill=\"#000\" stroke=\"none\" " +
          "points=\"#{(x1)*@scale},#{(y1+1/4.0)*@scale} " +
          "#{(x1)*@scale},#{(y1-1/4.0)*@scale} " +
          "#{(x1-1/8.0-1/2.0)*@scale},#{(y1)*@scale}\"/>\n"
      end
      return res
    end

    # Generate recursively the content of a flow from statement +stmnt+,
    # where +no+ tells if there is an else branch.
    def statement_svg_deep(stmnt,no=false)
      case stmnt.type
      when :assign
        res = assign_svg(stmnt)
      when :seq, :par
        res = block_svg(stmnt)
        # And its arrows.
        stmnt.arrows.each { |x0,y0,x1,y1| res += arrow_svg(x0,y0,x1,y1) }
      when :if
        res = if_svg(stmnt, no || stmnt.branches[2])
      when :case
        res = case_svg(stmnt, no || stmnt.branches[3])
      when :repeat
        res = repeat_svg(stmnt)
      when :wait
        res = wait_svg(stmnt)
      when :terminate
        res = terminate_svg(stmnt)
      when :print
        res = print_svg(stmnt)
      else
        # The other types are the condition expression, they are
        # not statements so they are skipped.
        return ""
      end
      # Recurse on the branches.
      case stmnt.type
      when :if, :case, :repeat
        fs = stmnt.type != :case ? 1 : 2 # First statement position.
        stmnt.branches[fs..-2].each {|b| res += statement_svg_deep(b,true) }
        res += statement_svg_deep(stmnt.branches[-1],false)
      when :seq, :par
        res += statement_svg_deep(stmnt.branches[0])
      end
      # And the successor
      res += statement_svg_deep(stmnt.successor) if stmnt.successor
      return res
    end

    # Generate in SVG format the graphical representation of the flow.
    # +top+ tells if it is the top IC.
    # +tx+ is the x translation of the full description.
    # +ty+ is the y translation of the full description.
    # +width+ is the forced width of the full description if any.
    # +height+ is the forced height of the full description if any.
    def to_svg(top = true, tx=0, ty=0, width=nil, height=nil)
      # puts "Node to_svg for node=#{self.name} top=#{top} type=#{@type}"
      # Compute the various sizes.
      x0,y0, x1,y1 = 0,0, @width*@scale, @height*@scale
      puts "x0,y0, x1,y1 = #{x0},#{y0}, #{x1}, #{y1}"
      bT = (@scale * 1.5)                # Border thickness
      pT = (bT / 5.0)                    # Port thickness
      wT = bT / 30.0                     # Wire thickness
      sF = @scale*0.4                    # Small font height
      mF = @scale*0.6                    # Medium font height
      lF = @scale*1.0                    # Large font height
      width  = (x1-x0)+bT*5 unless width
      height = (y1-y0)+bT*5 unless height
      # stx = (width - (x1-x0)-bT*5) / 2.0 # X translation of the top system
      # sty = (height - (y1-y0)-bT*5) / 2.0 # Y translation of the top system
      stx = (width - (x1-x0)) / 2.0 # X translation of the top system
      sty = (height - (y1-y0)) / 2.0 # Y translation of the top system
      puts "bT=#{bT} pT=#{pT} wT=#{wT} width=#{width} height=#{height}"
      # The initial visibility.
      visibility = top ? "visible" : "hidden"
      # The string used as suffix for style class names.
      @idC = "-" + self.name.gsub(/[:$]/,"-")
      # Generate the SVG code.
      if top then
        # It is the top node flow.
        # Generate the header.
        res = Viz.svg_header(self.name,x0,y0,width,height)
      else
        # It is not the top, no need of initialization.
        res = ""
      end

      # # Sets the styles.
      # res += "<style>\n"
      # # Fonts
      # res += ".small#{self.idC}  { font: #{sF}px monospace; }\n"
      # res += ".medium#{self.idC} { font: #{mF}px monospace; }\n"
      # res += ".large#{self.idC}  { font: #{lF}px monospace; }\n"
      # res += "</style>\n"

      # Generate the group containing all the flow description.
      res += "<g id=\"#{self.name}\" visibility=\"#{visibility}\" " +
             "transform=\"translate(#{tx},#{ty})\">\n"
      # Generate the rectangle of the bounding box.
      res += "<rect fill=\"#4682B4\" stroke=\"#007\" " +
        "stroke-width=\"#{@scale/4.0}\" " +
        # "x=\"#{x0-bT*2.5}\" y=\"#{y0-bT*2.5}\" "+
        "x=\"#{x0}\" y=\"#{y0}\" "+
        "width=\"#{width}\" height=\"#{height}\"/>\n"

      # Generate the group containing the top system and its contents.
      res += "<g transform=\"translate(#{stx},#{sty})\">\n"

      # Generate the node boxes.
      puts "Generate node box for self.type=#{self.type}"
      case self.type
      when :assign
        # The SVG object representing an assignment is to draw.
        res += assign_svg(self)
      when :seq, :par
        # The SVG objet repenting a block is to draw.
        res += block_svg(self)
        # Also generate its content.
        res += self.statement_svg_deep(self.branches[0])
        # And its arrows.
        @arrows.each { |x0,y0,x1,y1| res += arrow_svg(x0,y0,x1,y1) }
      end

      # Close the group containing the top system and its content.
      res += "</g>\n"
      # Close the group containing the description of the IC.
      res += "</g>\n"

      if top then
        # It is the top so close the SVG.
        res += "</svg>\n"
      end
      return res
    end
  end



  # Additional tools for generating or managing ICs.
  
  # Converts to a SVG-compatible text.
  def self.to_svg_text(name)
    return name.gsub(/&/,"&amp;").gsub(/</,"&lt;").gsub(/-@/,"-").gsub(/\+@/,"+")
  end

  # Converts to a SVG-compatible id.
  def self.to_svg_id(name)
    return name.gsub(/ /,"")
  end
  
  # Generate an input register name from +name+
  def self.reg2input_name(name)
    return name + "$I"
  end

  # Generate an output register name from +name+
  def self.reg2output_name(name)
    return name + "$O"
  end


  # Generate the svg header, global control scripts and helping panel.
  def self.header_svg(name,x0,y0,width,height)
    return <<~SVG
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
          "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg id="svg:#{name}" width="100%" height="100%" 
     viewBox="#{x0} #{y0} #{width} #{height}" 
     xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink" >

<script>
const diagram = document.getElementById('svg:#{name}');
const zoom = 1.0;
const deltaR = 100.0;
let x0 = #{x0};
let y0 = #{y0};
let width = #{width};
let height = #{height};
diagram.setAttribute('viewBox', `${x0} ${y0} ${width} ${height}`);

// Create an SVGPoint for conputing the location in the diagram
let pt = diagram.createSVGPoint();

// Get the location of the cursor in the diagram.
function cursorPoint(e){
  pt.x = e.clientX; pt.y = e.clientY;
  return pt.matrixTransform(diagram.getScreenCTM().inverse());
}

// Zooming function.
diagram.addEventListener("wheel", (e) => {
    let factor = 1.0 / (zoom * Math.exp(e.deltaY/deltaR))
    let loc = cursorPoint(e);
    x0 = x0 * factor;
    y0 = y0 * factor;
    width = width * factor;
    height = height * factor;
    let dx = (-loc.x) * (factor-1);
    let dy = (-loc.y) * (factor-1);
    x0 += dx;
    y0 += dy;
    diagram.setAttribute('viewBox', `${x0} ${y0} ${width} ${height}`);
});

// Moving function.
let isMoving = false;
let prevLoc;

diagram.addEventListener("mousedown", (e) => {
    prevLoc = cursorPoint(e);
    isMoving = true;
});

diagram.addEventListener("mouseup", (e) => {
    isMoving = false;
});

diagram.addEventListener("mousemove", (e) => {
    if (isMoving) {
        let loc = cursorPoint(e);
        let dx = prevLoc.x-loc.x;
        let dy = prevLoc.y-loc.y;
        x0 += dx;
        y0 += dy;
        diagram.setAttribute('viewBox', `${x0} ${y0} ${width} ${height}`);
    }
});

diagram.addEventListener("keydown", (e) => {
    switch(e.key) {
        case 'ArrowLeft':
            x0 -= width/100.0;
            break;
        case 'ArrowUp':
            y0 -= width/100.0;
            break;
        case 'ArrowRight':
            x0 += width/100.0;
            break;
        case 'ArrowDown':
            y0 += width/100.0;
            break;
    }
    diagram.setAttribute('viewBox', `${x0} ${y0} ${width} ${height}`);
});

</script>

SVG
  end

  # Generate a closing button symbol.
  # (Invisible by default, if "" is given as visibilty, not set here.
  def self.closing_svg(name,side,xpos,ypos,visibility="hidden")
    # The rectangle of the button.
    if visibility.empty? then
      res  = "<g id=\"#{name}\" >\n"
    else
      res  = "<g id=\"#{name}\" visibility=\"#{visibility}\">\n"
    end
    res += "<rect fill=\"#cd5c5c\" "+
      "stroke=\"#000\" stroke-width=\"#{side/8.0}\" " +
      "x=\"#{xpos}\" y=\"#{ypos}\" " +
      "width=\"#{side}\" height=\"#{side}\" />\n"
    # The cross lines.
    res += "<line stroke=\"#000\" stroke-width=\"#{side/8.0}\" " +
      "stroke-linecap=\"butt\" " +
      "x1=\"#{xpos}\" y1=\"#{ypos}\" " +
      "x2=\"#{xpos+side}\" y2=\"#{ypos+side}\" " +
      " />\n"
    res += "<line stroke=\"#000\" stroke-width=\"#{side/8.0}\" " +
      "stroke-linecap=\"butt\" " +
      "x1=\"#{xpos+side}\" y1=\"#{ypos}\" " +
      "x2=\"#{xpos}\" y2=\"#{ypos+side}\" " +
      " />\n"
    res += "</g>"
  end

  # Generate the help panel and its handling.
  def self.help_svg(x0,y0,width,height)
    # Compute the fit factor.
    fit = 1024.0/[width,height].min
    return <<~SVG
// Helping button.
<g id="$help$_open">
  <rect fill="yellow" stroke="#000" stroke-width="3"
   x="#{x0+width-62/fit}" y="#{y0+2/fit}" width="#{60/fit}" height="#{30/fit}" />
  <text style="text-anchor: middle; dominant-baseline: middle;" 
        font-family="monospace" font-size="#{20/fit}px"
        x="#{x0+width-32/fit}" y="#{y0+17/fit}" >
    Help
  </text>
</g>

// Helping panel.
<g id="$help$" visibility="hidden">
  <rect fill="#ffffd7" stroke="#000" stroke-width="6"
   x="#{x0}" y="#{y0}" width="#{width}" height="#{height}" />
   <text font-size="#{40/fit}px" font-family="serif" font-weight="bold"
    x="#{x0+width/2}" y="#{y0+40/fit}" >
    Help
   </text>

   <text font-size="#{30/fit}px" font-family="serif" font-weight="bold"
    x="#{x0+15/fit}" y="#{y0+100/fit}" >
   Navigation:
   </text>
   <text font-size="#{25/fit}px" font-family="serif" x="#{x0+25/fit}" y="#{y0+140/fit}" >
   Zoom in/out:
   </text>
   <text font-size="#{25/fit}px" font-family="serif" x="#{x0+190/fit}" y="#{y0+140/fit}" >
   mouse wheel.
   </text>
   <text font-size="#{25/fit}px" font-family="serif" x="#{x0+25/fit}" y="#{y0+170/fit}" >
   Move diagram:
   </text>
   <text font-size="#{25/fit}px" font-family="serif" x="#{x0+190/fit}" y="#{y0+170/fit}" >
   left click and drag, or arrow keys.
   </text>
   <text font-size="#{25/fit}px" font-family="serif" x="#{x0+25/fit}" y="#{y0+200/fit}" >
   Open element:
   </text>
   <text font-size="#{25/fit}px" font-family="serif" x="#{x0+190/fit}" y="#{y0+200/fit}" >
   left click on element.
   </text>
   <text font-size="#{25/fit}px" font-family="serif" x="#{x0+25/fit}" y="#{y0+230/fit}" >
   Close element:
   </text>
   <text font-size="#{25/fit}px" font-family="serif" x="#{x0+190/fit}" y="#{y0+230/fit}" >
   left click on the close button at the top right of the element.
   </text>

   <text font-size="#{30/fit}px" font-family="serif" font-weight="bold"
    x="#{x0+15/fit}" y="#{y0+300/fit}" >
   Types of elements:
   </text>
   #{
   # ic = IC.new("Instance",:instance)
   # ic.scale = 35.0
   # ic.xpos = (x0+15/fit) / ic.scale
   # ic.ypos = 330/fit / ic.scale
   # ic.width = 300/fit / ic.scale
   # ic.height = 100/fit / ic.scale
   # ic.instance_svg(ic)
   ic = IC.new("Instance",:instance)
   ic.scale = 35.0/fit
   ic.xpos = (x0+15)/fit / ic.scale
   ic.ypos = 330/fit / ic.scale
   ic.width = 300/fit / ic.scale
   ic.height = 100/fit / ic.scale
   ic.instance_svg(ic)
   }
   #{
   # ic = IC.new("Continuous assignment",:alu)
   # ic.scale = 35.0
   # ic.xpos = (x0+(15+300+15)/fit) / ic.scale
   # ic.ypos = 305/fit / ic.scale
   # ic.width = 300/fit / ic.scale
   # ic.height = 150/fit / ic.scale
   # p0 = Port.new("in0",ic,:input)
   # p0.side = LEFT
   # ic.ports << p0
   # p1 = Port.new("in1",ic,:input)
   # p1.side = LEFT
   # ic.ports << p1
   # p2 = Port.new("out",ic,:output)
   # p2.side = RIGHT
   # ic.alu_svg(ic)
   # ic.ports << p2
   # ic.alu_svg(ic)
   ic = IC.new("Continuous assignment",:alu)
   ic.scale = 35.0/fit
   ic.xpos = (x0+(15+300+15))/fit / ic.scale
   ic.ypos = 305/fit / ic.scale
   ic.width = 300/fit / ic.scale
   ic.height = 150/fit / ic.scale
   p0 = Port.new("in0",ic,:input)
   p0.side = LEFT
   ic.ports << p0
   p1 = Port.new("in1",ic,:input)
   p1.side = LEFT
   ic.ports << p1
   p2 = Port.new("out",ic,:output)
   p2.side = RIGHT
   ic.alu_svg(ic)
   ic.ports << p2
   ic.alu_svg(ic)
   }
   #{
   # ic = IC.new("Combinatorial process",:process)
   # ic.scale = 35.0
   # ic.xpos = (x0+15/fit) / ic.scale
   # ic.ypos = 480/fit / ic.scale
   # ic.width = 300/fit / ic.scale
   # ic.height = 100/fit / ic.scale
   # ic.process_svg(ic)
   ic = IC.new("Combinatorial process",:process)
   ic.scale = 35.0/fit
   ic.xpos = (x0+15)/fit / ic.scale
   ic.ypos = 480/fit / ic.scale
   ic.width = 300/fit / ic.scale
   ic.height = 100/fit / ic.scale
   ic.process_svg(ic)
   }
   #{
   # ic = IC.new("Clocked process",:clocked_process)
   # ic.scale = 35.0
   # ic.xpos = (x0+(15+300+15)/fit) / ic.scale
   # ic.ypos = 480/fit / ic.scale
   # ic.width = 300/fit / ic.scale
   # ic.height = 100/fit / ic.scale
   # ic.clocked_process_svg(ic)
   ic = IC.new("Clocked process",:clocked_process)
   ic.scale = 35.0/fit
   ic.xpos = (x0+(15+300+15))/fit / ic.scale
   ic.ypos = 480/fit / ic.scale
   ic.width = 300/fit / ic.scale
   ic.height = 100/fit / ic.scale
   ic.clocked_process_svg(ic)
   }
   #{
   # ic = IC.new("Time process",:timed_process)
   # ic.scale = 35.0
   # ic.xpos = (x0+(15+300+15+300+15)/fit) / ic.scale
   # ic.ypos = 480/fit / ic.scale
   # ic.width = 300/fit / ic.scale
   # ic.height = 100/fit / ic.scale
   # ic.timed_process_svg(ic)
   ic = IC.new("Time process",:timed_process)
   ic.scale = 35.0/fit
   ic.xpos = (x0+(15+300+15+300+15))/fit / ic.scale
   ic.ypos = 480/fit / ic.scale
   ic.width = 300/fit / ic.scale
   ic.height = 100/fit / ic.scale
   ic.timed_process_svg(ic)
   }
   #{
   # ic = IC.new("Signal",:register)
   # ic.scale = 35.0
   # ic.xpos = (x0+15/fit) / ic.scale
   # ic.ypos = 600/fit / ic.scale
   # ic.width = 150/fit / ic.scale
   # ic.height = 75/fit / ic.scale
   # ic.register_svg(ic)
   ic = IC.new("Signal",:register)
   ic.scale = 35.0/fit
   ic.xpos = (x0+15)/fit / ic.scale
   ic.ypos = 600/fit / ic.scale
   ic.width = 150/fit / ic.scale
   ic.height = 75/fit / ic.scale
   ic.register_svg(ic)
   }
   #{
   # ic = IC.new("Memory",:memory)
   # ic.scale = 35.0
   # ic.xpos = (x0+(15+200+15)/fit) / ic.scale
   # ic.ypos = 600/fit / ic.scale
   # ic.width = 200/fit / ic.scale
   # ic.height = 100/fit / ic.scale
   # ic.memory_svg(ic)
   ic = IC.new("Memory",:memory)
   ic.scale = 35.0/fit
   ic.xpos = (x0+(15+200+15))/fit / ic.scale
   ic.ypos = 600/fit / ic.scale
   ic.width = 200/fit / ic.scale
   ic.height = 100/fit / ic.scale
   ic.memory_svg(ic)
   }

   <text font-size="#{30/fit}px" font-family="serif" font-weight="bold"
    x="#{x0+15/fit}" y="#{y0+800/fit}" >
   Contents of processes and assigments:
   </text>
   <text font-size="#{25/fit}px" font-family="serif" x="#{x0+25/fit}" y="#{y0+840/fit}" >
   Represented as sets of parallel flow charts.
   </text>

   // Closing button for the helping panel.
   #{Viz.closing_svg("$help$_close",20/fit,width-20/fit,0,"")}
</g>

// Control of the helping panel.
<script>
diagram.getElementById('$help$_open').addEventListener("click", (e) => {
    // For the element.
    let elem = diagram.getElementById('$help$');
    elem.setAttribute('visibility','visible');
});
diagram.getElementById('$help$_close').addEventListener("click", (e) => {
    // For the element.
    let elem = diagram.getElementById('$help$');
    elem.setAttribute('visibility','hidden');
});
</script>

SVG
  end

  # Generate a script for resizing a font to fit +width+ for text object
  # +name+, with max font size +max_size+ px.
  def self.svg_text_fit(name,width,max_size)
    return <<~SCRIPT
<script> 
    fitWidth=#{width};
    textNode = document.getElementById("#{self.to_svg_id(name)}");
    textBB = textNode.getBBox();
    fitSize = fitWidth / textBB.width;
    if (fitSize > #{max_size}) fitSize = #{max_size};
    textNode.setAttribute("font-size", fitSize + "px")
 </script>
SCRIPT
  end

end





# Extend the sytemT class for conversion to Viz format.
class HDLRuby::Low::SystemT
  def to_viz
    puts "Generating VIZ representation for system #{self.name}..."
    # The registers.
    regs = {}
    # The existing ports by name for further connections.
    ports = Hash.new { |h,k| h[k] = [] }
    # The ports explicit connections lists.
    # Named +links+ to avoid confusion with HDLRuby connection objects.
    links = []
    # Create the viz for the current systemT.
    world = HDLRuby::Viz::IC.new(self.name.to_s,:module)
    # Adds its ports.
    self.each_input  do |port|
      puts "Adding input port #{port.name} to #{world.name}"
      name = port.name.to_s
      ports[name] << world.add_port(name, :input)
    end
    self.each_output do |port|
      puts "Adding output port #{port.name} to #{world.name}"
      name = port.name.to_s
      ports[name] << world.add_port(name, :output)
    end
    self.each_inout  do |port| 
      puts "Adding inout port #{port.name} to #{world.name}"
      name = port.name.to_s
      ports[name] << world.add_port(name, :inout)
    end
    # Recurse on the scope.
    self.scope.to_viz(world,regs,ports,links)
    # Do the connection by maching names of each port and handling
    # the connections between signals.
    # First connect the ports with same name of different ic.
    # ports.each_value do |subs|
    ports.each do |name,subs|
      # Skip connection to registers, they are processed later.
      next if regs[name]
      # Not a register, can go on.
      subs.each do |p0|
        subs.each do |p1|
          # puts "p0=#{p0.name} ic=#{p0.ic.name} p1=#{p1.name} ic=#{p1.ic.name}"
          if p0.ic != p1.ic then
            # Ports are from different IC, we can connect thems.
            puts "Connect by name in ic=#{world.name}."
            world.connect(p0,p1) unless p0.targets.include?(p1)
          end
        end
      end
    end
    # Connect the registers.
    ports.each do |name,subs|
      # Check if there is a register corresponding to the port
      # (full port or sub port of the register).
      next if name.include?("$") # Skip register ports which are targets.
      rname = name
      while !regs.key?(rname) do
        break unless rname.include?(".")
        rname = rname.gsub(/\.[^.]*$/,"")
      end
      reg = regs[rname]
      next unless reg
      # Connect the register, once per ic and direction.
      subs.uniq {|p| [p.ic,p.direction] }.each do |p|
        # puts "Connect to register port name #{name} in ic=#{world.name} with port=#{p.name}"
        if p.direction == :output then
          world.connect(p,ports[HDLRuby::Viz.reg2input_name(name)][0])
        elsif p.direction == :input then
          world.connect(ports[HDLRuby::Viz.reg2output_name(name)][0],p)
        else
          world.connect(p,ports[HDLRuby::Viz.reg2input_name(name)][0])
          world.connect(ports[HDLRuby::Viz.reg2output_name(name)][0],p)
        end
      end
    end
    # Then connects according to the explicit connections.
    links.each do |n0,n1|
      puts "n0=#{n0} n1=#{n1}"
      # Is n0 a register?
      reg = regs[n0]
      if reg then
        # Yes, connect its input port.
        p0 = ports[HDLRuby::Viz.reg2input_name(n0)][0]
      else
        # No, it is a normal port.
        p0 = ports[n0][0]
      end
      # In n1 a register?
      reg = regs[n1]
      if reg then
        # Yes, connect its output port.
        p1 = ports[HDLRuby::Viz.reg2output_name(n1)][0]
      else
        # No, it is a normal port.
        p1 = ports[n1][0]
      end
      # NOTE: p0 or p1 may be empty if outside current module.
      world.connect(p0,p1) unless (!p0 or !p1 or p0.targets.include?(p1))
    end
    # Remove the dangling input ports in registers (they are ROMS).
    regs.each_value do |reg|
      to_remove_input = reg.ports.select {|p| p.direction==:input }.all? do
        |p|
        p.targets.none?
      end
      if to_remove_input then
        reg.ports.delete_if {|p| p.direction == :input }
      end
    end
    # Return the resulting visualization.
    return world
  end
end


# Extend the Scope class for conversion to Viz format.
class HDLRuby::Low::Scope
  # Converts the scope to a Viz struture inside +world+, updating
  # the table of ports +ports+, the table of registers +regs+ and 
  # explicit port connections +links+ with root name +rname+.
  def to_viz(world, regs, ports, links, rname = "")
    # If it is a sub scope:
    # Compute the name of the scope which will be used as prefix.
    if self.parent.is_a?(HDLRuby::Low::Scope) then
      sname = self.name.empty? ? "" : self.name.to_s + "."
      sname = rname + sname # Add the root name.
    else
      sname = ""
    end
    # Adds the inner as "registers" with input and output ports
    # of identical name.
    self.each_inner do |inner|
      typ = inner.type
      typ = typ.def while typ.is_a?(HDLRuby::Low::TypeDef)
      # name = sname + inner.name.to_s
      # name = inner.name.to_s
      name = sname + inner.name.to_s
      # Create the viz for the "register"
      if typ.is_a?(HDLRuby::Low::TypeVector) and
          typ.base.width > 1 then
        puts "Adding scope register #{name} to #{world.name}"
        # This is in fact a memory matrix.
        reg = HDLRuby::Viz::IC.new(name,:memory,world)
      else
        puts "Adding plain register #{name} to #{world.name}"
        # This is a plain register.
        reg = HDLRuby::Viz::IC.new(name,:register,world)
      end
      regs[reg.name] = reg
      # Create the corresponding input and output ports.
      iname = HDLRuby::Viz.reg2input_name(name)
      puts "Adding input port #{iname} to reg #{reg.name}"
      ports[iname] << reg.add_port(iname,:input) 
      oname = HDLRuby::Viz.reg2output_name(name)
      puts "Adding output port #{oname} to reg #{reg.name}"
      ports[oname] << reg.add_port(oname,:output)
      if typ.is_a?(HDLRuby::Low::TypeStruct) then
        # Add ports for each sub type.
        typ.each do |sub,styp|
          isname = HDLRuby::Viz.reg2input_name(name + "." + sub.to_s)
          puts "Adding input sub port #{isname} to reg #{reg.name}"
          ports[isname] << reg.add_port(isname,:input)
          osname = HDLRuby::Viz.reg2output_name(name + "." + sub.to_s)
          puts "Adding output sub port #{osname} to reg #{reg.name}"
          ports[osname] << reg.add_port(osname,:output)
        end
      end
    end
    # Adds the instances.
    self.each_systemI do |instance|
      # Create the viz for the systemT it is instantiating.
      sys_viz = instance.systemT.to_viz
      # Create the viz for the instance.
      # ic = HDLRuby::Viz::IC.new(instance.name.to_s,:instance,world,sys_viz)
      ic = HDLRuby::Viz::IC.new(sname + instance.name.to_s,:instance,world,sys_viz)
      # And adds its ports.
      instance.each_input  do |port|
        name = ic.name + "." + port.name.to_s
        puts "Adding input port #{name} to #{ic.name}"
        ports[name] << ic.add_port(name, :input)
      end
      instance.each_output do |port| 
        name = ic.name + "." + port.name.to_s
        puts "Adding output port #{name} to #{ic.name}"
        ports[name] << ic.add_port(port.name, :output)
      end
      instance.each_inout  do |port|
        name = ic.name + "." + port.name.to_s
        puts "Adding inout port #{name} to #{ic.name}"
        ports[name] << ic.add_port(port.name, :inout)
      end
    end
    # Adds its connections with expressions, 
    # they will also be considered as inner ICs.
    # For the other connections, register then a explicit port
    # connections.
    self.each_connection do |connection|
      if connection.right.is_a?(HDLRuby::Low::RefName) then
        # Explicit port connect case.
        links << [ connection.left.to_viz_names[0],
                   connection.right.to_viz_names[0] ]
        # # Get the right refered name.
        # rname = connection.right.to_viz_names[0]
        # # If it is a register make the name its output.
        # rname = HDLRuby::Viz.reg2output_name(rname) if regs[rname]
        # # Get the left refered name.
        # lname = connection.left.to_viz_names[0]
        # # If it is a register make the name its input.
        # lname = HDLRuby::Viz.reg2input_name(lname) if regs[lname]
        # # Make the explicit port connect.
        # links << [ lname, rname ]
        # Add the explicit port connection.
        puts "added link between #{links[-1][0]} and #{links[-1][1]}"
        next
      end
      ic = HDLRuby::Viz::IC.new(HDLRuby.uniq_name("cxn"),:assign,world)
      # Add its ports.
      # Output.
      name = connection.left.to_viz_names[0]
      puts "Adding output port #{name} to #{ic.name}"
      ports[name] << ic.add_port(name, :output) unless ic.port?(name)
      # Inputs.
      connection.right.to_viz_names.each do |name|
        puts "Adding input port #{name} to #{ic.name}"
        ports[name] << ic.add_port(name, :input) unless ic.port?(name)
      end
      # Create its control flow.
      connection.to_viz_node(ic)
    end

    # Adds its behaviors, they will also be considered as inner ICs.
    self.each_behavior do |behavior|
      bname = HDLRuby.uniq_name("proc").to_s
      # Is it a clocked process.
      if (behavior.each_event.any? { |ev| ev.on_edge? }) then
        # Yes.
        ic = HDLRuby::Viz::IC.new(bname,:clocked_process,world)
        # No, is it a timed process.
      elsif behavior.block.is_a?(HDLRuby::Low::TimeBlock)
        # Yes
        ic = HDLRuby::Viz::IC.new(bname,:timed_process,world)
      else
        # No, use a standard process type.
        ic = HDLRuby::Viz::IC.new(bname,:process,world)
      end
      # Add its ports.
      # For the events.
      behavior.each_event do |ev|
        name = ev.ref.to_viz_names[0]
        next if ic.port?(name) # The port has already been added.
        # Is it a clocked event?
        if ev.on_edge? then
          # Yes.
          ports[name] << ic.add_port(name, :input, ev.type)
        else
          # No, use a standard port.
          ports[name] << ic.add_port(name, :input)
        end
      end
      # Recurse on its blocks.
      # behavior.block.to_viz(world,ic,ports)
      behavior.block.to_viz(world,ic,regs,ports)
    end
    # Recurse on the sub scopes.
    # self.each_scope {|scope| scope.to_viz(world,regs,ports,scope.name.to_s) }
    self.each_scope {|scope| scope.to_viz(world,regs,ports,sname) }
    # Return the world, not necessary but is more coherent.
    return world
  end
end



class HDLRuby::Low::Transmit
  # Converts the transmit to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(:assign,parent)
    # And generate the left and right children.
    self.left.to_viz_node(node)
    self.right.to_viz_node(node)
    return node
  end
end


class HDLRuby::Low::If
  # Converts the if to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(:if,parent)
    # Generate the condition.
    self.condition.to_viz_node(node)
    # And generate the sub statments.
    self.yes.to_viz_node(node)
    self.each_noif do |cond,stmnt|
      sub = HDLRuby::Viz::Node.new(:if,node)
      cond.to_viz_node(sub)
      stmnt.to_viz_node(sub)
    end
    self.no.to_viz_node(node) if self.no
    return node
  end
end


class HDLRuby::Low::Case
  # Converts the case to a Viz flow node under +parent+.
  def to_viz_node(parent)
    # node = HDLRuby::Viz::Node.new(:case,parent)
    # # Generate the value.
    # self.value.to_viz_node(node)
    # # And generate the sub statments.
    # self.each_when do |w|
    #   sub = HDLRuby::Viz::Node.new(:when,node)
    #   w.match.to_viz_node(sub)
    #   w.statement.to_viz_node(sub)
    # end
    # self.default.to_viz_node(node) if self.default
    # return node
    node = parent
    # Generate one node per possible value.
    self.each_when do |w|
      sub = HDLRuby::Viz::Node.new(:case,node)
      self.value.to_viz_node(sub) # Readd the value to compare
      w.match.to_viz_node(sub)
      w.statement.to_viz_node(sub)
      node = sub if node == parent # Set the first node
    end
    self.default.to_viz_node(node) if self.default
    return node
  end
end


class HDLRuby::Low::Block
  # Converts the block to a Viz struture inside +world+ for +ic+, updating
  # the table of ports +ports+, the table of registers +reg+ and
  # with root name +rname+.
  def to_viz(world, ic, regs, ports, rname = "")
    # Compute the name of the block which will be used as prefix.
    bname = self.name.empty? ? "" : self.name.to_s + "."
    bname = rname + bname # Add the root name.
    # Adds the inner as "registers" with input and output ports
    # of identical name.
    self.each_inner do |inner|
      name = bname + inner.name.to_s
      puts "Adding block register #{name} to #{world.name}"
      # Create the viz for the "register"
      if inner.type.base.width > 1 then
        # This is in fact a memory matrix.
        reg = HDLRuby::Viz::IC.new(name,:memory,world)
      else
        reg = HDLRuby::Viz::IC.new(name,:register,world)
      end
      regs[reg.name] = reg
      # Create the corresponding input and output ports.
      iname = HDLRuby::Viz.reg2input_name(name)
      puts "Adding input port #{iname} to #{world.name}"
      # ports[iname] << ic.add_port(iname,:input) 
      ports[iname] << reg.add_port(iname,:input) 
      oname = HDLRuby::Viz.reg2output_name(name)
      puts "Adding output port #{oname} to #{world.name}"
      # ports[oname] << ic.add_port(oname,:output)
      ports[oname] << reg.add_port(oname,:output)
    end
    # For the statements.
    iports = {}
    oports = {}
    self.each_statement_deep do |stmnt|
      if stmnt.is_a?(HDLRuby::Low::If) then
        # The main condition may have inputs.
        stmnt.condition.to_viz_names.each do |name|
          if oports.key?(name) then
            # Change to inout port.
            puts "Changed port #{name} to inout"
            oports[name].direction = :inout
            next
          end
          puts "Adding input port #{name} to #{ic.name}"
          unless iports.key?(name) then
            port = ic.add_port(name, :input)
            ports[name] << port
            iports[name] = port
          end
        end
        # The elsif conditions too.
        stmnt.each_noif do |nocond,stmnt|
          nocond.to_viz_names.each do |name|
            if oports.key?(name) then
              # Change to inout port.
              puts "Changed port #{name} to inout"
              oports[name].direction = :inout
              next
            end
            puts "Adding input port #{name} to #{ic.name}"
            unless iports.key?(name) then
              port = ic.add_port(name, :input)
              ports[name] << port
              iports[name] = port
            end
          end
        end
      elsif stmnt.is_a?(HDLRuby::Low::Case) then
        # The value may have inputs.
        stmnt.value.to_viz_names.each do |name|
          # if iports.key?(name) then
          if oports.key?(name) then
            # Change to inout port.
            puts "Changed port #{name} to inout"
            # iports[name].direction = :inout
            oports[name].direction = :inout
            next
          end
          puts "Adding input port #{name} to #{ic.name}"
          unless iports.key?(name) then
            port = ic.add_port(name, :input)
            ports[name] << port
            iports[name] = port
          end
        end
      end

      next unless stmnt.is_a?(HDLRuby::Low::Transmit)
      name = stmnt.left.to_viz_names[0]
      if iports.key?(name) then
        # Change to inout port.
        iports[name].direction = :inout
        next
      end
      # Add one port by output name.
      unless oports.key?(name) then
        puts "Adding output port #{name} to #{ic.name}"
        port = ic.add_port(name, :output)
        ports[name] << port
        oports[name] = port
      end
      stmnt.right.to_viz_names.each do |name|
        if oports.key?(name) then
          # Change to inout port.
          oports[name].direction = :inout
          next
        end
        # Add one port by input name.
        unless iports.key?(name) then
          puts "Adding input port #{name} to #{ic.name}"
          port = ic.add_port(name,:input)
          ports[name] << port
          iports[name] = port
        end
      end
    end
    # Create its control flow.
    self.to_viz_node(ic)
    # Return the world, not necessary but is more coherent.
    return world
  end


  # Converts the block to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(self.mode,parent)
    prev = nil
    self.each_statement do |stmnt| 
      succ = stmnt.to_viz_node(node)
      prev.successor = succ if prev
      prev = succ
    end
    unless prev then
      # There were no statement in the block, create a dummy one
      # as placeholder.
      HDLRuby::Viz::Node.new(:empty,node)
    end
    return node
  end
end


class HDLRuby::Low::TimeWait
  # Converts the transmit to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(:wait,parent)
    # And generate the children.
    self.delay.to_viz_node(node)
    return node
  end
end


class HDLRuby::Low::TimeRepeat
  # Converts the transmit to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(:repeat,parent)
    # And generate the children.
    self.number.to_expr.to_viz_node(node)
    self.statement.to_viz_node(node)
    return node
  end
end


class HDLRuby::Low::TimeTerminate
  # Converts the transmit to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(:terminate,parent)
    return node
  end
end


class HDLRuby::Low::Delay
  # Converts the transmit to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(:delay,parent, 
                                  self.value.to_s + self.unit.to_s)
    return node
  end
end


class HDLRuby::Low::Print
  # Converts the transmit to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(:print,parent)
    # And generate the children.
    self.each_arg {|arg| arg.to_viz_node(node) }
    return node
  end
end


class HDLRuby::Low::Expression
  # Get the port names for visualization from the expression.
  def to_viz_names
    res = []
    self.each_node do |expr|
      res += expr.to_viz_names
    end
    return res
  end
end


class HDLRuby::Low::Value
  # Converts the value to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(:value,parent,self.content.to_s)
    return node
  end
end


class HDLRuby::Low::StringE
  # Converts the value to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(:string,parent,self.content.to_s)
    return node
  end
end


class HDLRuby::Low::Cast
  # Converts the value to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(:cast,parent,self.type.to_viz_name)
    # And generate the children.
    self.child.to_viz_node(node)
    return node
  end
end


class HDLRuby::Low::Operation
  # Converts the operation to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(self.operator,parent)
    # And generate the children.
    self.each_node {|child| child.to_viz_node(node) }
    return node
  end
end


class HDLRuby::Low::Concat
  # Converts the operation to a Viz flow node under +parent+.
  def to_viz_node(parent)
    node = HDLRuby::Viz::Node.new(:concat,parent)
    # And generate the children.
    self.each_node {|child| child.to_viz_node(node) }
    return node
  end
end


class HDLRuby::Low::RefConcat
  # Get the port names for visualization from the expression.
  def to_viz_names
    return self.each_ref.map {|ref| ref.to_viz_names }.flatten
  end

  # Converts the index reference to a Viz flow node under +parent+.
  def to_viz_node(parent)
    # Create the viz node.
    node = HDLRuby::Viz::Node.new(:concat,parent)
    # And generate the children.
    self.each_node {|child| child.to_viz_node(node) }
    return node
  end
end


class HDLRuby::Low::RefIndex
  # Get the port names for visualization from the expression.
  def to_viz_names
    return self.ref.to_viz_names + self.index.to_viz_names
  end

  # Converts the index reference to a Viz flow node under +parent+.
  def to_viz_node(parent)
    # Create the viz node.
    node = HDLRuby::Viz::Node.new(:[],parent)
    # Generate the base.
    self.ref.to_viz_node(node)
    # Generate the index.
    self.index.to_viz_node(node)
    return node
  end
end


class HDLRuby::Low::RefRange
  # Get the port names for visualization from the expression.
  def to_viz_names
    return self.ref.to_viz_names +
      self.range.first.to_viz_names + self.range.last.to_viz_names
  end

  # Converts the index reference to a Viz flow node under +parent+.
  def to_viz_node(parent)
    # Create the viz node.
    node = HDLRuby::Viz::Node.new(:[],parent)
    # Generate the base.
    self.ref.to_viz_node(node)
    # Generate the range.
    self.range.first.to_viz_node(node)
    self.range.last.to_viz_node(node)
    return node
  end
end


class HDLRuby::Low::RefName
  # Get the port names for visualization from the expression.
  def to_viz_names
    res = self.ref.to_viz_names[0]
    res += "." unless res.empty?
    return [ res + self.name.to_s ]
  end

  # Converts the index reference to a Viz flow node under +parent+.
  def to_viz_node(parent)
    # Create the viz node.
    node = HDLRuby::Viz::Node.new(:".",parent,self.name.to_s)
    # Generate the base if any.
    self.ref.to_viz_node(node)
    return node
  end
end


class HDLRuby::Low::RefThis
  # Get the port names for visualization from the expression.
  def to_viz_names
    return [ "" ]
  end 

  # No Viz here.
  def to_viz_node(parent)
    return nil
  end
end


class HDLRuby::Low::Type
  # Convert to a name usable in a Viz representation.
  def to_viz_name
    return self.name.to_s
  end
end


class HDLRuby::Low::TypeVector
  # Convert to a name usable in a Viz representation.
  def to_viz_name
    fstr = self.range.first.is_a?(HDLRuby::Low::Value) ? self.range.first.content.to_s : self.range.first.to_s
    lstr = self.range.last.is_a?(HDLRuby::Low::Value) ? self.range.last.content.to_s : self.range.last.to_s
    return self.base.to_viz_name + "[" + fstr + ".." + lstr + "]"
  end
end


class HDLRuby::Low::TypeTuple
  # Convert to a name usable in a Viz representation.
  def to_viz_name
    return "["+ self.each_type.map {|sub| sub.to_viz_name }.join(",") +"]"
  end
end


class HDLRuby::Low::TypeStruct
  # Convert to a name usable in a Viz representation.
  def to_viz_name
    return "{" + self.types.map {|k,sub| k.to_s + " =&rt; " + sub.to_viz_name }.join(",") + "}"
  end
end
