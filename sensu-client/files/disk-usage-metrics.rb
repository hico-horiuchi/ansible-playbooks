#!/usr/bin/env ruby

require 'sensu-plugin/metric/cli'
require 'socket'

class DiskUsageMetrics < Sensu::Plugin::Metric::CLI::Graphite

  option :scheme,
         :description => 'Metric naming scheme, text to prepend to .$parent.$child',
         :long => '--scheme SCHEME',
         :default => "#{Socket.gethostname}.disk_usage"

  option :flatten,
         :description => 'Output mounts with underscore rather than dot',
         :short => '-f',
         :long => '--flatten',
         :boolean => true,
         :default => false

  def run
    delim = config[:flatten] == true ? '_' : '.'

    `df -lP`.split("\n").drop(1).each do |line|
      _, _, _, _, used_p, mnt = line.split

      unless %r{/sys|/dev|/run}.match(mnt)
        if config[:flatten]
          mnt = mnt.eql?('/') ? 'root' : mnt.gsub(/^\//, '')
        else
          mnt = mnt.length == 1 ? 'root' : mnt.gsub(/^\//, 'root.')
        end

        mnt = mnt.gsub '/', delim
        output [config[:scheme], mnt, 'used_percentage'].join('.'), used_p.gsub('%', '')
      end
    end
    ok
  end
end
