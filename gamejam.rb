require 'gosu'
require 'chingu'
require 'angle_velocity'

class Gamejam < Chingu::Window
  def initialize
    super
    @world = World.create
    @player = Player.create
    @world.input = {:holding_left => :rot_left, :holding_right => :rot_right}
  end
end

class World < Chingu::GameObject
  has_traits :angle_velocity
  
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/world.png'])
    self.velocity_angle = 1
    self.acceleration_angle = 0.4
  end
  
  def rot_left
    self.angle -= 1
    during(300) { @color = Color.new(0xFFFFFFFF) }
  end
  
  def rot_right
    self.angle += 1
  end
end

class Player < Chingu::GameObject
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/player.png'])
  end
end

Gamejam.new.show