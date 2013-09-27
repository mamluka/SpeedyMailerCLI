#!/usr/bin/env ruby
require 'thor'
require 'net/ssh'
require 'net/http'

class Bootstrap < Thor
  desc 'bootstrap droneIp dronePassword ', 'Bootstraps a drone using SSH'

  def bootstrap(drone_ip, password)
    master_ip = Net::HTTP.get(URI.parse('http://ipecho.net/plain'))
    p "Found master ip to be: #{master_ip}"

    drone_domain = `/usr/bin/dig +noall +answer -x #{drone_ip} | awk '{$5=substr($5,1,length($5)-1); print $5}' | tr  -d '\n'`

    'Reverse dns must be setup' if drone_domain.nil?

    p "Found reverse dns for drone at #{drone_domain}"

    Net::SSH.start(drone_ip, 'root', :password => password) do |ssh|
      p 'Install curl'
      p ssh.exec! 'apt-get update && apt-get install curl -y'
      p 'Creating drone user'
      p ssh.exec! "curl -L 'http://#{master_ip}:8080/create-drone' | bash"
      p 'Switching to drone user'
    end

    Net::SSH.start(drone_ip, 'drone', :password => password) do |ssh|

      p 'Running install script'

      channel = ssh.open_channel do |ch|
        channel.request_pty do |ch, success|
          raise "I can't get pty request" unless success

          ch.exec "\\curl -L 'http://#{master_ip}:8080/install?droneDomain=#{drone_domain}&masterDomain=#{master_ip}' | bash" do |ch, success|
            raise 'could not execute command' unless success

            ch.on_data do |c, data|
              if data.inspect.include?('[sudo]') || data.inspect.include?('password required for')
                channel.send_data("#{password}\n")
                sleep 1
              end
              $stdout.print data
            end

            ch.on_extended_data do |c, type, data|
              $stderr.print data
            end

            ch.on_close { puts 'Drone is bootstrapped' }
          end
        end
      end
      channel.wait
    end
  end

  desc 'update_node droneIp dronePassword', 'Update code for a given drone includes a restart'

  def update_node(drone_ip, password)
    Net::SSH.start(drone_ip, 'drone', :password => password) do |ssh|

      p 'Running update script'

      channel = ssh.open_channel do |ch|
        channel.request_pty do |ch, success|
          raise "I can't get pty request" unless success

          ch.exec 'bash ~/SpeedyMailerCLI/update-node.sh' do |ch, success|
            raise 'could not execute command' unless success

            ch.on_data do |c, data|
              if data.inspect.include?('[sudo]') || data.inspect.include?('password required for')
                channel.send_data("#{password}\n")
                sleep 1
              end
              $stdout.print data
            end

            ch.on_extended_data do |c, type, data|
              $stderr.print data
            end

            ch.on_close { puts 'Node is updated and running' }
          end
        end
      end
      channel.wait
    end
  end

  desc 'update_code  droneIp dronePassword', 'Update code for a given drone includes a restart'

  def update_code(drone_ip, password)

    Net::SSH.start(drone_ip, 'drone', :password => password) do |ssh|

      p 'Running update script'

      channel = ssh.open_channel do |ch|
        channel.request_pty do |ch, success|
          raise "I can't get pty request" unless success

          ch.exec 'cd SpeedyMailerCLI && bash update-drone.sh' do |ch, success|
            raise 'could not execute command' unless success

            ch.on_data do |c, data|
              if data.inspect.include?('[sudo]') || data.inspect.include?('password required for')
                channel.send_data("#{password}\n")
                sleep 1
              end
              $stdout.print data
            end

            ch.on_extended_data do |c, type, data|
              $stderr.print data
            end

            ch.on_close { puts 'Drone is updated and running' }
          end
        end
      end
      channel.wait
    end
  end

  desc 'stop droneIp dronePassword', 'Stop service for that drone'

  def stop(drone_ip, password)

    Net::SSH.start(drone_ip, 'drone', :password => password) do |ssh|

      p 'Stopping drone'

      channel = ssh.open_channel do |ch|
        channel.request_pty do |ch, success|
          raise "I can't get pty request" unless success

          ch.exec 'tmux kill-session -t drone' do |ch, success|
            raise 'could not execute command' unless success

            ch.on_data do |c, data|
              if data.inspect.include?('[sudo]') || data.inspect.include?('password required for')
                channel.send_data("#{password}\n")
                sleep 1
              end
              $stdout.print data
            end

            ch.on_extended_data do |c, type, data|
              $stderr.print data
            end

            ch.on_close { puts 'Drone is stopped' }
          end
        end
      end
      channel.wait
    end

  end

end

Bootstrap.start
