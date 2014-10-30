#!/usr/bin/env ruby
# Sensu Network Traffic Metrics Handler

require 'sensu-plugin/metric/cli'
require 'socket'

class LinuxPacketMetrics < Sensu::Plugin::Metric::CLI::Graphite

  option :scheme,
    description: 'Metric naming scheme, text to prepend to metric',
    short: '-s SCHEME',
    long: '--scheme SCHEME',
    default: "#{Socket.gethostname}.net"

  option :sleep,
    long: '--sleep SLEEP',
    proc: proc {|a| a.to_f },
    default: 1

  def get_net_stats
    ifaces = {}

    Dir.glob('/sys/class/net/*').each do |iface_path|
      next if File.file? iface_path
      iface = File.basename iface_path
      next if iface == 'lo'

      traffic = 0
      traffic += File.open(iface_path + '/statistics/tx_bytes').read.to_i
      traffic += File.open(iface_path + '/statistics/rx_bytes').read.to_i
      ifaces[iface] = traffic
    end

    ifaces
  end

  def run
    timestamp = Time.now.to_i

    net_stats_before = get_net_stats
    sleep config[:sleep]
    net_stats_after = get_net_stats

    net_stats_after.each do |iface, traffic|
      diff = traffic - net_stats_before[iface]
      output "#{config[:scheme]}.#{iface}.traffic_bytes", diff, timestamp
    end

    ok
  end

end
