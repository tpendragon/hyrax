# There is an interplay between an AdminSet and a PermissionTemplate.
# @see Hyrax::AdminSetBehavior for further discussion
class AdminSet < ActiveFedora::Base
  DEFAULT_ID = 'admin_set/default'.freeze

  include Hyrax::AdminSetBehavior
end
