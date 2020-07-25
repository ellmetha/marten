require "./validation/**"

module Marten
  module DB
    abstract class Model
      # Provides validation to model instances.
      module Validation
        # Returns the error set containing the errors generated during a validation.
        getter errors : ErrorSet = ErrorSet.new

        # Returns a boolean indicating whether the object is valid.
        def valid?
          @errors.clear
          perform_validation
        end

        # Returns a boolean indicating whether the object is invalid.
        def invalid?
          !valid?
        end

        # Allows to run custom validations for the considered model.
        #
        # By default this method is empty and does nothing. It should be overridden in the specific model at hand in
        # order to implement custom validation logics.
        def validate
        end

        private def perform_validation
          validate
          errors.empty?
        end
      end
    end
  end
end
