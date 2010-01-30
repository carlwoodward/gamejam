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
  
  attr_accessor :score, :king, :enemy_waves, :world

  def initialize
    super(self.class.width, self.class.height)
    self.world = World.create
    self.king = King.create
    self.enemy_waves = EnemyWaves.create
    enemy_waves.spawn
    @crown = Crown.create
    @world.pivot = Pivot.create
    self.input = {:escape => :close}
    self.score = 0
  end
end

class World < Chingu::GameObject

  has_trait :angular_momentum, :max_angular_velocity => 8
  has_trait :timer

  attr_accessor :enemies, :pivot, :current_background

  BACKGROUND_DIM = 2310

  def initialize(options={})
    @backgrounds = [
      { :color => :blue, :image => Gosu::Image['assets/blue.png']}, 
      { :color => :yellow, :image => Gosu::Image['assets/yellow.png']}, 
      { :color => :purple, :image => Gosu::Image['assets/purple.png']}]

    super options.merge(:image => @backgrounds[rand(@backgrounds.length)])
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
    $window.enemy_waves.current_wave.each {|enemy| transform(enemy)} unless previous_angle == angle
    draw_score
  end
  
  def change_background
    self.current_background = @backgrounds[rand(@backgrounds.length)]
    @image = current_background[:image]
    current_background
  end
  
  def draw_score
    PulsatingText.destroy_if { |text| text.size == 40}
    PulsatingText.create($window.score, :x => 40, :y => Gamejam.height - 80, :size => 40)
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
      
      # self.center_x = 0.25 # (center_x*BACKGROUND_DIM + $window.mouse_x-x) * Math.cos(angle.gosu_to_radians) / BACKGROUND_DIM
      # self.center_y = 0.25 # (center_y*BACKGROUND_DIM + $window.mouse_y-y) * Math.sin(angle.gosu_to_radians) / BACKGROUND_DIM

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

class EnemyWaves < Chingu::BasicGameObject
  has_traits :timer
  
  attr_accessor :waves
  
  def initialize
    super
    self.waves = []
    
    every(3000, :name => 'spawning') do
      spawn
    end
  end
  
  def all_enemies
    waves.flatten
  end
  
  def of_color(color)
    all_enemies.select { |enemy| enemy.color == color }
  end
  
  def kill_all
    all_enemies.each {|enemy| enemy.destroy}
    stop_timers
  end
  
  def spawn
    bg = $window.world.change_background
    enemies = 5.times.to_a.collect { Enemy.create($window.king, bg[:color].to_s) }
    self.waves << enemies
  end
  
  def current_wave
    waves.last
  end
end

class Enemy < Chingu::GameObject

  has_traits :velocity, :bounding_circle, :collision_detection, :timer

  attr_accessor :king, :color
  
  def initialize(king, color, options={})
    self.king = king
    self.color = color
    super options.merge(:image => Gosu::Image["assets/triangle_#{color}.png"])
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

    point_at king
    @death_animation = Chingu::Animation.new(:file => "assets/particle.png", :size => [32,32])
  end

  def update
    self.class.all.each do |enemy|
      if enemy != self && collides?(enemy)
        king.shrink
        during(1500) { 
          @image = @death_animation.next 
        }.then {
          self.destroy
          $window.score += 1
        }
      end
    end
  end

  def speed
    1
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
  has_traits :bounding_box, :collision_detection
  
  attr_accessor :radius
  
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/king.png'])
    self.x, self.y = Gamejam.center
    self.radius = 15.0
  end
  
  def update
    Enemy.all.each do |enemy|
      if self.bounding_circle_collision?(enemy)
        $window.score -= 1
        self.radius += 5
        enemy.destroy
        # if $window.score < -20
        #   $window.push_game_state GameOver
        # end
      end
    end
    self.factor = (radius * 2) / @image.width
  end
  
  def shrink
    self.radius -= 5 unless radius <= 15
  end
  
end

class GameOver < Chingu::GameState
  def update
    PulsatingText.destroy_if { |text| text.size == 100}
    PulsatingText.create("YOU DIED", :x => 400, :y => 200, :size => 100)
    $window.enemy_waves.kill_all
  end
end

class Pivot < Chingu::GameObject
  def initialize(options={})
    super options.merge(:image => Gosu::Image['assets/pivot.png'])
  end

  def update
    self.x, self.y = $window.mouse_x, $window.mouse_y
  end
end

class PulsatingText < Chingu::Text
  has_traits :timer, :effect
  
  def initialize(text, options = {})
    super(text, options)
    
    options = text  if text.is_a? Hash
    @pulse = options[:pulse] || false
    self.rotation_center(:center_center)
    every(20) { create_pulse }   if @pulse == false
  end
  
  def create_pulse
    pulse = PulsatingText.create(@text, :x => @x, :y => @y, :height => @height, :pulse => true, :image => @image, :zorder => @zorder+1)
    colors = [Gosu::Color::RED, Gosu::Color::GREEN, Gosu::Color::BLUE]
    pulse.color = colors[rand(colors.size)].dup
    pulse.mode = :additive
    pulse.alpha -= 150
    pulse.scale_rate = 0.002
    pulse.fade_rate = -3 + rand(2)
    pulse.rotation_rate = rand(2)==0 ? 0.05 : -0.05
  end
    
  def update
    destroy if self.alpha == 0
  end
  
end


Gamejam.new.show
