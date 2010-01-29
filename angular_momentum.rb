module Chingu
  module Traits
    #
    # A chingu trait providing angular_velocity and angular_acceleration logic.
    # Adds parameters: angular_velocity_x/y, angular_acceleration_x/y and modifies self.x / self.y
    # Also keeps previous_x and previous_y which is the x, y before modification.
    # Can be useful for example collision detection
    #
    module AngularMomentum
      attr_accessor :angular_velocity, :angular_acceleration, :max_angular_velocity, :previous_angle

      module ClassMethods
        def initialize_trait(options = {})
          trait_options[:angular_velocity] = {:apply => true}.merge(options)
        end
      end

      def setup_trait(options)
        self.angular_velocity = options[:angular_velocity] || 0
        self.angular_acceleration = options[:angular_acceleration] || 0
        self.max_angular_velocity = options[:max_angular_velocity] || 10
        super
      end

      def update_trait
        self.angular_velocity += angular_acceleration if (angular_velocity + angular_acceleration).abs <= max_angular_velocity
        self.previous_angle = angle
        self.angle += angular_velocity if trait_options[:angular_velocity][:apply]
        super
      end

      def stop_angular_momentum
        self.angular_velocity, self.angular_acceleration = 0, 0
        # self.angular_velocity = 0
      end
    end
  end
end