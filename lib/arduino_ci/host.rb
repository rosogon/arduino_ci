require 'os'
require 'open3'
require 'pathname'

module ArduinoCI

  # Tools for interacting with the host machine
  class Host
    # Cross-platform way of finding an executable in the $PATH.
    # via https://stackoverflow.com/a/5471032/2063546
    #   which('ruby') #=> /usr/bin/ruby
    # @param cmd [String] the command to search for
    # @return [String] the full path to the command if it exists
    def self.which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      nil
    end

    def self.run_and_capture(*args, **kwargs)
      stdout, stderr, status = Open3.capture3(*args, **kwargs)
      { out: stdout, err: stderr, success: status.exitstatus.zero? }
    end

    def self.run_and_output(*args, **kwargs)
      system(*args, **kwargs)
    end

    # return [Symbol] the operating system of the host
    def self.os
      return :osx if OS.osx?
      return :linux if OS.linux?
      return :windows if OS.windows?
    end

    # if on windows, call mklink, else self.symlink
    # @param [Pathname] old_path
    # @param [Pathname] new_path
    def self.symlink(old_path, new_path)
      return FileUtils.ln_s(old_path.to_s, new_path.to_s) unless RUBY_PLATFORM =~ /mswin32|cygwin|mingw|bccwin/

      # https://stackoverflow.com/a/22716582/2063546
      # windows mklink syntax is reverse of unix ln -s
      # windows mklink is built into cmd.exe
      # vulnerable to command injection, but okay because this is a hack to make a cli tool work.
      orp = old_path.realpath.to_s.tr("/", "\\") # HACK DUE TO REALPATH BUG where it
      np = new_path.to_s.tr("/", "\\")           # still joins windows paths with '/'

      _stdout, _stderr, exitstatus = Open3.capture3('cmd.exe', "/C mklink /D #{np} #{orp}")
      exitstatus.success?
    end
  end
end
