#!/usr/bin/env ruby

require 'sensu-plugin/metric/cli'
require 'socket'

class MemoryMetricsPercent < Sensu::Plugin::Metric::CLI::Graphite

  option :scheme,
    :description => "Metric naming scheme, text to prepend to metric",
    :short => "-s SCHEME",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.memory_percent"

  def run
    mem = metrics_hash

    mem.each do |k, v|
      output "#{config[:scheme]}.#{k}", v
    end

    ok
  end

  def metrics_hash
    mem = {}
    memp = {}

    meminfo_output.each_line do |line|
      mem['total']     = line.split(/\s+/)[1].to_i * 1024 if line.match(/^MemTotal/)
      mem['free']      = line.split(/\s+/)[1].to_i * 1024 if line.match(/^MemFree/)
      mem['buffers']   = line.split(/\s+/)[1].to_i * 1024 if line.match(/^Buffers/)
      mem['cached']    = line.split(/\s+/)[1].to_i * 1024 if line.match(/^Cached/)
    end

    mem['used'] = mem['total'] - mem['free']
    mem['usedWOBuffersCaches'] = mem['used'] - (mem['buffers'] + mem['cached'])

    memp['usedWOBuffersCaches'] = 100.0 * mem['usedWOBuffersCaches'] / mem['total']
    memp
  end

  def meminfo_output
    File.open("/proc/meminfo", "r")
  end
end
