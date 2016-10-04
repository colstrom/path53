require 'contracts'
require_relative 'resource_record_sets'

module Path53
  module Feature
    module Changes
      include ::Contracts::Core
      include ::Contracts::Builtin
      include ::Path53::Feature::ResourceRecordSets

      Action = Enum[*%w(CREATE DELETE UPSERT)]

      Change = ({
                  action: Action,
                  resource_record_set: BoundRecordSet
                })

      ChangeContext = Func[BoundRecordSet => Change]

      Contract ArrayOf[Change] => ArrayOf[Change]
      def changes(changes)
        changes
      end

      Contract ArrayOf[BoundRecordSet] => ArrayOf[Change]
      def changes(changes)
        changes.map { |change| upsert change }
      end

      Contract Or[Change, BoundRecordSet] => ArrayOf[Change]
      def changes(change)
        changes [change]
      end

      alias change changes

      def self.included(_)
        Action.instance_variable_get('@vals').each do |action|
          define_method(action.downcase) { |*args| action(action, *args) }
        end
      end

      private

      Contract Action => ChangeContext
      def action(action)
        ->(record_set) { action action, record_set }
      end

      Contract Action, BoundRecordSet => Any
      def action(action, record_set)
        {
          action: action,
          resource_record_set: record_set
        }
      end
    end
  end
end
