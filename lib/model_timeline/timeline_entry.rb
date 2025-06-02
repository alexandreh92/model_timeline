module ModelTimeline
  class TimelineEntry < ActiveRecord::Base
    self.table_name = 'model_timeline_timeline_entries'

    belongs_to :auditable, polymorphic: true, optional: true
    belongs_to :user, polymorphic: true, optional: true

    validates :audit_log_table, :audit_action, presence: true

   # Dynamic finder methods
    def self.for_auditable(auditable)
      where(auditable_type: auditable.class.name, auditable_id: auditable.id)
    end

    def self.for_log_table(table_name)
      where(audit_log_table: table_name)
    end

    def self.for_user(user)
      where(user_type: user.class.name, user_id: user.id)
    end

    def self.for_ip_address(ip)
      where(ip_address: ip)
    end

    # PostgreSQL-specific querying for JSONB
    def self.with_changed_attribute(attribute)
      where("object_changes ? :key", key: attribute.to_s)
    end

    def self.with_changed_value(attribute, value)
      # Search for changes where the new value matches
      # This handles the [old_value, new_value] format in the changes column
      where("object_changes -> :key ->> 1 = :value", key: attribute.to_s, value: value.to_s)
    end
  end
end
