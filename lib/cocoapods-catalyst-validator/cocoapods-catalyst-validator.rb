require 'cocoapods-catalyst-validator/gem_version'
require 'cocoapods-core'
require 'cocoapods'
require 'macho'


module CocoapodsCatalystValidator
  CATALYST_PLATFORM = 6
  SUPPORTS_MACCATALYST = 'SUPPORTS_MACCATALYST'

  class CatalystValidator
    def self.support_catalust_for_xcframework?(path)
      !Pathname.glob(path + '*-maccatalyst').empty?
    end

    def self.support_catalust_for_framework?(path)
      path += '.framework' unless path.extname == '.framework'
      name = path.basename(".framework")
      support_catalyst?(path + name)
    end

    def self.support_catalust_for_library?(path)
      support_catalyst?(path)
    end

    def self.support_catalyst?(path)
      !binary_arch(path).map {|a| platform_is_catalyst?(path, a)}.include?(false)
    end

    def self.binary_arch(path)
      `lipo -archs "#{path}"`.split(' ')
    end

    def self.platform_is_catalyst?(path, arch)
      platform = `otool -l -arch #{arch} "#{path}" | grep platform -m 1`
      return false unless platform =~ /platform\s+(\w*)/
      return ['MACCATALYST', '1'].include?(platform.match(/platform\s+(\w*)/)[1])
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
          raise Informative, "Unsupported catalyst verify type '#{type}', must be :warning or :error."
        end
        @catalyst_verification = type
      end

      def catalyst_verification
        if root?
          @catalyst_verification
        else
          @catalyst_verification || parent.catalyst_verification
        end
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
          libs_cache = {}
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
                un_support_catalyst_libs = verify_libraries.reject{ |l| libs_cache[l] ||= CocoapodsCatalystValidator::CatalystValidator.support_catalust_for_library?(l)}
                un_support_catalyst_libs.concat verify_frameworks.reject{ |f| libs_cache[f] ||= CocoapodsCatalystValidator::CatalystValidator.support_catalust_for_framework?(f)}
                un_support_catalyst_libs.concat verify_xcframeworks.reject{ |x| libs_cache[x] ||= CocoapodsCatalystValidator::CatalystValidator.support_catalust_for_xcframework?(x)}
                unsupport_names = un_support_catalyst_libs.map(&:basename).map(&:to_s)
                next if unsupport_names.empty?
                case catalyst_verification
                when :warning
                  UI.puts "Catalyst verify warning: \n#{unsupport_names}".yellow
                else :error
                  raise Informative, "Catalyst verify error: \n#{unsupport_names}"
                end
              end
            end
          end
        end

      end
    end
  end
end

