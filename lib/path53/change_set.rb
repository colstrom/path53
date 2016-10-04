require 'aws-sdk'
require 'contracts'
require_relative 'features'

module Path53
  class ChangeSet
    include ::Contracts::Core
    include ::Contracts::Builtin
    include ::Path53::Feature::AliasTargets
    include ::Path53::Feature::Changes
    include ::Path53::Feature::ResourceRecordSets

    HostedZone = RespondTo[:id, :name]
    ChangeRequest = ({
                       hosted_zone_id: String,
                       change_batch: {
                         comment: Maybe[String],
                         changes: ArrayOf[Change]
                       }
                     })

    attr_reader :zone

    Contract HostedZone => ChangeSet
    def initialize(zone, changes = Set.new)
      @zone = zone
      @changes = changes
      self
    end

    Contract Change => ChangeSet
    def add(change)
      @changes.add change
      self
    end

    Contract BoundRecordSet => ChangeSet
    def add(change)
      @changes.add(*changes(change))
      self
    end

    Contract Change => ChangeSet
    def remove(change)
      @changes.delete change
      self
    end

    alias rem remove

    Contract None => ChangeSet
    def reset!
      @changes = Set.new
      self
    end

    Contract Proc => ChangeSet
    def batch(&block)
      self.tap do |this|
        this.instance_eval(&block)
      end
    end

    Contract None => String
    def apply!
      route53.change_resource_record_sets(self.to_request).change_info.id
    end

    Contract KeywordArgs[comment: Optional[String]] => ChangeRequest
    def to_request(comment: nil)
      {
        hosted_zone_id: zone.id,
        change_batch: {
          changes: changes(@changes.to_a)
        }.tap { |batch| batch.merge! comment: comment if comment }
      }
    end

    private

    def route53
      @route53 ||= Aws::Route53::Client.new
    end
  end
end
