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
    @world.enemies << Enemy.new(@player)
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

class King < Chingu::GameObject
  has_trait :bounding_circle
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/king.png'])
    self.x, self.y = Gamejam.center
    self.factor = 30.0 / 2310
  end
end

class Crown < Chingu::GameObject
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/crown.png'])
    self.x, self.y = Gamejam.center
  end
end

class Enemy < Chingu::GameObject
  has_traits :velocity
  attr_accessor :player

  def initialize(player, options={})
    super options.merge(:image => Gosu::Image['assets/triangle.png'])
    self.x, self.y = 200, 200
    self.player = player
  end

  def draw
  end
end

Gamejam.new.show