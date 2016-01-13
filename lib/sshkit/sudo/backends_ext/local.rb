module SSHKit
  module Backend
    class Local < Abstract
      def sudo(*args)
        _execute(:sudo, *args).success?
      end

      alias execute! execute
    end
  end
end
