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

      stats = {}
      stats[:tx_bytes] = File.open(iface_path + '/statistics/tx_bytes').read.to_i
      stats[:rx_bytes] = File.open(iface_path + '/statistics/rx_bytes').read.to_i
      stats[:traffic] = stats[:tx_bytes] + stats[:rx_bytes]
      ifaces[iface] = stats
    end

    ifaces
  end

  def run
    timestamp = Time.now.to_i

    net_stats_before = get_net_stats
    sleep config[:sleep]
    net_stats_after = get_net_stats

    all = 0
    net_stats_after.each do |iface, stats|
      stats.each do |key, value|
        diff = value - net_stats_before[iface][key]
        output "#{config[:scheme]}.#{iface}.#{key}", diff, timestamp
        all += diff if key == :traffic
      end
    end
    output "#{config[:scheme]}.all.traffic", all, timestamp

    ok
  end

end
