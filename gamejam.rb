require 'gosu'
require 'chingu'
require 'angular_momentum'

class Gamejam < Chingu::Window
  class << self
    def width; 960; end
    def height; 640; end
    def center
      [width / 2, height / 2]
    end
  end

  def initialize
    super(self.class.width, self.class.height)
    @world = World.create
    @king = King.create
    @crown = Crown.create
    @world.input = world_input
    5.times { @world.enemies << Enemy.create(@world, @king) }
    self.input = {:escape => :close}
  end

  def world_input
    # TODO Repeating code.
    {:holding_right => :rotate_right, :released_right => :stop_rotating_right,
     :holding_left => :rotate_left,   :released_left => :stop_rotating_left}
  end
end

class World < Chingu::GameObject
  has_trait :angular_momentum, :max_angular_velocity => 8
  has_trait :timer
  attr_accessor :enemies
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/blue.png'])
    self.x, self.y = Gamejam.center
    self.enemies = []
  end

  def update
    enemies_follow_rotation
  end

  def enemies_follow_rotation
    enemies.each { |enemy| follow_rotation enemy }
  end

  def follow_rotation(child)
    if previous_angle != angle
      new_angle = (previous_angle - angle)
      theta = new_angle.gosu_to_radians

      vx = child.x - x.to_f
      vy = child.y - y.to_f
      translated_x = vy * Math.cos(theta) - vx * Math.sin(theta)
      translated_y = -vx * Math.cos(theta) - vy * Math.sin(theta)

      child.x = translated_x + x
      child.y = translated_y + y
      speed = 1
      child.velocity_x = speed.to_f * Math.cos(child.angle.gosu_to_radians)
      child.velocity_y = speed.to_f * Math.sin(child.angle.gosu_to_radians)
      child.angle += theta
    end
  end

  %w(left right).each do |dir|
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
  attr_accessor :king, :world

  def initialize(world, king, options={})
    super options.merge(:image => Gosu::Image['assets/triangle.png'])
    self.x, self.y = rand(Gamejam.width), rand(Gamejam.height)
    self.world, self.king = world, king
    direct_to_king!
  end

  def update
    (world.enemies - [self]).each do |enemy|
      if collides? enemy
        self.alpha = 128
        enemy.alpha = 128
      end
    end
  end

  def direct_to_king!
    self.angle = Gosu.angle(x, y, king.x, king.y)
    angle_in_rads = angle.gosu_to_radians
    speed = 1.0
    self.velocity_x, self.velocity_y = speed.to_f * Math.cos(angle_in_rads), speed.to_f * Math.sin(angle_in_rads)
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


Gamejam.new.show