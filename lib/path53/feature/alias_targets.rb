require 'contracts'

module Path53
  module Feature
    module AliasTargets
      include ::Contracts::Core
      include ::Contracts::Builtin

      EvaluateTargetHealth = Or[
        Bool,
        KeywordArgs[evaluate_target_health: Bool],
      ]

      LoadBalancer = RespondTo[:canonical_hosted_zone_name_id, :canonical_hosted_zone_name]

      AliasTarget = ({
                       hosted_zone_id: String,
                       dns_name: String,
                       evaluate_target_health: Bool
                     })

      Contract None => Func[EvaluateTargetHealth => Bool]
      def evaluate_target_health
        ->(value) { evaluate_target_health value }
      end

      Contract Maybe[Bool] => Bool
      def evaluate_target_health(value = false)
        value || false
      end

      Contract KeywordArgs[evaluate_target_health: Bool] => Bool
      def evaluate_target_health(options)
        evaluate_target_health options.fetch :evaluate_target_health
      end

      Contract String, String, Maybe[EvaluateTargetHealth] => AliasTarget
      def alias_target(zone, name, check = nil)
        {
          hosted_zone_id: zone,
          dns_name: name,
          evaluate_target_health: evaluate_target_health(check)
        }
      end

      Contract LoadBalancer, Maybe[EvaluateTargetHealth] => AliasTarget
      def alias_target(load_balancer, check = nil)
        alias_target(
          load_balancer.canonical_hosted_zone_name_id,
          load_balancer.canonical_hosted_zone_name,
          check
        )
      end
    end
  end
end
