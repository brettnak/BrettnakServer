#!/usr/bin/env ruby

require File.join( File.dirname( __FILE__ ), "lib", "deployer" ).to_s

module Brettnak
  class Deployer < Chair::Deployer

    # We assume you know what to do...
    def deploy
      update_git
      copy_files
      link_nginx_sites
      restart_all_server_processes
      check_syntax
    end

    def check_syntax
      session.sudo( "nginx -t")
    end

    def restart_all_server_processes
      session.sudo( "kill -s USR2 `cat /tmp/nginx.pid`" )
      session.sudo( "kill -s USR2 `cat /tmp/thecarelesslovers-unicorn.pid`" )
      # session.sudo( "kill -s USR2 `cat /tmp/brettnak-unicorn.pid`" )
    end

    def link_nginx_sites
      Chair::RemoteFileUtils.link(
        "/etc/nginx/sites-available/thecarelesslovers.com.conf",
        "/etc/nginx/sites-enabled/thecarelesslovers.com.conf",
        :sudo => true,
        :session => self.session
       )

      # Chair::RemoteFileUtils.link(
      #   "/etc/nginx/sites-available/brettnak.com.conf",
      #   "/etc/nginx/sites-enabled/brettnak.com.conf",
      #   :sudo => true,
      #   :session => self.session
      #  )       
    end

    def copy_files
      self.config.config_files.each do |elem|

        from  = "#{config.working_server_directory}/#{elem['from']}"
        to    = elem['to']
        sudo  = elem['sudo']

        if sudo
          Chair::RemoteFileUtils.copy( from, to, :session => self.session, :sudo => true, :flags => "-fv" )
        else
          Chair::RemoteFileUtils.copy( from, to, :session => self.session, :flags => "-fv" )
        end
      end
    end

    def setup
      session.run( "mkdir -p #{config.working_server_directory}" )
      session.run( "git clone #{config.repository_url} #{config.working_server_directory}" )

      # make sure this is setup
      session.run( "cd #{config.working_server_directory} && git remote add origin #{config.repository_url}" )
    end

    def update_git
      session.run( "cd #{config.working_server_directory} && git pull origin master" )
    end

    def test
      session.sudo( "echo \"ran as sudoer\"" )
      session.run( "echo \"ran as user\"" )
      session.close
    end
  end
end

deployer = Brettnak::Deployer.new( "config.yaml" )
cmd = ARGV[0] || "deploy"
deployer.__send__( cmd.to_sym )





