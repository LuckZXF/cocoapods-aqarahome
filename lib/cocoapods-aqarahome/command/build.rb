
module Pod
  class Command
    class Build < Command
      self.summary = 'A custom build command'
      self.description = 'This is a custom build command to do something specific.'
      def initialize(argv)
        @envs = []

        # 循环直到没有更多非选项参数
        while (arg = argv.shift_argument)
          @envs << "#{arg}=0"
        end
        super
      end

      def run
        system("#{@envs.join(' ')} pod install")
      end
    end
  end
end
