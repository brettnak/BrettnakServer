require 'net/ssh'
require 'highline'
require 'yaml'
require 'ostruct'

module Chair

  class Deployer
    attr_accessor :config, :session

    def initialize( config_yaml )
      config = OpenStruct.new( YAML::load_file( config_yaml ) )
      self.session = Chair::Session.new( config.host, config.user )
    end
  end

  class RemoteFileUtils
    def self.copy( from, to, options = {} )
      flags = options[:flags] || ""

      if options[:sudo]
        self.session.sudo( "cp #{flags} #{from} #{to}" )
      else
        self.session.run( "cp #{flags} #{from} #{to}" )
      end
    end
  end

  class Session
    attr_accessor :ssh_session, :host, :user, :highline

    def initialize( host, user )
      self.host = host
      self.user = user
      self.highline = HighLine.new
    end

    def with_session
      if self.ssh_session.nil?
        self.ssh_session = Net::SSH.start( self.host, self.user )
        self.ssh_session.loop
      end

      return self.ssh_session
    end

    def close_session
      self.ssh_session.close
      self.ssh_session = nil
    end

    def sudo( command )
      with_session

      command = "sudo sh -c '#{command}'"
      self.highline.say( "[COMMAND #{self.host}] Executing: #{command}" )

      self.ssh_session.open_channel do |channel|
        channel.exec( command ) do |channel, success|

          channel.on_extended_data do |ch, status, data|
            if data =~ /password/ || data =~ /Sorry, try again/
              password = self.highline.ask("[PROMPT #{self.host}]: #{data} ") { |q| q.echo = false }
              ch.send_data( password + "\n" )
            else
              self.highline.say("[ERROR  #{self.host}]: #{data}" )
            end
          end

          channel.on_data do |ch, data|
            self.highline.say( "[STDOUT #{self.host}]: " + data )
          end
        end

        channel.wait
      end
    end

    def run( command )
      with_session

      command = "sh -c '#{command}'"
      self.highline.say( "[COMMAND #{self.host}] Executing: #{command}" )

      ssh_session.open_channel do |channel|
        channel.exec( command ) do |channel, success|
          channel.on_extended_data do |ch, status, data|
            self.highline.say("[ERROR  #{self.host}]: #{data}" )
          end

          channel.on_data do |channel, data|
            self.highline.say("[STDOUT #{self.host}]: #{data}" )
          end
        end

        channel.wait
      end
    end

    def close
      self.ssh_session.close
    end
  end
end


if __FILE__ == $0
  session = Chair::Session.new( "brettnak.com", "brettnak" )
  session.sudo( "echo sudo" )
  session.run(  "echo user" )
  session.close
end
