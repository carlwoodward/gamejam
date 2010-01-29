require 'gosu'
require 'chingu'
require 'angle_velocity'

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
    @player = King.create
    @world.input = world_input
    5.times { @world.enemies << Enemy.create(@world, @player) }
    self.input = {:escape => :close}
  end
  
  def world_input
    # TODO Repeating code.
    {:holding_right => :start_rotation_right, :released_right => :finish_rotation_right,
      :holding_left => :start_rotation_left, :released_left => :finish_rotation_left}
  end
end

class World < Chingu::GameObject
  has_traits :angle_velocity, :timer
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
      anchor_x, anchor_y = 100, 100
      vx = child.x - anchor_x.to_f
      vy = child.y - anchor_y.to_f
      translated_x = vy * Math.cos(theta) - vx * Math.sin(theta)
      translated_y = -vx * Math.cos(theta) - vy * Math.sin(theta)
      
      child.x = translated_x + anchor_x
      child.y = translated_y + anchor_y
      # child.angle += theta
      # speed = 1
      # child.velocity_x = speed.to_f * Math.cos(child.angle.gosu_to_radians)
      # child.velocity_y = speed.to_f * Math.sin(child.angle.gosu_to_radians)
    end
  end
  
  %w(left right).each do |dir|
    define_method "start_rotation_#{dir}" do
      stop_timers
      self.acceleration_angle = dir == 'right' ? 0.075 : -0.075
    end
  
    define_method "finish_rotation_#{dir}" do
      during(10) { self.acceleration_angle *= 0.95; self.velocity_angle *= 0.95 }.then { self.acceleration_angle = 0; self.velocity_angle = 0 }
    end
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

class Enemy < Chingu::GameObject
  has_traits :velocity, :bounding_box, :collision_detection
  attr_accessor :player, :world
    
  def initialize(world, player, options={})
    super options.merge(:image => Gosu::Image['assets/triangle.png'])
    self.x, self.y = rand(Gamejam.width), rand(Gamejam.height)
    self.player = player
    self.world = world
    find_king
  end
  
  def update
    (world.enemies - [self]).each do |enemy|
      if collides? enemy
        self.alpha = 128
        enemy.alpha = 128
      end
    end
  end
  
  def find_king
    self.angle = Gosu.angle(x, y, player.x, player.y)
    angle_in_rads = angle.gosu_to_radians
    speed = 1
    self.velocity_x, self.velocity_y = speed.to_f * Math.cos(angle_in_rads), speed.to_f * Math.sin(angle_in_rads)
  end
end

Gamejam.new.show