require 'gosu'
require 'chingu'
require 'angular_momentum'

class Gamejam < Chingu::Window
  class << self
    def width; 600; end
    def height; 400; end
    def center
      [width / 2, height / 2]
    end
  end

  def initialize
    super(self.class.width, self.class.height)
    @world = World.create
    @king = King.create
    @crown = Crown.create
    5.times { @world.enemies << Enemy.create(@world, @king) }
    @pivot = Pivot.create(@world)
    self.input = {:escape => :close}
  end
end

class World < Chingu::GameObject

  has_trait :angular_momentum, :max_angular_velocity => 8
  has_trait :timer

  attr_accessor :enemies

  BACKGROUND_DIM = 2310

  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/blue.png'])
    self.x, self.y = Gamejam.center
    self.enemies = []
    self.input = {
      :mouse_left => :step_right,
      :holding_mouse_left => :rotate_right,
      :released_mouse_left => :stop_rotating_right,
      :mouse_right => :step_left,
      :holding_mouse_right => :rotate_left,
      :released_mouse_right => :stop_rotating_left
    }
  end

  def update
    # if previous_angle != angle
    #   enemies.each {|enemy| enemy.translate $world.mouse_x, $world.mouse_y, angle}
    # end
  end

  # def follow_rotation(child)
  #   if previous_angle != angle
  #     new_angle = (previous_angle - angle)
  #     theta = new_angle.gosu_to_radians
  #
  #     vx = child.x - x.to_f
  #     vy = child.y - y.to_f
  #     translated_x = vy * Math.cos(theta) - vx * Math.sin(theta)
  #     translated_y = -vx * Math.cos(theta) - vy * Math.sin(theta)
  #
  #     child.x = translated_x + x
  #     child.y = translated_y + y
  #     speed = 1
  #     child.velocity_x = speed.to_f * Math.cos(child.angle.gosu_to_radians)
  #     child.velocity_y = speed.to_f * Math.sin(child.angle.gosu_to_radians)
  #     child.angle += theta
  #   end
  # end

  %w(left right).each do |dir|

    define_method "step_#{dir}" do

      self.x = $window.mouse_x
      self.y = $window.mouse_y


      self.center_x = 2310 / ((BACKGROUND_DIM/center_x) - (Gamejam.width/2) + $window.mouse_x)
      self.center_y = 2310 / ((BACKGROUND_DIM/center_y) - (Gamejam.height/2) + $window.mouse_y)


      puts "#{BACKGROUND_DIM/center_x} - #{Gamejam.width/2} + #{$window.mouse_x} = #{center_x}"

      send("rotate_#{dir}".to_sym)
    end

    define_method "rotate_#{dir}" do
      stop_timers
      self.angular_acceleration = dir == 'right' ? 0.4 : -0.4
    end

    define_method "stop_rotating_#{dir}" do
      during(1500) {
        self.angular_acceleration *= 0.85
        self.angular_velocity *= 0.85
      }.then{stop_angular_momentum}
    end
  end
end

class Enemy < Chingu::GameObject

  has_traits :velocity, :bounding_box, :collision_detection

  attr_accessor :world, :speed

  def initialize(world, king, options={})
    super options.merge(:image => Gosu::Image['assets/triangle.png'])
    self.x, self.y = rand(Gamejam.width), rand(Gamejam.height)
    self.world, self.speed = world, 0.2
    point_at king
  end

  def update
    self.class.all.each do |enemy|
      # if enemy != self && collides? enemy
      #   self.alpha = 128
      #   enemy.alpha = 128
      # end
    end
  end

  def point_at(pt)
    self.angle = Gosu.angle(x, y, pt.x, pt.y)
    self.velocity_x, self.velocity_y = Gosu.offset_x(angle, speed), Gosu.offset_y(angle, speed)
  end
end

class Crown < Chingu::GameObject
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/crown.png'])
    self.x, self.y = Gamejam.center
  end
end

class King < Chingu::GameObject
  has_trait :bounding_circle
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/king.png'])
    self.x, self.y = Gamejam.center
    self.factor = 30.0 / 2310
  end
end

class Pivot < Chingu::GameObject
  def initialize(world, options={})
    super options.merge(:image => Gosu::Image['assets/pivot.png'])
  end

  def update
    self.x, self.y = $window.mouse_x, $window.mouse_y
  end
end


Gamejam.new.show