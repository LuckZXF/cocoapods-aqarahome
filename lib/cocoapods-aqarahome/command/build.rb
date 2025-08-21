
module Pod
  class Command
    class Build < Command
      self.summary = 'A custom build command'
      self.description = 'Custom build with envs and plugin adjustments.'

      def initialize(argv)
        @envs = []
        while (arg = argv.shift_argument)
          @envs << "#{arg}=1"
        end
        super
      end

      def run
        # 设置环境变量
        @envs.each do |env|
          key, val = env.split('=')
          ENV[key] = val
          UI.puts "当前环境变量 #{key}=#{val}"
        end

        podfile = Pod::Config.instance.podfile

        if podfile.plugins.key?('cocoapods-aqara-localzedLoader')
          UI.puts "跳过多语言下载和更新过程".yellow
          podfile.plugins.delete('cocoapods-aqara-localzedLoader')
        end

        install_cmd = Pod::Command::Install.new(CLAide::ARGV.new([]))
        install_cmd.run

        podfile.plugins['cocoapods-aqara-localzedLoader'] = {}
      end
    end
  end
end
