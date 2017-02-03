module VirtFS
  module Activation
    def activate_mutex
      @activate_mutex ||= Mutex.new
    end

    def activated?
      @activated
    end

    def activate!(enable_require = false)
      activate_mutex.synchronize do
        raise "VirtFS.activate! already activated" if @activated
        @activated = true

        Object.class_eval do
          remove_const(:Dir)
          remove_const(:File)
          remove_const(:IO)
          remove_const(:Pathname)

          const_set(:Dir,      VirtFS::VDir)
          const_set(:File,     VirtFS::VFile)
          const_set(:IO,       VirtFS::VIO)
          const_set(:Pathname, VirtFS::VPathname)
        end

        if enable_require
          VirtFS::Kernel.inject
          VirtFS::Kernel.enable
        end
      end
      true
    end

    def deactivate!
      activate_mutex.synchronize do
        raise "VirtFS.deactivate! not activated" unless @activated
        @activated = false

        Object.class_eval do
          remove_const(:Dir)
          remove_const(:File)
          remove_const(:IO)
          remove_const(:Pathname)

          const_set(:Dir,      VfsRealDir)
          const_set(:File,     VfsRealFile)
          const_set(:IO,       VfsRealIO)
          const_set(:Pathname, VfsRealPathname)
        end
        VirtFS::Kernel.disable
      end
      true
    end

    def with(enable_require = false)
      if activated?
        yield
      else
        begin
          activate!(enable_require)
          yield
        ensure
          deactivate!
        end
      end
    end

    def without
      if !activated?
        yield
      else
        begin
          deactivate!
          yield
        ensure
          activate!
        end
      end
    end
  end
end
