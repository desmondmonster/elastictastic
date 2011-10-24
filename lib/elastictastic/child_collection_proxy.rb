module Elastictastic
  class ChildCollectionProxy < Scope
    attr_reader :parent, :transient_children

    def initialize(association, parent)
      super(
        parent.index,
        association.clazz,
        Search.new(
          'query' => {
            'constant_score' => {
              'filter' => { 'term' => { '_parent' => parent.id }}
            }
          }
        )
      )
      @parent = parent
      @parent_collection = self
      @transient_children = []
    end

    def new(*args)
      parent_collection = self
      super.tap do |instance|
        instance.instance_eval do
          @_parent_collection = parent_collection
        end
        @transient_children << instance
      end
    end

    def first
      super || @transient_children.first
    end

    def persisted!(child)
      @transient_children.delete(child)
    end

    private

    def enumerate_each(batch_options = {}, &block)
      super
      @transient_children.each(&block)
    end

    def params_for_find
      super.merge('routing' => @parent.id)
    end
  end
end
