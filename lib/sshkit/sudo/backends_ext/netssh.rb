# require 'net/ssh'
require 'sshkit'
# require 'sshkit/backend/netssh'

module SSHKit
  module Backend

    class Netssh < Printer
      def sudo(*args)
        _sudo(*args).success?
      end

      private

      def _sudo(*args)
        command(:sudo, *args).tap do |cmd|
          output << cmd
          cmd.started = true
          exit_status = nil
          with_ssh do |ssh|
            ssh.open_channel do |chan|
              chan.request_pty
              chan.exec cmd.to_command do |ch, success|
                chan.on_data do |ch, data|
                  cmd.stdout = data
                  cmd.full_stdout += data
                  output << cmd

                  if data =~ /password.*:/
                    pass = $stdin.noecho(&:gets)
                    ch.send_data(pass)
                  end
                end
                chan.on_extended_data do |ch, type, data|
                  cmd.stderr = data
                  cmd.full_stderr += data
                  output << cmd
                end
                chan.on_request("exit-status") do |ch, data|
                  exit_status = data.read_long
                end
                #chan.on_request("exit-signal") do |ch, data|
                #  # TODO: This gets called if the program is killed by a signal
                #  # might also be a worthwhile thing to report
                #  exit_signal = data.read_string.to_i
                #  warn ">>> " + exit_signal.inspect
                #  output << cmd
                #end
                chan.on_open_failed do |ch|
                  # TODO: What do do here?
                  # I think we should raise something
                end
                chan.on_process do |ch|
                  # TODO: I don't know if this is useful
                end
                chan.on_eof do |ch|
                  # TODO: chan sends EOF before the exit status has been
                  # writtend
                end
              end
              chan.wait
            end
            ssh.loop
          end
          # Set exit_status and log the result upon completion
          if exit_status
            cmd.exit_status = exit_status
            output << cmd
          end
        end
      end
    end
  end

end
