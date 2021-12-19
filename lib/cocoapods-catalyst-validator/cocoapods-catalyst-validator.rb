require 'cocoapods-catalyst-validator/gem_version'
require 'cocoapods-core'
require 'cocoapods'
require 'macho'


module CocoapodsCatalystValidator
  CATALYST_PLATFORM = 6
  SUPPORTS_MACCATALYST = 'SUPPORTS_MACCATALYST'

  class CatalystValidator
    def self.support_catalyst?(binary)
      MachO.open(binary).load_commands.select { |l| l.is_a?(BuildVersionCommand) }.first.platform == CATALYST_PLATFORM
    end

    def self.support_catalust_for_xcframework?(path)
      !Pathname.glob(path + '*-maccatalyst').empty?
    end
    def self.support_catalust_for_framework?(path)
      false
    end
    def self.support_catalust_for_library?(path)
      false
    end
  end
end

module Pod
  class Podfile
    def use_catalyst_verify!(type = :warning)
      current_target_definition.use_catalyst_verify!(type)
    end

    class TargetDefinition
      attr_accessor :catalyst_verification

      def use_catalyst_verify!(type = :warning)
        unless [:warning, :error].include?(type)
          raise StandardError, "Unsupported catalyst verify type '#{type}', must be :warning or :error."
        end
        @catalyst_verification = type
      end

      def catalyst_verification
        @catalyst_verification if root?
        @catalyst_verification ? @catalyst_verification : parent.catalyst_verification
      end
    end
  end

  class Installer
    class Xcode
      class TargetValidator
        alias_method :original_validate!, :validate!
        def validate!
          original_validate!
          verify_pods_vendored_artifacts_support_catalyst
        end
        def verify_pods_vendored_artifacts_support_catalyst
          aggregate_targets.each do |aggregate_target|
            catalyst_verification = aggregate_target.target_definition.catalyst_verification
            next unless [:warning, :error].include?(catalyst_verification)
            next unless aggregate_target.platform.name == :ios
            aggregate_target.user_targets.each do |user_target|
              user_target.build_configurations.each do |config|
                next unless config.build_settings[CocoapodsCatalystValidator::SUPPORTS_MACCATALYST]
                pod_targets = aggregate_target.pod_targets_for_build_configuration(config.name)
                verify_libraries = pod_targets.flat_map(&:file_accessors).flat_map(&:vendored_libraries)
                verify_xcframeworks = pod_targets.flat_map(&:file_accessors).flat_map(&:vendored_xcframeworks)
                verify_frameworks = pod_targets.flat_map(&:file_accessors).flat_map(&:vendored_frameworks) - verify_xcframeworks
                un_support_catalyst_libs = verify_libraries.select{ |l| !CocoapodsCatalystValidator::CatalystValidator.support_catalust_for_library?(l)}
                un_support_catalyst_libs += verify_frameworks.select{ |f| !CocoapodsCatalystValidator::CatalystValidator.support_catalust_for_framework?(f)}
                un_support_catalyst_libs += verify_xcframeworks.select{ |x| !CocoapodsCatalystValidator::CatalystValidator.support_catalust_for_framework?(x)}
                unsupport_names = un_support_catalyst_libs.map(&:basename).map(&:to_s)
                unless un_support_catalyst_libs.empty?
                  case catalyst_verification
                  when :warning
                    UI.puts "catalyst verify warning: #{unsupport_names}".yellow
                  else :error
                    raise StandardError, "catalyst verify error: #{unsupport_names}"
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
