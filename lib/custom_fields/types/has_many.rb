module CustomFields

  module Types

    module HasMany

      module Field

        extend ActiveSupport::Concern

        included do

          def has_many_to_recipe
            { 'class_name' => self.class_name, 'inverse_of' => self.inverse_of }
          end

          def has_many_to_is_relationship?
            self.type == 'has_many'
          end

        end

      end

      module Target

        extend ActiveSupport::Concern

        module ClassMethods

          # Adds a has_many relationship between 2 mongoid models
          #
          # @param [ Class ] klass The class to modify
          # @param [ Hash ] rule It contains the name of the relation and if it is required or not
          #
          def apply_has_many_custom_field(klass, rule)
            # puts "#{klass.inspect}.has_many #{rule['name'].inspect}, :class_name => #{rule['class_name'].inspect}, :inverse_of => #{rule['inverse_of']}" # DEBUG

            position_name = "position_in_#{rule['inverse_of']}"

            klass.has_many rule['name'], :class_name => rule['class_name'], :inverse_of => rule['inverse_of'], :order => position_name.to_sym.asc

            klass.accepts_nested_attributes_for rule['name'], :allow_destroy => true

            if rule['required']
              klass.validates_length_of rule['name'], :minimum => 1
            end
          end

        end

      end

    end

  end

end