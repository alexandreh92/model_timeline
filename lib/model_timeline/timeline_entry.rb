# frozen_string_literal: true

module ModelTimeline
  class TimelineEntry < ActiveRecord::Base
    self.table_name = 'model_timeline_timeline_entries'

    belongs_to :timelineable, polymorphic: true, optional: true
    belongs_to :user, polymorphic: true, optional: true

    def self.for_timelineable(timelineable)
      where(timelineable_type: timelineable.class.name, timelineable_id: timelineable.id)
    end

    def self.for_user(user)
      where(user_type: user.class.name, user_id: user.id)
    end

    def self.for_ip_address(ip)
      where(ip_address: ip)
    end

    def self.with_changed_attribute(attribute)
      where('object_changes ? :key', key: attribute.to_s)
    end

    def self.with_changed_value(attribute, value)
      where('object_changes -> :key ->> 1 = :value', key: attribute.to_s, value: value.to_s)
    end
  end
end
