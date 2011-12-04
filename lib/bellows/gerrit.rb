require 'json'

module Bellows
  class Gerrit

    def self.run_cmd(command)
      return %x{ssh review gerrit #{command}}
    end

    def self.reviews(project, status="open", branch="master")
      reviews = []
      out=Gerrit.run_cmd(%{query "status: #{status}" --current-patch-set --format JSON})
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

  end
end
