module Graphics
  class Point
    attr_reader :x, :y
    def initialize(x,y)
      @x = x
      @y = y
    end

    def ==(other)
      (@x == other.x) and (@y == other.y)
    end

    def hash
      [@x , @y].hash
    end

    def self.topmost(first,second)
      if first.y < second.y then first else second end
    end

    def self.leftmost(first,second)
      if first.x < second.x then first else second end
    end

    def self.rightmost(first,second)
      if first.y > second.y then first else second end
    end

    def self.bottommost(first,second)
      if first.x > second.x then first else second end
    end

    def render_on(canvas)
      canvas.set_pixel @x, @y
    end

    alias_method :==, :eql?
  end

  module PointsPair
    attr_reader :first, :second

    def initialize(start,finish)
      if start.x == finish.x
        @first = Point.topmost start, finish
        @second = Point.bottommost start, finish
      else
        @first = Point.leftmost start, finish
        @second = Point.bottommost start, finish
      end
    end

    def hash
      [@first, @second].hash
    end

    def ==(other)
      (@first == other.first) and (@second == other.second)
    end

    alias_method :==, :eql?
  end

  class Line
    include PointsPair

    alias_method :from, :first
    alias_method :to, :second

    def rasterize_plot_x(delta_x,delta_y,x, y,max, offset_x, offset_y, &block)
        error = delta_x / 2.0
        while x != max
          error, x = error - delta_y, x+offset_x
          if error <= 0
            y, error = y + offset_y, error + delta_x
          end
          yield Point.new x,y
        end
    end

    def rasterize_plot_y(delta_x,delta_y,x, y,max, offset_x, offset_y, &block)
        error = delta_y / 2.0
        while y != max
          error, y = error - delta_x, y + offset_y
          if error <= 0
            x, error = x + offset_x, error + delta_y
          end
          yield Point.new x,y
        end
    end

    def rasterize(a, b,&block)
      delta_x, delta_y, x, y = (b.x - a.x).abs, (b.y - a.y).abs, a.x, a.y
      offset_x, offset_y = a.x > b.x ? -1 : 1 , a.y > b.y ? -1 : 1

      yield Point.new x,y

      if delta_x > delta_y
        rasterize_plot_x delta_x,delta_y,x,y, b.x, offset_x, offset_y, &block
      else
        rasterize_plot_y delta_x,delta_y,x,y, b.y, offset_x, offset_y, &block
      end
    end

    def render_on(canvas)
      if @first.x == @second.x
        min = [@first.y,@second.y].min
        max = [@first.y,@second.y].max
        (min .. max).each {|y| canvas.set_pixel @first.x, y}
      else
        rasterize(@first,@second) {|point| canvas.set_pixel point.x, point.y}
      end
    end
  end

  class Rectangle
    include PointsPair

    alias_method :left, :first
    alias_method :right, :second

    def top_left
      @top_left ||= Point.new @first.x, [@first.y, @second.y].min
    end

    def top_right
      @top_right ||= Point.new @second.x, [@first.y, @second.y].min
    end

    def bottom_left
      @bottom_left ||= Point.new @first.x, [@first.y, @second.y].max
    end

    def bottom_right
      @bottom_right ||= Point.new @second.x, [@first.y, @second.y].max
    end

    def render_on(canvas)
      (top_left.x .. top_right.x).each {|x| canvas.set_pixel x, top_left.y}
      (top_left.x .. top_right.x).each {|x| canvas.set_pixel x,bottom_left.y}
      (top_left.y .. bottom_left.y).each {|y| canvas.set_pixel top_left.x,y}
      (top_left.y .. bottom_left.y).each {|y| canvas.set_pixel top_right.x,y}
    end
  end

  class Canvas
    attr_reader :width, :height
    def initialize(width,height)
      @width = width
      @height = height
      @pane = Array.new(height) {Array.new width,false}
    end

    def draw(figure)
      figure.render_on self
    end

    def set_pixel(x, y)
      @pane[x][y] = true
    end

    def pixel_at?(x, y)
      @pane[x][y]
    end

    def render_as(renderer)
      renderer.render(self)
    end
  end

  module Renderers
    class Ascii
      def self.render(canvas)
        result = ""
        (0 .. canvas.height-1).each do |y|
          (0 .. canvas.width-1).each do |x|
            result = result + (print_character canvas, x, y)
          end
          result = result + "\n"
        end
        result
      end
      
      def self.print_character(canvas,x,y)
        if canvas.pixel_at? x, y then "@" else "-" end
      end

    end

    class Html
      def self.render(canvas)
        result = ""
        (0 .. canvas.height-1).each do |y|
          (0 .. canvas.width-1).each do |x|
            result = result + (print_character canvas, x, y)
          end
          result = result + "<br/>"
        end
        DATA.read.sub ">FINDME",result
      end

      def self.print_character(canvas,x,y)
        if canvas.pixel_at? x, y then "<b></b>" else "<i></i>" end
      end
    end
  end
end

module Graphics
  canvas = Canvas.new 30, 30

  # Door frame and window
  canvas.draw Rectangle.new(Point.new(3, 3), Point.new(18, 12))
  canvas.draw Rectangle.new(Point.new(1, 1), Point.new(20, 28))

  # Door knob
  canvas.draw Line.new(Point.new(4, 15), Point.new(7, 15))
  canvas.draw Point.new(4, 16)

  # Big "R"
  canvas.draw Line.new(Point.new(8, 5), Point.new(8, 10))
  canvas.draw Line.new(Point.new(9, 5), Point.new(12, 5))
  canvas.draw Line.new(Point.new(9, 7), Point.new(12, 7))
  canvas.draw Point.new(13, 6)
  canvas.draw Line.new(Point.new(12, 8), Point.new(13, 10))

  puts canvas.render_as(Renderers::Ascii)
end

__END__

<!DOCTYPE html>
  <html>
  <head>
    <title>Rendered Canvas</title>
    <style type="text/css">
      .canvas {
        font-size: 1px;
        line-height: 1px;
      }
      .canvas * {
        display: inline-block;
        width: 10px;
        height: 10px;
        border-radius: 5px;
      }
      .canvas i {
        background-color: #eee;
      }
      .canvas b {
        background-color: #333;
      }
    </style>
  </head>
  <body>
    <div class="canvas">
      >FINDME
    </div>
  </body>
  </html>