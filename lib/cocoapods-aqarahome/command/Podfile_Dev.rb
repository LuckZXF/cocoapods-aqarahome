module Pod
  class Podfile
    module DSL
      require 'cocoapods-aqarahome/Utils/Color'
      public

      def dev_pods(pods, branch = 'aqara')
        if branch.length > 0
          # pods.each do |name|
          #   pod name, :git => "https://xyz.com/ios/#{name}.git", :branch => "#{branch}"
          # end
          pull_latest_code_and_resolve_conflict(pods)
          # puts "lebbay: using remote pods with branch: #{branch}".green
        else
          # 自定义开发目录
          development_path = Config.instance.dev_pods_path
          pods.each do |name|
            pod name, :path => "#{development_path}#{name}"
          end
          puts "lebbay: using local pods with path: #{development_path}xxx".green
        end
      end

      def watch_up
        puts '|========================================================================|'.red
        (0..10).each do |i|
          puts '|                                                                        |'.red unless i == 5
          puts '|                       '.red + '你小子注意更新私有库SDK'.green + '                          |'.red unless i != 5
        end
        puts '|========================================================================|'.red
      end

      #--------------------------------------#

      private

      def pull_latest_code_and_resolve_conflict(pods)
        # 1、Podfile.lock
        puts "正在清理Podfile.lock中私有库的commit信息...".pink
        rewrite_lock_file(pods, Config.instance.lockfile_path)
        puts "Podfile.lock中私有库的commit信息已清除！".light_blue
        # 2、Manifest.lock
        puts "正在清理Manifest.lock中私有库的commit信息...".pink
        rewrite_lock_file(pods, Config.instance.sandbox.manifest_path)
        puts "Manifest.lock中私有库的commit信息已清除！".light_blue
      end

      def rewrite_lock_file(pods, lock_path)
        return unless lock_path.exist?
        lock_hash = Lockfile.from_file(lock_path).to_hash

        # 1、PODS
        lock_pods = lock_hash['PODS']
        if lock_pods
          target_pods = []
          lock_pods.each do |pod|
            if pod.is_a? Hash
              first_key = pod.keys[0]
              first_value = pod.values[0]
              if (first_key.is_a? String) && (first_value.is_a? Array)
                next if is_include_key_in_pods(first_key, pods)
                dep_pods = first_value.reject { |dep_pod| is_include_key_in_pods(dep_pod, pods) }
                target_pods << (dep_pods.count > 0 ? {first_key => dep_pods} : first_key)
                next
              end
            elsif pod.is_a? String
              next if is_include_key_in_pods(pod, pods)
            end
            target_pods << pod
          end
          lock_hash['PODS'] = target_pods
        end

        # 2、DEPENDENCIES
        locak_dependencies = lock_hash['DEPENDENCIES']
        if locak_dependencies
          target_dependencies = []
          locak_dependencies.each do |dependence|
            if dependence.is_a? String
              next if is_include_key_in_pods(dependence, pods)
            end
            target_dependencies << dependence
          end
          lock_hash['DEPENDENCIES'] = target_dependencies
        end

        Lockfile.new(lock_hash).write_to_disk(lock_path)
      end

      def is_include_key_in_pods(target_key, pods)
        pods.each do |pod|
          if target_key.include? pod
            return true
          end
        end
        return false
      end

      #--------------------------------------#
    end
  end
end
