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
    @world.enemies << Enemy.create(@world, @king)
    @world.pivot = Pivot.create
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
  attr_accessor :enemies, :pivot
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
      anchor_x, anchor_y = pivot.x, pivot.y
      vx = child.x - anchor_x.to_f
      vy = child.y - anchor_y.to_f
      translated_x = vy * Math.cos(theta) - vx * Math.sin(theta)
      translated_y = -vx * Math.cos(theta) - vy * Math.sin(theta)
      
      child.x = translated_x + anchor_x
      child.y = translated_y + anchor_y
      child.angle -= new_angle
      child.velocity_x = child.default_speed.to_f * Math.cos(child.angle.gosu_to_radians)
      child.velocity_y = child.default_speed.to_f * Math.sin(child.angle.gosu_to_radians)
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
    self.x, self.y = 480, 100
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
    self.velocity_x, self.velocity_y = default_speed.to_f * Math.cos(angle_in_rads), default_speed.to_f * Math.sin(angle_in_rads)
  end
  
  def default_speed
    0.3
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
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/pivot.png'])
  end

  def update
    super
    self.x = $window.mouse_x
    self.y = $window.mouse_y
  end
end


Gamejam.new.show