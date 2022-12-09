module Pod
  class Podfile
    module DSL

      public

      def dev_pods(pods, branch = 'aqara')
        if branch.length > 0
          # pods.each do |name|
          #   pod name, :git => "https://xyz.com/ios/#{name}.git", :branch => "#{branch}"
          # end
          pull_latest_code_and_resolve_conflict(pods)
          podStr = pods.join(", ")
          puts "成功清除私有库".green + "#{podStr}".yellow + "的缓存数据".green
          pods.each do |pod|
            args = ['clean',pod]
            Pod::Command::Cache.run(args)
          end
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

      def code_signing_allow_no!
        post_install do |installer|
          installer.pods_project.targets.each do |target|
            if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
              target.build_configurations.each do |config|
                config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
              end
            end
          end
        end
      end

      #--------------------------------------#

      private

      def pull_latest_code_and_resolve_conflict(pods)
        # 1、Podfile.lock
        puts "正在清理Podfile.lock中私有库的commit信息..."
        rewrite_lock_file(pods, Config.instance.lockfile_path)
        puts "Podfile.lock中私有库的commit信息已清除！".green
        # 2、Manifest.lock
        puts "正在清理Manifest.lock中私有库的commit信息..."
        rewrite_lock_file(pods, Config.instance.sandbox.manifest_path)
        puts "Manifest.lock中私有库的commit信息已清除！".green
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
