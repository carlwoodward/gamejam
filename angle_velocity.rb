module Chingu
  module Traits
    #
    # A chingu trait providing velocity and acceleration logic. 
    # Adds parameters: velocity_x/y, acceleration_x/y and modifies self.x / self.y
    # Also keeps previous_x and previous_y which is the x, y before modification.
    # Can be useful for example collision detection
    #
    module AngleVelocity
      attr_accessor :velocity_angle, :acceleration_angle, :max_velocity
      attr_reader :previous_angle
      
      module ClassMethods
        def initialize_trait(options = {})
          trait_options[:velocity] = {:apply => true}.merge(options)
        end
      end
      
      def setup_trait(options)
        @velocity_options = {:debug => false}.merge(options)        
        
        @velocity_angle = options[:velocity_angle] || 0
        @acceleration_angle = options[:acceleration_angle] || 0
        @max_velocity = options[:max_velocity] || 1000
        super
      end
      
      def update_trait        
        @velocity_angle += @acceleration_angle if	(@velocity_angle + @acceleration_angle).abs < @max_velocity
        
        @previous_angle = @angle
        
        #
        # if option :apply is false, just calculate velocities, don't apply them to x/y
        #
        if trait_options[:velocity][:apply]          
          self.angle += @velocity_angle
        end
        super
      end
      
      def stop
        # @acceleration_y = @acceleration_x = 0
        @velocity_angle = 0
      end      
    end
  end
end