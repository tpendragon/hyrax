module Hyrax
  # Ensures that the default AdminSet id is set if this form doesn't have
  # an admin_set_id provided. This should come before the
  # Hyrax::Actors::InitializeWorkflowActor, so that the correct
  # workflow can be kicked off.
  class DefaultAdminSetActor < Hyrax::Actors::AbstractActor

    # initialize the default admin set
    #
    # @return [String] the default adminset id
    def self.initialize_default_admin_set
      actor =  new(nil,nil,nil)
      actor.send(:default_admin_set_id)
    end

    def create(attributes)
      ensure_admin_set_attribute!(attributes)
      next_actor.create(attributes)
    end

    def update(attributes)
      ensure_admin_set_attribute!(attributes)
      next_actor.update(attributes)
    end

    protected
      def default_admin_set_id
        create_default_admin_set unless default_exists?
        DEFAULT_ID
      end

    private

      def ensure_admin_set_attribute!(attributes)
        return if attributes[:admin_set_id].present?
        attributes[:admin_set_id] = default_admin_set_id
      end

      DEFAULT_ID = 'admin_set/default'.freeze

      def default_exists?
        AdminSet.exists?(DEFAULT_ID)
      end

      # Creates the default AdminSet and an associated PermissionTemplate with workflow
      def create_default_admin_set
        AdminSet.create!(id: DEFAULT_ID, title: ['Default Admin Set']).tap do |_as|
          PermissionTemplate.create!(admin_set_id: DEFAULT_ID, workflow_name: 'default')
        end
      end
  end
end
