module Hyrax
  module MyControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Catalog
    include Hydra::BatchEditBehavior

    included do
      include Blacklight::Configurable

      copy_blacklight_config_from(CatalogController)

      before_action :authenticate_user!
      before_action :enforce_show_permissions, only: :show
      before_action :enforce_viewing_context_for_show_requests, only: :show

      # include the render_check_all view helper method
      helper ::BatchEditsHelper
      # include the display_trophy_link view helper method
      helper Hyrax::TrophyHelper
    end

    def index
      # return the user's collections
      @user_collections = Hyrax::CollectionsService.new(self).search_results(:edit)

      @user = current_user
      (@response, @document_list) = query_solr
      prepare_instance_variables_for_batch_control_display

      respond_to do |format|
        format.html {}
        format.rss  { render layout: false }
        format.atom { render layout: false }
      end
    end

    private

      # TODO: Extract a presenter object that wrangles all of these instance variables.
      def prepare_instance_variables_for_batch_control_display
        # set up some parameters for allowing the batch controls to show appropriately
        max_batch_size = 80
        count_on_page = @document_list.count { |doc| batch.index(doc.id) }
        @disable_select_all = @document_list.count > max_batch_size
        batch_size = batch.uniq.size
        @result_set_size = @response.response["numFound"]
        @empty_batch = batch.empty?
        @all_checked = (count_on_page == @document_list.count)
        batch_size_on_other_page = batch_size - count_on_page
        @batch_part_on_other_page = batch_size_on_other_page > 0

        @add_files_to_collection = params.fetch(:add_files_to_collection, '')
      end

      def query_solr
        search_results(params)
      end
  end
end
