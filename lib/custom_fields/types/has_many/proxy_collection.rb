module CustomFields
  module Types
    module HasMany

      class ProxyCollection

        attr_accessor :parent, :target_klass, :field_name, :ids, :values

        def initialize(parent, target_klass, field_name, options = {})
          self.parent = parent

          self.target_klass = target_klass

          self.field_name = field_name

          self.ids, self.values = [], []
        end

        def find(id)
          id = BSON::ObjectId(id) unless id.is_a?(BSON::ObjectId)
          self.values.detect { |obj_id| obj_id == id }
        end

        def update(values)
          values = [] if values.blank? || self.target_klass.nil?

          self.ids = values.collect { |obj| self.id_for_sure(obj) }.compact
          self.values = values.collect { |obj| self.object_for_sure(obj) }.compact
        end

        # just before the parent gets saved, reflect the changes to the parent object
        def store_values
          self.parent.write_attribute(self.field_name, self.ids)
        end

        # once the parent object gets saved, call this method, kind of hook or callback
        def persist
          true
        end

        def <<(*args)
          args.flatten.compact.each do |obj|
            self.ids << self.id_for_sure(obj)
            self.values << self.object_for_sure(obj)
          end
        end

        alias :push :<<

        def size
          self.values.size
        end

        alias :length :size

        def reload
          self.collection(true)
          self
        end

        def method_missing(name, *args, &block)
          self.values.send(name, *args, &block)
        end

        protected

        def id_for_sure(id_or_object)
          id_or_object.respond_to?(:_id) ? id_or_object._id : id_or_object
        end

        def object_for_sure(id_or_object)
          if id_or_object.respond_to?(:_id)
            id_or_object
          else
            self.collection.find(id_or_object)
          end
        rescue # target_klass does not exist anymore or the target element has been removed since
          nil
        end

        def collection(reload_embedded = false)
          return [] if self.target_klass.nil?

          if self.target_klass.embedded?
            if @embedded_collection.nil? || reload_embedded
              parent_target = self.target_klass._parent

              parent_target = parent_target.reload if reload_embedded

              @embedded_collection = parent_target.send(self.target_klass.association_name)
            end

            @embedded_collection
          else
            self.target_klass
          end
        end

      end

    end
  end
end