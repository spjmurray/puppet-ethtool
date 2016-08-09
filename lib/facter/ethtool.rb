module Ethtool
  module Facts

    # Check whether ethtool exists
    def self.exists?
      File.exists?('/sbin/ethtool')
    end

    # Run ethtool on an interface
    def self.ethtool interface
      %x{/sbin/ethtool #{interface} 2>/dev/null}
    end

    # Get all interfaces on the system
    def self.interfaces
      Dir.foreach('/sys/class/net').reject{|x| x.start_with?('.', 'veth')}
    end

    # Convert raw interface names into a canonical version
    def self.alphafy str
      str.gsub(/[^a-z0-9_]/i, '_')
    end

    # Get a hash of interfaces and speeds
    def self.speeds
      self.interfaces.inject({}) do |speeds, interface|
        speedline = self.ethtool(interface).split("\n").detect{|x| x.include?('Speed:')}
        speed = speedline && speedline.scan(/\d+/).first
        next speeds unless speed
        speeds[interface] = speed
        speeds
      end
    end

    # Get a hash of interfaces and maximum speeds
    def self.max_speeds
      self.interfaces.inject({}) do |max_speeds, interface|
        linkmodes = self.ethtool(interface).scan(/Supported link modes:[^:]*/m).first
        max_speed = linkmodes && linkmodes.scan(/\d+/).map(&:to_i).max
        next max_speeds unless max_speed
        max_speeds[interface] = max_speed.to_s
        max_speeds
      end
    end

    # Gather all facts
    def self.facts
      # Ethtool isn't installed, don't collect facts
      return if ! self.exists?

      # Interface speeds
      self.speeds.each do |interface, speed|
        Facter.add('speed_' + self.alphafy(interface)) do
          confine :kernel => 'Linux'
          setcode do
            speed
          end
        end
      end

      # Maximum interface speeds
      self.max_speeds.each do |interface, max_speed|
        Facter.add('maxspeed_' + self.alphafy(interface)) do
          confine :kernel => 'Linux'
          setcode do
            max_speed
          end
        end
      end
    end

  end
end

Ethtool::Facts.facts
