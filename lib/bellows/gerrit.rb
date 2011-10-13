require 'json'

module Bellows
  class Gerrit

    def self.reviews(project, status="open")
      reviews = []
      out=%x{ssh review gerrit query "status: #{status}" --current-patch-set --format JSON}
      out.each_line do |line|
        data = JSON.parse(line)
        if data['project'] and data['project'] == "openstack/#{project}"
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
