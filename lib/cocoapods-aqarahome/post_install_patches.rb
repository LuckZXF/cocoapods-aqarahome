# frozen_string_literal: true

module CocoapodsAqarahome
  # Post-install / post-integrate fixes for newer Xcode, React Native upgrades,
  # and legacy pods (WCDB, ZBar, fmt, AWSCore, privacy manifests, etc.).
  module PostInstallPatches
    module_function

    def apply_post_install(installer, options = {})
      aggregate_target = options.fetch(:aggregate_target, 'Pods-AqaraHome')
      user_target = options.fetch(:user_target, 'AqaraHome')
      testadhoc_config = options.fetch(:testadhoc_config_name, 'TestADHoc')
      privacy_line_regex = options.fetch(
        :privacy_resource_line_regex,
        /^.*LMNewSensorsAnalytics\/LMNewSensorsAnalytics\/LMNewSensorsAnalytics\/Resources\/PrivacyInfo\.xcprivacy"\n/
      )
      privacy_path_filter = options.fetch(:privacy_path_filter, 'LMNewSensorsAnalytics')

      patch_bundle_code_signing(installer)
      patch_aggregate_xcconfig_iconv(installer, aggregate_target: aggregate_target)
      patch_netinet6_headers(installer)
      patch_privacy_resources_script(
        installer,
        aggregate_target: aggregate_target,
        privacy_line_regex: privacy_line_regex
      )
      patch_user_project_copy_pods_resources(
        installer,
        aggregate_target: aggregate_target,
        user_target: user_target,
        privacy_path_filter: privacy_path_filter
      )

      normalize_build_setting_array = lambda do |value|
        values = value.is_a?(Array) ? value : [value]
        values.compact.flat_map { |item| item.to_s.split(/\s+/) }.reject(&:empty?)
      end

      rn_pod_target = lambda do |name|
        name == 'React-Core' ||
          name.start_with?('React-') ||
          name.start_with?('RCT') ||
          name == 'Yoga' ||
          name == 'YogaKit' ||
          name == 'hermes-engine' ||
          name == 'ReactCodegen'
      end

      patch_fmt_base_header = lambda do
        fmt_base_header = File.join(
          installer.sandbox.root.to_s,
          'fmt',
          'include',
          'fmt',
          'base.h'
        )
        return unless File.exist?(fmt_base_header)

        content = File.read(fmt_base_header)
        marker = <<~MARKER
          #if defined(FMT_USE_CONSTEVAL)
          // Use the provided definition.
          #elif !defined(__cpp_lib_is_constant_evaluated)
        MARKER
        return if content.include?(marker)

        updated = content.sub(
          '#if !defined(__cpp_lib_is_constant_evaluated)',
          marker.chomp
        )
        if updated != content
          current_mode = File.stat(fmt_base_header).mode
          File.chmod(current_mode | 0o200, fmt_base_header) unless File.writable?(fmt_base_header)
          File.write(fmt_base_header, updated)
        end
      end

      wcdb_objc_support_files = Dir.glob(
        File.join(
          installer.sandbox.root.to_s,
          'Target Support Files',
          'WCDB.objc',
          'WCDB.objc*.xcconfig'
        )
      )

      wcdb_sqlcipher_support_files = Dir.glob(
        File.join(
          installer.sandbox.root.to_s,
          'Target Support Files',
          'WCDBOptimizedSQLCipher',
          'WCDBOptimizedSQLCipher*.xcconfig'
        )
      )

      zbar_sdk_support_files = Dir.glob(
        File.join(
          installer.sandbox.root.to_s,
          'Target Support Files',
          'ZBarSDK',
          'ZBarSDK*.xcconfig'
        )
      )

      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          if config.name == testadhoc_config && rn_pod_target.call(target.name)
            definitions = normalize_build_setting_array.call(
              config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] || '$(inherited)'
            )
            definitions.reject! do |value|
              value.start_with?('RCT_DEBUG=') ||
                value.start_with?('RCT_DEV=') ||
                value.start_with?('RCT_DEV_MENU=') ||
                value.start_with?('RCT_DEV_SETTINGS_ENABLE_PACKAGER_CONNECTION=')
            end
            definitions << 'RCT_DEBUG=1'
            definitions << 'RCT_DEV=1'
            definitions << 'RCT_DEV_MENU=1'
            definitions << 'RCT_DEV_SETTINGS_ENABLE_PACKAGER_CONNECTION=1'
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = definitions.uniq
          end

          case target.name
          when 'fmt'
            definitions = normalize_build_setting_array.call(
              config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] || '$(inherited)'
            )
            definitions.reject! { |value| value.start_with?('FMT_USE_CONSTEVAL=') }
            definitions << 'FMT_USE_CONSTEVAL=0'
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = definitions.uniq
          when 'WCDB.objc'
            header_search_paths = config.build_settings['HEADER_SEARCH_PATHS'] || '$(inherited)'
            header_search_paths = [header_search_paths] unless header_search_paths.is_a?(Array)
            header_search_paths << '"${PODS_ROOT}/boost"'
            header_search_paths << '"${PODS_TARGET_SRCROOT}/src/**"'
            config.build_settings['HEADER_SEARCH_PATHS'] = header_search_paths.uniq
            config.build_settings['USE_HEADERMAP'] = 'NO'
          when 'WCDBOptimizedSQLCipher'
            definitions = normalize_build_setting_array.call(
              config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] || '$(inherited)'
            )
            definitions.reject! { |value| value == '_HAVE_SQLITE_CONFIG_H' }
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = definitions
            header_search_paths = config.build_settings['HEADER_SEARCH_PATHS'] || '$(inherited)'
            header_search_paths = [header_search_paths] unless header_search_paths.is_a?(Array)
            header_search_paths.unshift('"${PODS_ROOT}/boost"')
            header_search_paths.unshift('"${PODS_TARGET_SRCROOT}/ext/rtree"')
            header_search_paths.unshift('"${PODS_TARGET_SRCROOT}/ext/fts3"')
            header_search_paths.unshift('"${PODS_TARGET_SRCROOT}"')
            header_search_paths.unshift('"${PODS_TARGET_SRCROOT}/src"')
            config.build_settings['HEADER_SEARCH_PATHS'] = header_search_paths.uniq
            config.build_settings['USE_HEADERMAP'] = 'NO'
          when 'LMAccessNetSDK'
            header_search_paths = config.build_settings['HEADER_SEARCH_PATHS'] || '$(inherited)'
            header_search_paths = [header_search_paths] unless header_search_paths.is_a?(Array)
            header_search_paths.unshift('"${PODS_TARGET_SRCROOT}/APP_iOS_AccessNetSDK/LumiConnectSDK/LMAppleHomeConnect"')
            config.build_settings['HEADER_SEARCH_PATHS'] = header_search_paths.uniq
          when 'ZBarSDK'
            header_search_paths = config.build_settings['HEADER_SEARCH_PATHS'] || '$(inherited)'
            header_search_paths = [header_search_paths] unless header_search_paths.is_a?(Array)
            header_search_paths.unshift('"${PODS_TARGET_SRCROOT}/zbar"')
            config.build_settings['HEADER_SEARCH_PATHS'] = header_search_paths.uniq
            config.build_settings['USE_HEADERMAP'] = 'NO'
          end
        end
      end

      patch_fmt_base_header.call

      wcdb_objc_support_files.each do |path|
        content = File.read(path)
        next if content.include?('"${PODS_TARGET_SRCROOT}/src/**"') &&
                content.include?('"${PODS_ROOT}/boost"')

        content = content.gsub(
          /^HEADER_SEARCH_PATHS = (.+)$/,
          "HEADER_SEARCH_PATHS = \\1 \"${PODS_ROOT}/boost\" \"${PODS_TARGET_SRCROOT}/src/**\""
        )
        File.write(path, content)
      end

      wcdb_sqlcipher_support_files.each do |path|
        content = File.read(path)
        updated = content.gsub(/\s_HAVE_SQLITE_CONFIG_H\b/, '')
        unless updated.include?('"${PODS_ROOT}/boost"') &&
               updated.include?('"${PODS_TARGET_SRCROOT}"') &&
               updated.include?('"${PODS_TARGET_SRCROOT}/src"') &&
               updated.include?('"${PODS_TARGET_SRCROOT}/ext/fts3"') &&
               updated.include?('"${PODS_TARGET_SRCROOT}/ext/rtree"')
          updated = updated.gsub(
            /^HEADER_SEARCH_PATHS = (.+)$/,
            "HEADER_SEARCH_PATHS = \"${PODS_ROOT}/boost\" \"${PODS_TARGET_SRCROOT}/ext/rtree\" \"${PODS_TARGET_SRCROOT}/ext/fts3\" \"${PODS_TARGET_SRCROOT}/src\" \"${PODS_TARGET_SRCROOT}\" \\1"
          )
        end
        File.write(path, updated) if updated != content
      end

      zbar_sdk_support_files.each do |path|
        content = File.read(path)
        updated = content

        unless updated.include?('"${PODS_TARGET_SRCROOT}/zbar"')
          updated = updated.gsub(
            /^HEADER_SEARCH_PATHS = (.+)$/,
            'HEADER_SEARCH_PATHS = "${PODS_TARGET_SRCROOT}/zbar" \1'
          )
        end

        unless updated.match?(/^USE_HEADERMAP = NO$/)
          updated = "#{updated.rstrip}\nUSE_HEADERMAP = NO\n"
        end

        File.write(path, updated) if updated != content
      end

      patch_awscore_unistd(installer)
    end

    def apply_post_integrate(installer, options = {})
      user_target = options.fetch(:user_target, 'AqaraHome')
      privacy_path_filter = options.fetch(:privacy_path_filter, 'LMNewSensorsAnalytics')

      installer.aggregate_targets
        .map(&:user_project)
        .compact
        .uniq { |project| project.path.to_s }
        .each do |user_project|
          changed = false

          user_project.targets.each do |ut|
            next unless ut.name == user_target

            ut.shell_script_build_phases.each do |phase|
              next unless phase.name == '[CP] Copy Pods Resources'

              input_paths = phase.input_paths.reject do |path|
                path.include?(privacy_path_filter) && path.include?('PrivacyInfo.xcprivacy')
              end
              output_paths = phase.output_paths.reject do |path|
                path.end_with?('/PrivacyInfo.xcprivacy')
              end

              changed ||= input_paths != phase.input_paths || output_paths != phase.output_paths
              phase.input_paths = input_paths
              phase.output_paths = output_paths
            end
          end

          user_project.save if changed
        end
    end

    def patch_bundle_code_signing(installer)
      installer.pods_project.targets.each do |target|
        next unless target.respond_to?(:product_type) && target.product_type == 'com.apple.product-type.bundle'

        target.build_configurations.each do |config|
          config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end
    end

    def patch_aggregate_xcconfig_iconv(installer, aggregate_target:)
      installer.pods_project.targets.each do |target|
        next unless target.name == aggregate_target

        puts "Updating #{target.name} OTHER_LDFLAGS To fit Xcode15.0.1+"
        target.build_configurations.each do |config|
          xcconfig_path = config.base_configuration_reference.real_path

          File.open(xcconfig_path, 'r+') do |file|
            file.each_line do |line|
              next unless line.include?('iconv.2.4.0')

              original_length = line.length
              updated_line = line.gsub('iconv.2.4.0', 'iconv.2')
              file.seek(-original_length, IO::SEEK_CUR)
              file.write(updated_line)
              file.write(' ' * (original_length - updated_line.length - 1))
              break
            end
          end
        end
      end
    end

    def patch_netinet6_headers(installer)
      Dir.glob(File.join(installer.sandbox.root.to_s, '**', '*.{h,m,mm,c,cc,cpp,hpp}')).each do |path|
        next unless File.file?(path)

        content = File.read(path)
        next unless content.include?('#import <netinet6/in6.h>') ||
                    content.include?('#include <netinet6/in6.h>')

        mode = File.stat(path).mode
        File.chmod(mode | 0o200, path) unless File.writable?(path)

        updated = content
          .gsub('#import <netinet6/in6.h>', '#import <netinet/in.h>')
          .gsub('#include <netinet6/in6.h>', '#include <netinet/in.h>')

        if updated != content
          File.write(path, updated)
          puts "Patched private netinet6 header: #{path}"
        end
      end
    end

    def patch_privacy_resources_script(installer, aggregate_target:, privacy_line_regex:)
      pods_resources_script = File.join(
        installer.sandbox.root.to_s,
        'Target Support Files',
        aggregate_target,
        "#{aggregate_target}-resources.sh"
      )

      return unless File.exist?(pods_resources_script)

      content = File.read(pods_resources_script)
      updated = content.gsub(privacy_line_regex, '')
      File.write(pods_resources_script, updated) if updated != content
    end

    def patch_user_project_copy_pods_resources(installer, aggregate_target:, user_target:, privacy_path_filter:)
      installer.aggregate_targets.each do |aggregate_target_obj|
        next unless aggregate_target_obj.name == aggregate_target

        user_project = aggregate_target_obj.user_project
        next unless user_project

        user_project.targets.each do |ut|
          next unless ut.name == user_target

          ut.shell_script_build_phases.each do |phase|
            next unless phase.name == '[CP] Copy Pods Resources'

            phase.input_paths = phase.input_paths.reject do |path|
              path.include?(privacy_path_filter) && path.include?('PrivacyInfo.xcprivacy')
            end
            phase.output_paths = phase.output_paths.reject do |path|
              path.end_with?('/PrivacyInfo.xcprivacy')
            end
          end
        end

        user_project.save
      end
    end

    def patch_awscore_unistd(installer)
      awscore_source_fixes = {
        File.join(installer.sandbox.root.to_s, 'AWSCore', 'AWSCore', 'FMDB', 'AWSFMDatabase.m') => [
          ['#import "unistd.h"', '#import <unistd.h>']
        ],
        File.join(installer.sandbox.root.to_s, 'AWSCore', 'AWSCore', 'FMDB', 'AWSFMResultSet.m') => [
          ['#import "unistd.h"', '#import <unistd.h>']
        ]
      }

      awscore_source_fixes.each do |path, replacements|
        next unless File.exist?(path)

        content = File.read(path)
        updated = content.dup
        replacements.each do |from, to|
          updated = updated.gsub(from, to)
        end
        next if updated == content

        current_mode = File.stat(path).mode
        File.chmod(current_mode | 0o200, path) unless File.writable?(path)
        File.write(path, updated)
      end
    end
  end
end
