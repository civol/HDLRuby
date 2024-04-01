require 'socket'

require 'rubyHDL'

# PCB Colors RGB: 42 100 36, 34 83 20, 106 155 108, 


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
    SW = Struct.new(:id, :size, :hwrite) do
      def to_html
        return "<div class=\"swset\" id=\"#{self.id}\" data-value=\"0\">\\n" + 
          '<span class="name">' + self.hwrite.to_s.chop + '</span>' +
          '<span>&nbsp;&nbsp;</span>' + 
           self.size.times.map do |i| 
             '<label class="sw"><input type="checkbox" data-bit="' + 
                     (self.size-i-1).to_s + '" ' +
                     'onchange="sw_change(this)">' +
             '<span class="slider"></span></label>\n'
           end.join + "</div>\\n"
      end
    end

    ## Class describing a row of buttons.
    BT = Struct.new(:id, :size, :hwrite) do
      def to_html
        return "<div class=\"btset\" id=\"#{self.id}\" data-value=\"0\">\\n" + 
          '<span class="name">' + self.hwrite.to_s.chop + '</span>' +
          '<span>&nbsp;&nbsp;</span>' + 
           self.size.times.map do |i| 
             '<button class="bt" data-bit="' +
                     (self.size-i-1).to_s + '" ' +
                     'onmousedown="bt_click(this)" onmouseup="bt_release(this)" onmouseleave="bt_release(this)"><i class="bt_off"></i></button>\n'
           end.join + "</div>\\n"
      end
    end

    ## Class describing a row of LEDs.
    LED = Struct.new(:id, :size, :hread) do
      def to_html
        return "<div class=\"ledset\" id=\"#{self.id}\" data-value=\"0\">\\n" +
          '<span class="name">' + self.hread.to_s + '</span>' +
          '<span>&nbsp;&nbsp;</span>' + 
          self.size.times.map do |i|
            '<i class="led" class="led_off"></i>\n'
          end.join + "</div>\\n"
      end
    end

    ## Class describing a digit display.
    DIGIT = Struct.new(:id, :size, :hread) do
      def to_html
        return '<div class="digitset" id=' + self.id.to_s +
              ' data-width="' + self.size.to_s + '" data-value="0" >' +
            '<span class="name">' + self.hread.to_s + '</span>' +
            '<span>&nbsp;&nbsp;</span>' + 
            '<span class="matrix">' + "&nbsp;"*self.size + '</span>' +
          "</div>\\n" 
      end
    end

    ## Class describing an hexadecimal display.
    HEXA = Struct.new(:id, :size, :hread) do
      def to_html
        return "<div class=\"hexaset\" id=\"#{self.id}\" " +
          "data-width=\"#{self.size}\" data-value=\"0\">" +
          '<span class="name">' + self.hread.to_s + '</span>' +
          '<span>&nbsp;&nbsp;</span>' + 
          "<span class=\"matrix\">#{"0"*self.size}</span>" + "</div>\\n" 
      end
    end

    ## Class describing an oscilloscope.
    SCOPE  = Struct.new(:id, :min, :max, :hread) do
      def to_html
        # Prepare the min, max and blank strings.
        min = self.min.to_s
        max = self.max.to_s
        blank = (min.size > max.size) ? min : max;
        # Generate the html.
        return '<div>' +
            '<div class="hdiv"><div class="r-blank">' + blank + '</div>' + # just for adjusting the position with the scope.
              '<div class="scopetitle">' +self.hread.to_s + '</div>\\n' + 
            "</div>\\n" +
            '<div class="scopepane">' +
              '<div class="hdiv">\\n' +
                '<div class="y-range">' + 
                  '<div class="u-value">' + max + '</div>' +
                  '<div class="d-value">' + min + '</div></div>' +
                '<div class="scope" id=' + self.id.to_s +
                  ' data-min="' + min + '" data-max="' + max + '"' + 
                  ' data-pos="0" data-previous="0" data-value="0">' +
                  '<canvas class="screen"></canvas>' +
                "</div>\\n" +
              "</div>\\n" +
              '<div class="hdiv"><div class="r-blank">' + blank + '</div>' + # just for adjusting the position with the scope.
                '<div class="x-range">' + 
                  '<div class="l-value">' + "&nbsp;0&nbsp;" + '</div>' +
                  '<div class="r-value">' + "100" + '</div></div>' +
                "</div>\\n" +
              "</div>\\n" +
            "</div>\\n" +
          "</div>\\n"
      end
    end


    ## Class describing an ascii display.
    ASCII = Struct.new(:id, :size, :hread)

    ## Class describing a bitmap display with keyboard input supported
    BITMAP = Struct.new(:id, :width, :height, :hread)

    ## Class describing a new panel row.
    PROW = Struct.new(:id) do
      def to_html
        return '<div class="prow" id="' + self.id.to_s + '"></div>';
      end
    end

    ## The base HTML/Javascript/Ajax code of the FPGA UI: 
    # header
    UI_header = <<-HTMLHEADER
