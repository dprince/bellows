require 'json'
require 'pty'

module Bellows
  class Gerrit

    def self.run_cmd(command)
      return %x{ssh review gerrit #{command}}
    end

    #defined here so we can easily stub out for testing
    def self.stream_events_cmd
      return "ssh review gerrit stream-events"
    end

    def self.reviews(project, status="open", branch="master")
      reviews = []
      out=Gerrit.run_cmd(%{query status:#{status} project:openstack/#{project} branch:#{branch} limit:500 --current-patch-set --format JSON})
      out.each_line do |line|
        data = JSON.parse(line)
        if data['project'] and data['project'] == "openstack/#{project}" and data['branch'] and data['branch'] == branch
          if block_given?
            yield data
          else
            reviews << data 
          end
        end
      end
      reviews
    end

    def self.comment(revision, message, verify_vote=0)
      Gerrit.run_cmd(%{review --verified #{verify_vote} -m \"'#{message}'\" #{revision}})
    end

    def self.stream_events(type=nil)

      PTY.spawn stream_events_cmd do |read, write, pid|
        loop do
          begin
            data = JSON.parse(read.gets)
            if type.nil? or data['type'] == type then
              yield data
            end
          rescue
            break
          end
        end
      end

    end

  end
end
