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
    @world.enemies << Enemy.new(@player)
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
  
  def draw
    super
    enemies.each do |enemy|
      dx = enemy.x.to_f
      dy = -enemy.y.to_f
      theta = angle.gosu_to_radians
      translated_x = dx * Math.cos(theta) - dy * Math.sin(theta) + x.to_f
      translated_y = dx * Math.sin(theta) + dy * Math.cos(theta) + y.to_f
      
      enemy.image.draw_rot(translated_x, translated_y, enemy.zorder, enemy.angle, enemy.center_x, enemy.center_y, enemy.factor_x, enemy.factor_y, enemy.color, enemy.mode) if enemy.visible
    end
  end
  
  def update
    # enemies.each do |enemy|
    #       translate_child_to_self(enemy)
    #     end
  end
  
  def translate_child_to_self(child)
    dx = x - child.x
    dy = y - child.y
    theta = previous_angle - angle
    child.x = dx * Math.cos(theta) - dy * Math.sin(theta)
    # p child.y = dx * Math.sin(theta) + dy * Math.cos(theta)
    # child.x += Gosu.offset_x(angle, x-child.x)
    # child.y += Gosu.offset_y(angle, y-child.y)
    # child.x += Gosu.offset_y(angle, y)
    # d = Gosu.distance(x, y, enemy.x, enemy.y)
    # enemy.x = Gosu.offset_x(angle_delta, d)
    # enemy.y = Gosu.offset_y(angle_delta, d)
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
  has_traits :velocity
  attr_accessor :player
    
  def initialize(player, options={})
    super options.merge(:image => Gosu::Image['assets/triangle.png'])
    self.x, self.y = 200, 200
    self.player = player
    find_king
  end
  
  def update
    find_king
  end
  
  def find_king
    self.angle = Gosu::angle self.x, self.y, player.x, player.y
    speed = 1
    self.velocity_x, self.velocity_y = speed.to_f * Math.cos(angle), speed.to_f * Math.sin(angle)
  end
end

Gamejam.new.show