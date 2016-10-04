require 'contracts'
require_relative 'alias_targets'

module Path53
  module Feature
    module ResourceRecordSets
      include ::Contracts::Core
      include ::Contracts::Builtin
      include ::Path53::Feature::AliasTargets

      Type = Enum[*%w(A AAAA CNAME MX NAPTR NS PTR SOA SPF SRV TXT)]
      TTL = Or[Integer, KeywordArgs[ttl: Integer]]
      ResourceRecord = ({ value: String })

      AliasRecordSet = ({ alias_target: AliasTarget })
      ResourceRecordSet = ({
                             resource_records: ArrayOf[ResourceRecord],
                             ttl: Integer
                           })

      RecordSet = Or[ResourceRecordSet, AliasRecordSet]
      Target = Xor[RecordSet, LoadBalancer, String]

      BoundRecordSet = And[RecordSet, ({ name: String, type: Type })]

      RecordContext = Func[Target => BoundRecordSet]
      TypedContext = Func[String => RecordContext]

      Contract None => Func[TTL => Integer]
      def ttl
        ->(value) { ttl value }
      end

      Contract Maybe[Integer] => Integer
      def ttl(value = 300)
        value || 300
      end

      Contract KeywordArgs[ttl: Integer] => Integer
      def ttl(options)
        ttl options.fetch :ttl
      end

      Contract ArrayOf[String], Maybe[TTL] => ResourceRecordSet
      def record_set(targets, duration = nil)
        {
          ttl: ttl(duration),
          resource_records: targets.map { |target| { value: name(target) } }
        }
      end

      Contract String, Maybe[TTL] => ResourceRecordSet
      def record_set(target, duration = nil)
        record_set [target], duration
      end

      Contract AliasTarget, Maybe[TTL] => AliasRecordSet
      def record_set(target, duration = nil)
        { alias_target: target }
      end

      Contract LoadBalancer, Maybe[TTL] => AliasRecordSet
      def record_set(load_balancer, duration = nil)
        record_set alias_target load_balancer
      end

      def self.included(*)
        Type.instance_variable_get('@vals').each do |t|
          define_method(t.downcase) { |*args| type(t, *args) }
        end
      end

      private

      Contract String => String
      def name(name)
        name.gsub /\.@$/, ".#{zone.name}"
      end

      Contract Type => TypedContext
      def type(type)
        ->(name, target) { type type, name, target }
      end

      Contract Type, String => RecordContext
      def type(type, name)
        ->(target) { type type, name, target }
      end

      Contract Type, String, Target, Maybe[TTL] => BoundRecordSet
      def type(type, name, target, duration = nil)
        {
          type: type,
          name: name(name)
        }.merge record_set(target, duration)
      end
    end
  end
end
