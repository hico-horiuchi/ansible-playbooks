#!/usr/bin/env ruby

require 'sensu-plugin/metric/cli'
require 'socket'

class NetTrafficMetrics < Sensu::Plugin::Metric::CLI::Graphite

  option :scheme,
    description: 'Metric naming scheme, text to prepend to metric',
    short: '-s SCHEME',
    long: '--scheme SCHEME',
    default: "#{Socket.gethostname}.net"

  option :sleep,
    long: '--sleep SLEEP',
    proc: proc {|a| a.to_f },
    default: 1

  def get_all_traffic
    traffic = 0

    Dir.glob('/sys/class/net/*').each do |iface_path|
      next if File.file? iface_path
      iface = File.basename iface_path
      next if iface == 'lo'

      stats = {}
      stats[:tx_bytes] = File.open(iface_path + '/statistics/tx_bytes').read.to_i
      stats[:rx_bytes] = File.open(iface_path + '/statistics/rx_bytes').read.to_i
      traffic += stats[:tx_bytes] + stats[:rx_bytes]
    end

    traffic
  end

  def run
    timestamp = Time.now.to_i

    net_traffic_before = get_all_traffic
    sleep config[:sleep]
    net_traffic_after = get_all_traffic

    all_traffic = net_traffic_after - net_traffic_before
    output "#{config[:scheme]}.all.traffic", all_traffic, timestamp

    ok
  end

end
