require 'gosu'
require 'chingu'
require 'angle_velocity'

class Gamejam < Chingu::Window
  def initialize
    super
    @world = World.create
    @player = Player.create
    @world.input = {:holding_right => :start_rotation, :released_right => :finish_rotation}
    self.input = {:escape => :close}
  end
end

class World < Chingu::GameObject
  has_traits :angle_velocity, :timer
  
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/world.png'])
    self.x, self.y = 400, 300
  end
  
  def start_rotation
    stop_timers
    self.acceleration_angle = 0.075
  end
  
  def finish_rotation
    during(2000) { self.acceleration_angle *= 0.95; self.velocity_angle *= 0.95 }.then { self.acceleration_angle = 0; self.velocity_angle = 0 }
  end
end

class Player < Chingu::GameObject
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/player.png'])
    self.x, self.y = 400, 300
  end
end

Gamejam.new.show