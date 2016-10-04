require_relative 'path53/change_set'

module Path53
  def self.change(zone)
    ChangeSet.new(zone)
  end
end
