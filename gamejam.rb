require 'gosu'
require 'chingu'
require 'angular_momentum'

class Array
  def random
    self[rand(length)]
  end
end

class Gamejam < Chingu::Window
  class << self
    def width; 960; end
    def height; 640; end
    def center
      [width / 2, height / 2]
    end
  end

  attr_accessor :king, :director, :world

  def initialize
    super(self.class.width, self.class.height)
    self.world = World.create
    self.king = King.create
    self.director = Director.create

    @crown = Crown.create
    @world.pivot = Pivot.create
    self.input = {:escape => :close}
  end
end

# class GameOver < Chingu::GameState
#   def update
#     PulsatingText.destroy_if { |text| text.size == 100}
#     PulsatingText.create("YOU DIED", :x => 400, :y => 200, :size => 100)
#     $window.enemy_waves.kill_all
#   end
# end

class World < Chingu::GameObject
  has_trait :angular_momentum, :max_angular_velocity => 8
  has_trait :timer
  attr_accessor :enemies, :pivot, :colour

  def self.colours
    @colours ||= [:red, :green, :blue]
  end

  def self.backgrounds
    @backgrounds ||= {
      :red => Gosu::Image['assets/red.png'],
      :green => Gosu::Image['assets/green.png'],
      :blue => Gosu::Image['assets/blue.png']
    }
  end

  def initialize
    super :image => change_colour!
    self.x, self.y = Gamejam.center
    self.input = {
      :mouse_left => :step_right,
      :holding_mouse_left => :rotate_right,
      :released_mouse_left => :stop_rotating_right,
      :mouse_right => :step_left,
      :holding_mouse_right => :rotate_left,
      :released_mouse_right => :stop_rotating_left
    }
    # TODO This should be in Director
    every(5000, :name => 'colour') { $window.world.change_colour! }
  end

  def update
    Enemy.all.select {|e| e.colour == colour}.
              each {|e| transform(e)} unless previous_angle == angle
  end

  def change_colour!
    self.colour = self.class.colours.random
    self.image = self.class.backgrounds[colour]
    # Enemy.all.each do |e|
    #   (e.color == color) ? e.show! : e.hide!
    # end
    image
  end

  def transform(child)
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
    child.velocity_x = child.speed.to_f * Math.cos(child.angle.gosu_to_radians)
    child.velocity_y = child.speed.to_f * Math.sin(child.angle.gosu_to_radians)
  end

  %w(left right).each do |dir|

    define_method "step_#{dir}" do
      self.x += $window.mouse_x - x
      self.y += $window.mouse_y - y

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

class Director < Chingu::BasicGameObject
  has_traits :timer
  def initialize
    super
    every(1000, :name => 'spawn') { spawn }
  end

  def spawn
    5.times  {|i| Enemy.create}
  end
end

class Enemy < Chingu::GameObject
  has_traits :velocity, :bounding_circle, :collision_detection, :timer
  attr_accessor :king, :colour

  def self.images
    @images ||= {
      :red => Gosu::Image["assets/triangle_red.png"],
      :green => Gosu::Image["assets/triangle_green.png"],
      :blue => Gosu::Image["assets/triangle_blue.png"]
    }
  end

  def initialize
    self.king, self.colour = $window.king, $window.world.colour
    super :image => self.class.images[colour]
    place and point_at king

    @death_animation = Chingu::Animation.new(:file => "assets/particle.png", :size => [32,32])
  end

  def update
    return destroy unless will_be_visible?
    self.class.all.each do |enemy|
      if enemy != self && collision?(enemy)
        king.shrink
        during(1500) {
          @image = @death_animation.next
        }.then {
          self.destroy
        }
      end
    end
  end

  def speed
    1
  end

  def will_be_visible?(pad=400)
    x >= -pad && x <= ($window.width+pad) && y >= -pad && y <= ($window.height+pad)
  end

  def place
    case rand(3)
    when 0
      self.x, self.y = 0, rand(Gamejam.height)
    when 1
      self.x, self.y = Gamejam.width - 1, rand(Gamejam.height)
    when 2
      self.x, self.y = rand(Gamejam.width), 0
    when 3
      self.x, self.y = rand(Gamejam.width), Gamejam.height - 1
    end
  end

  def point_at(pt)
    self.angle = Gosu.angle(x, y, pt.x, pt.y)
    self.velocity_x, self.velocity_y = Gosu.offset_x(angle, speed), Gosu.offset_y(angle, speed)
  end
end

class Crown < Chingu::GameObject
  def initialize
    super :image => Gosu::Image['assets/crown.png']
    self.x, self.y = Gamejam.center
  end
end

class King < Chingu::GameObject
  has_traits :bounding_circle, :collision_detection
  attr_accessor :size

  INITIAL_SIZE = 30.0

  def initialize
    super :image => Gosu::Image['assets/king.png']
    self.x, self.y = Gamejam.center
    self.size, self.factor = 0, INITIAL_SIZE / image.width
  end

  def update
    Enemy.all.each do |enemy|
      if collision?(enemy)
        grow
        enemy.destroy
        # if $window.score < -20
        #   $window.push_game_state GameOver
        # end
      end
    end
    self.factor = (INITIAL_SIZE + size * 2) / image.width
  end

  def grow
    self.size += 5
  end

  def shrink
    self.size -= 1 unless size <= 0
  end

end

class Pivot < Chingu::GameObject
  def initialize
    super :image => Gosu::Image['assets/pivot.png']
  end

  def update
    self.x, self.y = $window.mouse_x, $window.mouse_y
  end
end

Gamejam.new.show
