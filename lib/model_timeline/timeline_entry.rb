# frozen_string_literal: true

module ModelTimeline
  # Represents a timeline entry that records changes to a model.
  # TimelineEntry stores the tracked object, user who made the change,
  # IP address, and the changes that were made.
  #
  class TimelineEntry < ActiveRecord::Base
    self.table_name = 'model_timeline_timeline_entries'

    # @!attribute timelineable
    #   @return [Object] The model instance that this timeline entry belongs to
    belongs_to :timelineable, polymorphic: true, optional: true

    # @!attribute user
    #   @return [Object] The user who made the change
    belongs_to :user, polymorphic: true, optional: true

    # Retrieves timeline entries for a specific timelineable object
    #
    # @param [Object] timelineable The object to find timeline entries for
    # @return [ActiveRecord::Relation] Timeline entries for the specified object
    def self.for_timelineable(timelineable)
      where(timelineable_type: timelineable.class.name, timelineable_id: timelineable.id)
    end

    # Retrieves timeline entries created by a specific user
    #
    # @param [Object] user The user who created the timeline entries
    # @return [ActiveRecord::Relation] Timeline entries created by the specified user
    def self.for_user(user)
      where(user_type: user.class.name, user_id: user.id)
    end

    # Retrieves timeline entries from a specific IP address
    #
    # @param [String] ip The IP address to search for
    # @return [ActiveRecord::Relation] Timeline entries from the specified IP address
    def self.for_ip_address(ip)
      where(ip_address: ip)
    end

    # Retrieves timeline entries where a specific attribute was changed
    #
    # @param [Symbol, String] attribute The attribute name to check for changes
    # @return [ActiveRecord::Relation] Timeline entries where the specified attribute changed
    def self.with_changed_attribute(attribute)
      where('object_changes ? :key', key: attribute.to_s)
    end

    # Retrieves timeline entries where an attribute was changed to a specific value
    #
    # @param [Symbol, String] attribute The attribute name to check
    # @param [Object] value The value the attribute was changed to
    # @return [ActiveRecord::Relation] Timeline entries matching the attribute and value change
    def self.with_changed_value(attribute, value)
      where('object_changes -> :key ->> 1 = :value', key: attribute.to_s, value: value.to_s)
    end
  end
end
