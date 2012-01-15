#!/usr/bin/env ruby

require File.join( File.dirname( __FILE__ ), "lib", "deployer" ).to_s

module Brettnak
  class Deployer < Chair::Deployer

    # We assume you know what to do...
    def deploy
      update_git
      copy_files
      restart_all_server_processes
    end

    def restart_all_server_processes
      session.sudo( "/usr/bin/nginx -s usr2" )
      session.sudo( "kill -S USR2 `cat /tmp/thecarelesslovers-unicorn.pid`" )
      session.sudo( "kill -S USR2 `cat /tmp/brettnak-unicorn.pid`" )
    end

    def copy_files
      self.config.config_files.each_pair do |from, to|
        parts = from.split( "::" )
        from  = "#{config.working_server_directory}/#{parts.last}"

        if parts.first == "sudo"
          RemoteFileUtils.copy( from, to, :sudo => true, :flags => "-f" )
        else
          RemoteFileUtils.copy( from, to, :flags => "-f" )
        end
      end
    end

    def setup
      session.run( "mkdir -p #{config.working_server_directory}" )
      session.run( "git clone #{config.repository_url} #{config.working_server_directory}" )

      # make sure this is setup
      session.run( "cd #{working_server_directory} && git remote add origin #{config.repository_url}" )
    end

    def update_git
      session.run( "cd #{working_server_directory} && git pull origin master" )
    end
  end
end

deployer = Brettnak::Deployer.new( "config.yaml" )
cmd = ARGV[0]
deployer.__send__( cmd.to_sym )
