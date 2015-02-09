#!/usr/bin/env ruby

require 'sensu-plugin/metric/cli'
require 'snmp'

class SNMPTrafficMetrics < Sensu::Plugin::Metric::CLI::Graphite

  option :hosts,
    short: '-h HOSTS',
    long: '--hosts HOSTS',
    default: 'localhost,127.0.0.1'

  option :community,
    short: '-c COMMUNITY',
    long: '--community COMMUNITY',
    default: 'public'

  option :sleep,
    long: '--sleep SLEEP',
    proc: proc {|a| a.to_f },
    default: 1

  def get_all_traffic(host, community)
    manager = SNMP::Manager.new host: host, community: community
    i = 1
    traffic = 0

    loop do
      response = manager.get ["1.3.6.1.2.1.2.2.1.10.#{i}"]
      begin
        response.each_varbind { |vb| traffic += vb.value.to_i }
      rescue NoMethodError
        break
      end
      i += 1
    end

    traffic
  end

  def run
    timestamp = Time.now.to_i
    threads = []

    config[:hosts].split(',').each do |host|
      threads << Thread.new do
        net_traffic_before = get_all_traffic(host, config[:community])
        sleep config[:sleep]
        net_traffic_after = get_all_traffic(host, config[:community])

        all_traffic = net_traffic_after - net_traffic_before
        output "#{host}.snmp.all.traffic", all_traffic, timestamp
      end
    end

    threads.each do |thread|
      thread.join
    end

    ok
  end

end
