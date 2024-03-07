
module HDLRuby::High::Std

  ##
  # Standard HDLRuby::High library: 
  # The idea is to be able to write sw-like sequential code.
  # 
  ########################################################################


  ## Class describing a board.
  class Board

    include Hmissing

    attr_reader :namespace
    
    ## Class describing a row of slide switches.
    SW = Struct.new(:id, :size) do
      def to_html
        <<-HTMLSW
  <label class="swset" id="#{@id}" data-value="0">
    #{@size.times.map { |i| '<div><input type="checkbox" class="sw" />' +
        '<span class="slider"></span></div>' }.join("\n") }
  </label>
HTMLSW
      end
    end

    ## Class describing a row of buttons.
    BT = Struct.new(:id, :size) do
      def to_html
        <<-HTMLBT
  <label class="btset" id="#{@id}" data-value="0">
    #{@size.times.map { |i| '<div><input type="button" class="bt" /></div>'
                      }.join("\n") } 
  </label>
HTMLBT
      end
    end

    ## Class describing a row of LEDs.
    LED = Struct.new(:id, :size) do
      def to_html
        <<-HTMLLED
  <label class="ledset" id="#{@id}" data-value="0">
    #{@size.times.map { |i| '<i class="led" class="led_off"/></i>' }.join("\n") }
  </label>
HTMLLED
      end
    end

    ## Class describing a digit display.
    DIGIT = Struct.new(:id, :size)

    ## Class describing an ascii display.
    ASCII = Struct.new(:id, :size)

    ## Class describing a bitmap display.
    BITMAP = Struct.new(:id, :width, :height)

    ## Class describing an oscilloscope.
    #  +width+, +height+ are the dimension in pixels of the display.
    #  +range+ is the value range that can be displayed, 
    #  +rate+ is the refresh rate.
    SCOPE  = Struct.new(:id, :width, :height, :range, :rate)


    ## The base HTML/Javascript/Ajax code of the FPGA UI: 
    # header
    UI_header = <<-HTMLHEADER
HTTP/1.1 200
Content-Type: text/html

<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  .title {
    font-size: 20px;
    padding: 25px;
  }

  .sw {
    position: relative;
    display: inline-block;
    width:  24px;
    height: 48px;
  }
  
  .sw input { 
    opacity: 0;
    width: 0;
    height: 0;
  }
  
  .slider {
    position: absolute;
    cursor: pointer;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: #ccc;
    -webkit-transition: .4s;
    transition: .4s;
  }
  
  .slider:before {
    position: absolute;
    content: "";
    height: 20px;
    width: 20px;
    left: 4px;
    bottom: 4px;
    background-color: white;
    -webkit-transition: .4s;
    transition: .4s;
  }
  
  input:checked + .slider {
    background-color: #2196F3;
  }
  
  input:focus + .slider {
    box-shadow: 0 0 1px #2196F3;
  }
  
  input:checked + .slider:before {
    -webkit-transform: translateX(20px);
    -ms-transform: translateX(20px);
    transform: translateX(20px);
  }


  .led_off { 
    height: 20px;  
    width: 20px; 
    border: solid 2px;  
    border-radius: 50%;  
    background-color: white;
    display: inline-block;
  }

  .led_on { 
    height: 20px;  
    width: 20px; 
    border: solid 2px;  
    border-radius: 50%;  
    background-color: red;
    display: inline-block;
  }

</style>
</head>

<body>

<div id="cartouche" class="title">
Name of the FPGA board
</div>

<div id="panel"></div>

<script>
  // Access to the components of the UI.
  const cartouche = document.getElementById("cartouche");
  const panel     = document.getElementById("panel");

  // The input and output elements.
  const input_elements = [];
  const output_elements = [];

  // The control functions.

  // Set the cartouche of the board.
  function set_cartouche(txt) {
    cartouche.innerHTML = txt;
  }

  // Add an element.
  function add_element(txt) {
    panel.innerHTML += txt;
    const element = panel.lastElementChild();
    // Depending of the kind of element.
    if (element.classList().contains('swset') ||
        element.classList().contains('btset')) {
        // Input element.
        input_elements.push(element);
    } else {
        // Output element.
        output_elements.push(element);
    }
  }

  // Handler of sw change.
  function sw_change(sw) {
    // Get the set holding sw.
    const swset = sw.parentElement();
    if (sw.checked) { 
      swset.dataset.value = swset.dataset.value | (1 << sw.dataset.bit);
    }
    else {
      swset.dataset.value = swset.dataset.value & ~(1 << sw.dataset.bit);
    }
    // Synchornize with HDLRuby.
    hruby_sync(swset);
  }

  // Switch a led on.
  function led_on(led) {
    led.classList.remove('led_off');
    led.classList.add('led_on');
  }

  // Switch a led off.
  function led_off(led) {
    led.classList.remove('led_on');
    led.classList.add('led_off');
  }
  
  // Update a led set.
  function ledset_update(ledset,value) {
    // Update the ledset value.
    ledset.dataset.value = value;
    // Update each led.
    // Get the individual leds.
    let leds = document.getElementsByTagName("*");
    // Set each led of the set.
    for(let i=0; i < leds.length; ++i) {
      const val = (value >> i) & 1;
      if (val == 1) { led_on(leds[i]); }
      else          { led_off(leds[i]); }
    }
  }

  // Synchronize with the HDLRuby simulator.
  function hruby_sync() {
    let xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
      if (this.readyState == 4 && this.status == 200) {
        // Update the interface with the answer.
        const commands = this.responseText.split(';');
        for(command of commands) {
           const toks = command.split(':');
           element_update(document.getElementById(toks[0]),toks[1]);
        }
      }
    };
    // Builds the action from the state of the input elements.
    act = '';
    for(element of input_elements) {
      act += element.id + ':' + element.dataset.value + ';';
    }
    xhttp.open("GET", act, true);
    xhttp.send();
  }

  // First call of synchronisation.
  hruby_sync();

  // Then periodic synchronize.
  setInterval(function() { hruby_sync; }, period);