HTTP/1.1 200
Content-Type: text/html

<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" name="viewport" content="width=device-width, initial-scale=1">
<style>

  html {
    background-color: #2a6424;
  }

  #header {
    width:  100%;
    /* border: solid 2px white; */
    text-align: center;
  }

  .panel {
    width:  100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-content: flex-start;
    gap: 20px;
  }

  .prow {
    width: 100%;
    display: flex;
    flex-direction: row;
    justify-content: center;
    gap: 15px;
  }

  .title {
    font-size: 36px;
    color: #d0d0d0;
    /* color: #2a6424; */
    /* color: white; */
    /* text-shadow: -1px -1px 1px white, 1px 1px 1px #101010; */
    text-shadow: -1px -1px 1px #63c359, 1px 1px 1px #153212;
    background-color: #265a20;
    box-shadow: -1px -1px 1px #153212, 1px 1px 1px #63c359;
    -moz-box-shadow: -1px -1px 1px #153212, 1px 1px 1px #63c359;
    -webkit-shadow: -1px -1px 1px #153212, 1px 1px 1px #63c359;
    padding: 4px;
    padding-left: 16px;
    padding-right: 16px;
    display: inline-block;
  }

  .name {
    font-size: 20px;
    font-family: "Lucida Console", "Courier New", monospace;
    color: white;
    background-color: #265a20;
    box-shadow: -1px -1px 1px #153212, 1px 1px 1px #63c359;
    -moz-box-shadow: -1px -1px 1px #153212, 1px 1px 1px #63c359;
    -webkit-shadow: -1px -1px 1px #153212, 1px 1px 1px #63c359;
    padding-left:  8px;
    padding-right: 8px;
    /* display: table-cell; 
    vertical-align: middle; */
    height: 28px;
    line-height: 28px;
  }

  .vl {
    /* border-left: 10px solid #2a6424; */
    color: #2a6424;
    box-shadow: -1px -1px 1px #63c359, 1px 1px 1px #153212;
    -moz-box-shadow: -1px -1px 1px #63c359, 1px 1px 1px #153212;
    -webkit-shadow: -1px -1px 1px #63c359, 1px 1px 1px #153212;
    width: 10px;
  }

  .hdiv {
    display: flex;
    flex-direction: row;
    align-item: stretch;
  }

  .vdiv {
    display: flex;
    flex-direction: column;
    justify-content: stretch;
  }

  .swset {
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    margin-left:  8px;
    margin-right: 8px;
    height: 40px;
  }

  .btset {
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    margin-left:  8px;
    margin-right: 8px;
    height: 40px;
  }

  .ledset {
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    margin-left:  8px;
    margin-right: 8px;
    height: 40px;
  }

  .digitset {
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    margin-left:  8px;
    margin-right: 8px;
    height: 40px;
  }

  .hexaset {
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    margin-left:  8px;
    margin-right: 8px;
    height: 40px;
  }

  .scopetitle {
    font-size: 20px;
    font-family: "Lucida Console", "Courier New", monospace;
    color: white;
    background-color: #265a20;
    box-shadow: -1px -1px 1px #153212, 1px 1px 1px #63c359;
    -moz-box-shadow: -1px -1px 1px #153212, 1px 1px 1px #63c359;
    -webkit-shadow: -1px -1px 1px #153212, 1px 1px 1px #63c359;
    display: inline-block;
    width:  30vw;
    height: 28px;
    line-height: 28px;
    margin-right: auto;
    margin-bottom: 4px;
    text-align:center;
  }

  .scopepane {
    background-color: #ccc;
    border: solid 2px #505050;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    padding: 10px;
    width: max-content;
    margin-left: auto;
    margin-right: auto;
  }

  .y-range {
    margin-left:  auto;
    /* border: solid 2px white; */
    display: flex;
    flex-direction: column;
  }

  .x-range {
    width:  30vw;
    /* border: solid 2px white; */
    display: flex;
    flex-direction: row;
    margin-right: auto;
    margin-left: 4px;
    margin-top: 4px;
  }

  .u-value {
    font-size: 16px;
    font-family: "Lucida Console", "Courier New", monospace;
    font-weight: bold;
    color: black;
    background-color: #ddd;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    padding-left:  8px;
    padding-right: 8px;
    text-align:center;
  }

  .d-value {
    font-size: 16px;
    font-family: "Lucida Console", "Courier New", monospace;
    font-weight: bold;
    color: black;
    background-color: #ddd;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    padding-left:  8px;
    padding-right: 8px;
    margin-top: auto;
    text-align:center;
  }

  .l-value {
    font-size: 16px;
    font-family: "Lucida Console", "Courier New", monospace;
    font-weight: bold;
    color: black;
    background-color: #ddd;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    padding-left:  8px;
    padding-right: 8px;
    height: fit-content;
  }

  .r-value {
    font-size: 16px;
    font-family: "Lucida Console", "Courier New", monospace;
    font-weight: bold;
    color: black;
    background-color: #ddd;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    padding-left:  8px;
    padding-right: 8px;
    margin-left: auto;
    height: fit-content;
  }

  .r-blank {
    font-size: 20px;
    color: rgba(0,0,0,0);
    border: solid 1px rgba(0,0,0,0);
    padding-left:  8px;
    padding-right: 8px;
    margin-left: auto;
    height: fit-content;
  }

  .scope {
    width:  30vw;
    height: 30vw;
    margin-right: auto; 
    border: solid 2px #505050;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
  }


  .screen {
    object-fit:contain;
    color: yellow;
    background-color: black;
    /* border: solid 2px #505050;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010; */
  }

  .sw {
    position: relative;
    display: inline-block;
    width: 24px;
    height: 40px;
    margin: 2px;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
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
    -webkit-transition: .2s;
    transition: .2s;
    border: solid 2px #505050;  
  }
  
  .slider:before {
    position: absolute;
    content: "";
    height: 16px;
    width: 16px;
    left: 2px;
    bottom: 2px;
    background-color: black;
    -webkit-transition: .2s;
    transition: .2s;
  }
  
  input:checked + .slider {
    background-color: yellow;
  }
  
  input:checked + .slider:before {
    -webkit-transform: translateY(-16px);
    -ms-transform: translateY(-16px);
    transform: translateY(-16px);
  }

  .matrix {
    font-size: 26px;
    font-family: "Lucida Console", "Courier New", monospace;
    color: yellow;
    background-color: black;
    border: solid 2px #505050;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
  }

  .bt {
    background-color: #ccc;
    border: solid 2px #505050;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
  }

  .bt:hover {
    background-color: #aaa;
  }

  .bt_off { 
    height: 20px;  
    width: 20px; 
    border: solid 1px #505050;
    border-radius: 50%;
    background: linear-gradient(to bottom right, #A0A0A0, black 60%);
    display: inline-block;
    margin-top: 1px;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
  }

  .bt_on {
    height: 20px;
    width: 20px;
    border: solid 1px #505050;
    border-radius: 50%;
    background: linear-gradient(to top left, #A0A0A0, black 80%);
    display: inline-block;
    margin-top: 3px;
    margin-bottom: -2px;
    box-shadow: -1px -1px 1px #101010, 1px 1px 1px white;
    -moz-box-shadow: -1px -1px 1px #101010, 1px 1px 1px white;
    -webkit-shadow: -1px -1px 1px #101010, 1px 1px 1px white;
  }

  .led_off { 
    height: 20px;  
    width: 20px;
    border: solid 2px #505050;
    border-radius: 50%;  
    background: radial-gradient(circle at 30% 30%, red 20%, #8B0000);
    display: inline-block;
    margin: 2px;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
  }

  .led_on { 
    height: 20px;  
    width: 20px; 
    border: solid 2px #505050;
    border-radius: 50%;  
    background: radial-gradient(circle, yellow 15%, orange 50%, red);
    display: inline-block;
    margin: 2px;
    box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -moz-box-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
    -webkit-shadow: -1px -1px 1px white, 1px 1px 1px #101010;
  }

</style>
</head>

<body>

<div id="header">
  <div id="cartouche" class="title">
  Name of the FPGA board
  </div>
</div>
<br>

<div id="panel" class="panel"><div class="prow"></div></div>

<script>
  // Access to the components of the UI.
  const cartouche = document.getElementById("cartouche");
  const panel     = document.getElementById("panel");

  // The input and output elements' ids.
  const input_ids = [];
  const output_ids = [];

  // The control functions.

  // Set the cartouche of the board.
  function set_cartouche(txt) {
    cartouche.innerHTML = txt;
  }

  // Add an element.
  function add_element(txt) {
    if (txt.includes('prow')) {
      // New panel row.
      panel.innerHTML += txt;
      return;
    }
    const prow = panel.lastElementChild;
    prow.innerHTML += txt;
    const element = prow.lastElementChild;
    // Depending of the kind of element.
    if (element.classList.contains('swset') ||
      element.classList.contains('btset')) {
      // Input element.
      input_ids.push(element.id);
    } else {
      // Output element.
      output_ids.push(element.id);
    }
  }

  // Set the size of a canvas.
  function setCanvasSize(canvas) {
    // Get the DPR and size of the canvas
    const dpr = window.devicePixelRatio;
    const parentRect = canvas.parentElement.getBoundingClientRect();
    // console.log("parentRect=[" + parentRect.width + "," + parentRect.height + "]");

    // Set the "actual" size of the canvas
    canvas.width =  parentRect.width * dpr;
    canvas.height = parentRect.height * dpr;

    // Scale the context to ensure correct drawing operations
    canvas.getContext("2d").scale(dpr, dpr);

    // Set the "drawn" size of the canvas
    canvas.style.width =  `${parentRect.width}px`;
    canvas.style.height = `${parentRect.height}px`;
  }

  // Handler of sw change.
  function sw_change(sw) {
    // Get the set holding sw.
    const swset = sw.parentElement.parentElement;
    const bit = sw.dataset.bit;
    if (sw.checked) { 
      swset.dataset.value = swset.dataset.value | (1 << bit);
    }
    else {
      swset.dataset.value = swset.dataset.value & ~(1 << bit);
    }
    // console.log("sw value=" + swset.dataset.value);
  }

  // Set the aspect of a button to clicked.
  function bt_on(bt) {
    bt.innerHTML = '<i class="bt_on"></i>';
  }

  // Set the aspect of a button to not clicked.
  function bt_off(bt) {
    bt.innerHTML = '<i class="bt_off"></i>';
  }

  // Handler of button clicked.
  function bt_click(bt) {
    // Change the aspect of the button.
    bt_on(bt);
    // Get the set holding bt.
    const btset = bt.parentElement;
    const bit = bt.dataset.bit;
    // Update its value.
    btset.dataset.value = btset.dataset.value | (1 << bit);
  }

  // Handler of button released.
  function bt_release(bt) {
    // Change the aspect of the button.
    bt_off(bt);
    // Get the set holding bt.
    const btset = bt.parentElement;
    const bit = bt.dataset.bit;
    // Update its value.
    btset.dataset.value = btset.dataset.value & ~(1 << bit);
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
    const leds = ledset.getElementsByTagName("i");
    const num = leds.length;
    // Set each led of the set.
    for(let i=0; i < num; ++i) {
      const val = (value >> i) & 1;
      if (val == 1) { led_on(leds[num-i-1]); }
      else          { led_off(leds[num-i-1]); }
    }
  }

  // Update a digit set.
  function digitset_update(digitset,value) {
    // Update the digiset value.
    digitset.dataset.value = value;
    // Unsigned case.
    const num = digitset.dataset.width;
    digitset.lastElementChild.innerHTML = String(value).padStart(num,"\u00A0");
  }

  // Update a hexadecimal set.
  function hexaset_update(hexaset,value) {
    // Update the digiset value.
    hexaset.dataset.value = value;
    // Update its display.
    const num = hexaset.dataset.width;
    hexaset.lastElementChild.innerHTML = Number(value).toString(16).padStart(num,'0');
  }

  // Update an oscilloscope.
  function scope_update(scope,value) {
    // Get the canvas.
    const canvas = scope.lastElementChild;
    // Shall we set up its size?
    let first = 0;
    if (scope.dataset.configured != 1) {
      // First time, so yes.
      setCanvasSize(canvas);
      scope.dataset.configured = 1;
      first = 1;
    }
    // Its size.
    const { width, height } = canvas.getBoundingClientRect();
    // Its context.
    const cxt = canvas.getContext("2d");
    // Get the properties of the scope.
    const min = Number(scope.dataset.min);
    const max = Number(scope.dataset.max);
    const pos = Number(scope.dataset.pos);
    const previous = Number(scope.dataset.previous);
    // console.log("min=" + min + " max=" + max);
    const toPx = function(val) { // Convert a percentage to x position.
      return (val*width)/100;
    }
    const toPy = function(val) { // Convert an input value to y position.
      return height - ((val-min) * height) / (max-min);
    }
    // Shall we restart the drawing?
    if (pos >= 100 || first == 1) {
      // Yes, clears the canvas.
      cxt.clearRect(0, 0, width, height);
      /* Draw the grid. */
      cxt.strokeStyle = "#b3b3b3";
      cxt.setLineDash([2,1]);
      cxt.lineWidth = 1;
      cxt.beginPath();
      for(let i=0; i<100; i += 10) {
         cxt.moveTo(toPx(0),  toPy((i*(max-min))/100+min));
         cxt.lineTo(toPx(100),toPy((i*(max-min))/100+min));
         cxt.moveTo(toPx(i),  toPy(min));
         cxt.lineTo(toPx(i),  toPy(max));
      }
      cxt.stroke();
      cxt.setLineDash([]);
      cxt.beginPath();
      for(let i=0; i<100; i+= 2) {
         cxt.moveTo(toPx(50-0.7), toPy((i*(max-min))/100+min));
         cxt.lineTo(toPx(50+0.7), toPy((i*(max-min))/100+min));
         cxt.moveTo(toPx(i),  toPy((max-min)/2 + min - 0.7*(max-min)/100));
         cxt.lineTo(toPx(i),  toPy((max-min)/2 + min + 0.7*(max-min)/100));
      }
      cxt.stroke();
      // Set the pen color for drawing the signal.
      cxt.strokeStyle = "yellow";
      cxt.lineWidth = 2;
      // Draw a single pixel.
      cxt.beginPath();
      cxt.moveTo(toPx(0), toPy(value));
      cxt.lineTo(toPx(0), toPy(value));
      cxt.stroke();
      /* Update the values. */
      scope.dataset.previous = value;
      scope.dataset.pos = 0;
    } else {
      // Go on, draw a line to the new position.
      // Set the pen color for drawing the signal.
      cxt.strokeStyle = "yellow";
      cxt.lineWidth = 2;
      // Draw a line to the new position.
      cxt.beginPath();
      cxt.moveTo(toPx(pos),   toPy(previous));
      cxt.lineTo(toPx(pos+1), toPy(value)); 
      cxt.stroke();
      /* Update the values. */
      scope.dataset.previous = value;
      scope.dataset.pos = pos + 1;
    }
  }

  // Update a general display element.
  function element_update(element,value) {
    if(element.classList.contains('ledset'))  { ledset_update(element,value); }
    if(element.classList.contains('digitset')){ digitset_update(element,value); }
    if(element.classList.contains('signedset')){signedset_update(element,value);}
    if(element.classList.contains('hexaset')) { hexaset_update(element,value); }
    if(element.classList.contains('scope'))   { scope_update(element,value); }
  }


  // Synchronize with the HDLRuby simulator.
  function hruby_sync() {
    let xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
      // console.log("response=" + this.responseText);
      if (this.readyState == 4 && this.status == 200) {
        if (/[0-9]+:[0-9]/.test(this.responseText)) {
          // There is a real response.
          // Update the interface with the answer.
          const commands = this.responseText.split(';');
          for(command of commands) {
             const toks = command.split(':');
             element_update(document.getElementById(toks[0]),toks[1]);
          }
        }
      }
    };
    // Builds the action from the state of the input elements.
    act = '';
    for(id of input_ids) {
      act += id + ':' + document.getElementById(id).dataset.value + ';';
    }
    // console.log("act=" + act);
    xhttp.open("GET", act, true);
    xhttp.overrideMimeType("text/plain; charset=x-user-defined");
    xhttp.send();
  }

  // First call of synchronisation.
  hruby_sync();

  // Then periodic synchronize.
  setInterval(function() { hruby_sync(); }, 100);

</script>

HTMLHEADER

    # Footer
    UI_footer = <<-HTMLFOOTER
</body>
</html>
HTMLFOOTER

UI_response = <<-HTMLRESPONSE
HTTP/1.1 200
Content-Type: text/plain

HTMLRESPONSE


    # The already used ports.
    @@http_ports = []


    # Create a new board named +name+ accessible on HTTP port +http_port+
    # and whose content is describe in +hdlruby_block+.
    def initialize(name, http_port = 8000, &hdlruby_block)
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
      # Create the server
      @server = TCPServer.new(@http_port)
      # Create the running function.
      this = self
      Kernel.define_method(@name.to_sym) { this.run }
      # Initialize the list of board elements to empty.
      @elements = []
      @out_elements = []
      # And build the board.
      # Create the namespace for the program.
      @namespace = Namespace.new(self)
      # Build the program object.
      High.space_push(@namespace)
      pr = nil
      High.top_user.instance_eval { pr = program(:ruby, @name.to_sym) {} }
      @program = pr
      # Fill it.
      High.top_user.instance_eval(&hdlruby_block)
      High.space_pop
    end

    # Adds new activation ports.
    def actport(*evs)
      @program.actport(*evs)
    end

    # Add a new slide switch element attached to HDLRuby port +hport+.
    def sw(hport)
      if !hport.is_a?(Hash) or hport.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{hport}")
      end
      # Create the HDLRuby program port.
      @program.outport(hport)
      # Create the ui component.
      hport = hport.first
      @elements << SW.new(@elements.size,hport[1].type.width,:"#{hport[0]}=")
    end

    # Add a new button element attached to HDLRuby port +hport+.
    def bt(hport)
      if !hport.is_a?(Hash) or hport.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{hport}")
      end
      # Create the HDLRuby program port.
      @program.outport(hport)
      hport = hport.first
      # Create the ui component.
      @elements << BT.new(@elements.size,hport[1].type.width,:"#{hport[0]}=")
    end

    # Add a new LED element attached to HDLRuby port +hport+.
    def led(hport)
      if !hport.is_a?(Hash) or hport.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{hport}")
      end
      # Create the HDLRuby program port.
      @program.inport(hport)
      hport = hport.first
      # Createthe ui component.
      @elements << LED.new(@elements.size,hport[1].type.width,hport[0])
      @out_elements << @elements[-1]
    end

    # Add a new digit element attached to HDLRuby port +hport+.
    def digit(hport)
      if !hport.is_a?(Hash) or hport.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{hport}")
      end
      # Create the HDLRuby program port.
      @program.inport(hport)
      hport = hport.first
      sign = hport[1].type.signed?
      # Createthe ui component.
      @elements << DIGIT.new(@elements.size, 
              Math.log10(2**hport[1].type.width - 1).to_i + (sign ? 2 : 1),
              hport[0])
      @out_elements << @elements[-1]
    end

    # Add a new hexadecimal element attached to HDLRuby port +hport+.
    def hexa(hport)
      if !hport.is_a?(Hash) or hport.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{hport}")
      end
      # Create the HDLRuby program port.
      @program.inport(hport)
      hport = hport.first
      # Createthe ui component.
      @elements << HEXA.new(@elements.size,
                            (hport[1].type.width-1)/4+1, hport[0])
      @out_elements << @elements[-1]
    end

    # Add a new scope element attached to HDLRuby port +hport+.
    def scope(hport)
      if !hport.is_a?(Hash) or hport.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{hport}")
      end
      # Create the HDLRuby program port.
      @program.inport(hport)
      hport = hport.first
      width = hport[1].type.width
      if hport[1].type.signed? then
        min = -2**(width-1)
        max = 2**(width-1) - 1
      else
        min = 0
        max = 2**width - 1
      end
      # Createthe ui component.
      @elements << SCOPE.new(@elements.size, min, max, hport[0])
      @out_elements << @elements[-1]
    end

    # Add a new ASCII element of +n+ columns attached to HDLRuby port +hport+.
    def ascii(n, hport)
      if !hport.is_a?(Hash) or hport.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{hport}")
      end
      # Create the HDLRuby program port.
      @program.inport(hport)
      hport = hport.first
      # Createthe ui component.
      @elements << ASCII.new(@elements.size,hport[1].type.width,hport[0])
      @out_elements << @elements[-1]
    end

    # Add a new bitmap element of width +w+ and height +h+ attached to HDLRuby
    # port +hport+.
    def bitmap(w,h, hport)
      if !hport.is_a?(Hash) or hport.size != 1 then
        raise UIError.new("Malformed HDLRuby port declaration: #{hport}")
      end
      # Create the HDLRuby program port.
      @program.inport(hport)
      hport = hport.first
      # Createthe ui component.
      @elements << BITMAP.new(@elements.size,w.to_i,h.to_i,hport[0])
      @out_elements << @elements[-1]
    end

    # Add a new panel row.
    def row()
      # Createthe ui component.
      @elements << PROW.new(@elements.size)
    end



    # Update port number +id+ with value +val+.
    def update_port(id,val)
      RubyHDL.send(@elements[id].hwrite,val)
    end

    # Generate a response to a request to the server.
    def make_response(request)
      # puts "request=#{request}"
      if (request.empty?) then
        # First or re-connection, generate the UI.
        return UI_header + "\n<script>\n" + 
          "set_cartouche('#{@name}');\n" +
          @elements.map do |elem|
            "add_element('#{elem.to_html}');"
          end.join("\n") + 
          "\n</script>\n" + UI_footer
      else
        # This should be an AJAX request, process it.
        commands = request.split(";")
        commands.each do |command|
          id, val = command.split(":").map {|t| t.to_i}
          self.update_port(id,val)
        end
        # And generate the response: an update of each board output element.
        return UI_response + @out_elements.each.map do |e|
          # puts "resp=" + "#{e.id}:#{RubyHDL.send(e.hread)}"
          "#{e.id}:#{RubyHDL.send(e.hread)}"
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
          # puts "verb=#{verb} path=#{path} protocol=#{protocol}"
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
