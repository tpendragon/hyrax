module Hyrax
  class AdminSetPresenter < CollectionPresenter
    def total_items
      ActiveFedora::SolrService.count("{!field f=isPartOf_ssim}#{id}")
    end

    # AdminSet cannot be deleted if default set or non-empty
    def disable_delete?
      total_items > 0 || default_set?
    end

    # Message to display if deletion is disabled
    def disabled_message
      return I18n.t('hyrax.admin.admin_sets.delete.error_default_set') if default_set?
      return I18n.t('hyrax.admin.admin_sets.delete.error_not_empty') if total_items > 0
    end

    private

      def default_set?
        id == AdminSet::DEFAULT_ID
      end
  end
end