</script>

HTMLHEADER

    # Footer
    UI_footer = <<-HTMLFOOTER
</body>
</html>
HTMLFOOTER


    # The already used ports.
    @@http_ports = []


    # Create a new board named +name+ accessible on HTTP port +http_port+
    # and whose content is describe in +block+.
    def initialize(name, http_port = 8000, &block)
      # Set the name.
      @name = name.to_s
      # Check and set the port.
      http_port = http_port.to_i
      if (@@http_ports.include?(http_port)) then
        # Port already used, error.
        raise UIError.new("UI (http) port #{http_port} already in use.")
      end
      @http_port = http_port
      @@http_ports << @http_port
      # The program object.
      @program = program(:ruby, @name.to_sym) {}
      # Create the running function.
      Kernel.define_method(@name.to_sym) { self.run }
      # Initialize the list of board elements to empty.
      @elements = []
      # And the corresponding simulator ports to empty.
      @hruby_ports = []
      @hruby_in_ports = []
      # And build the board.
      # Create the namespace for the program.
      @namespace = Namespace.new(self)
      # Build the program object.
      High.space_push(@namespace)
      High.top_user.instance_eval(&ruby_block)
      High.space_pop
    end

    # Adds new activation ports.
    def actport(*evs)
      @program.actport(*evs)
    end

    # Add a new slide switch element attached to HDLRuby port +port+.
    def sw(port = {})
      if !port.is_a?(Hash) or port.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{port}")
      end
      @elements << SW.new(@elements.size,port.first[1].type.width)
      # Create and add the program port.
      @program.inport(port)
      @hruby_in_ports << port
      @hruby_ports << port
    end

    # Add a new button element attached to HDLRuby port +port+.
    def bt(n, port = {})
      if !port.is_a?(Hash) or port.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{port}")
      end
      @elements << BT.new(@elements.size,port.first[1].type.width)
      # Create and add the program port.
      @program.inport(port)
      @hruby_in_ports << port
      @hruby_ports << port
    end

    # Add a new LED element attached to HDLRuby port +port+.
    def led(port = {})
      if !port.is_a?(Hash) or port.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{port}")
      end
      @elements << LED.new(@elements.size,n.to_i)
      # Create and add the program port.
      @program.inport(port)
      @hruby_in_ports << port
      @hruby_ports << port
    end

    # Add a new digit element of +n+ columns attached to HDLRuby port +port+.
    def digit(n, port = {})
      if !port.is_a?(Hash) or port.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{port}")
      end
      @elements << DIGIT.new(@elements.size,n.to_i)
      # Create and add the program port.
      @program.outport(port)
      @hruby_ports << port
    end

    # Add a new ASCII element of +n+ columns attached to HDLRuby port +port+.
    def ascii(n, port = {})
      if !port.is_a?(Hash) or port.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{port}")
      end
      @elements << ASCII.new(@elements.size,n.to_i)
      # Create and add the program port.
      @program.outport(port)
      @hruby_ports << port
    end

    # Add a new bitmap element of width +w+ and height +h+ attached to HDLRuby
    # port +port+.
    def bitmap(w,h, port = {})
      if !port.is_a?(Hash) or port.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{port}")
      end
      @elements << BITMAP.new(id: @elements.size, width: w.to_i, height: h.to_i)
      # Create and add the program port.
      @program.outport(port)
      @hruby_ports << port
    end

    # Add a new scope element of width +w+, height +h+, range +rng+ and rate +rt+
    # attached to HDLRuby port +port+.
    def scope(w,h,rng,rt, port = {})
      if !port.is_a?(Hash) or port.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{port}")
      end
      @elements << SCOPE.new(id: @elements.size, 
                             width: w.to_i, height: h.to_i,
                             range: rng.first.to_i..rng.last.to_i,
                             rate: rt.to_i)
      # Create and add the program port.
      @program.outport(port)
      @hruby_ports << port
    end

    # Update port number +id+ with value +val+.
    def update_port(id,val)
      port = hruby_ports[id]
      RubyHDL.send(port,val)
    end

    # Generate a response to a request to the server.
    def make_response(request)
      if (request.empty?) then
        # First or re-connection, generate the UI.
        return UI_header + '\n' + @elements.map do |elem|
          "add_element('#{elem}');"
        end.join("\n") + "\n" + UI_footer
      else
        # This should be an AJAX request, process it.
        commands = request.split(";")
        commands.each do |command|
          id, val = command.split(":").map {|t| t.to_i}
          self.update_port(id,val)
        end
        # And generate the response: an update of each output port.
        return @hruby_in_ports.with_index.map do |p,i|
          "#{i}:#{RubyHDL.send(p)}"
        end.join(";")
      end
    end

    # Start the ui.
    def run
      # At first the u is not running.
      @connected = false
      # Create the ui thread.
      @thread = Thread.new do
        while session = @server.accept
          # A request came, process it.
          request = session.gets
          verb,path,protocol  = request.split(' ')
          if protocol === "HTTP/1.1"
            # The request is valid, generate the response.
            session.print self.make_response(path[1..-1])
            # And tell the ui has been connected.
            @connected = true
          else
            session.print 'Connection Refuse'
          end

          session.close
        end
      end
      # Wait for a first connection.
      sleep(0.1) while(!@connected)
    end
  end


  # Create a new board named +name+ accessible on HTTP port +http_port+
  # and whose content is describe in +block+.
  def board(name, http_port = 8000, &block)
    return Board.new(name,http_port,&block)
  end

end
