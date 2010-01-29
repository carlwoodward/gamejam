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
    super(Gamejam.width, Gamejam.height)
    @world = World.create
    @player = Player.create
    @world.input = {:holding_right => :start_rotation, :released_right => :finish_rotation}
    self.input = {:escape => :close}
  end
end

class World < Chingu::GameObject
  has_traits :angle_velocity, :timer
  
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/blue.png'])
    self.x, self.y = Gamejam.center
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
    super options.merge(:image => Gosu::Image['assets/king.png'])
    self.x, self.y = Gamejam.center
  end
end

# class Enemy < Chingu::GameObject
#   def initialize(options={})
#     super options.merge(:image => Gosu::Image['assets/player.png'])
#     self.x, self.y = 400, 300
#   end
# end

Gamejam.new.show