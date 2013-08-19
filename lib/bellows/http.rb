require 'uri'
require 'net/http'
require 'net/https'
require 'openssl'
require 'openssl/x509'
require 'bellows/util'

module Net
  module HTTPHeader

    def set_form_data(params, sep = '&')
      query = URI.encode_www_form(params)
      query.gsub!(/&/, sep) if sep != '&'
      self.body = query
      self.content_type = 'application/x-www-form-urlencoded'
    end
    alias form_data= set_form_data

  end
end

module URI

  def self.encode_www_form(enum)
    enum.map do |k,v|
      if v.nil?
        k
      elsif v.respond_to?(:to_ary)
        v.to_ary.map do |w|
          str = k.dup
          unless w.nil?
            str << '='
            str << w
          end
        end.join('&')
      else
        str = k.dup
        str << '='
        str << v.to_s.gsub("%", "%25")
      end
    end.join('&')
  end

end

module Bellows
  class HTTP

  MULTI_PART_BOUNDARY="jtZ!pZ1973um"

    @@http=nil
    @@auth_user=nil
    @@auth_password=nil

    def self.init_connection

      configs=Util.load_configs

      base_url = configs["smokestack_url"]
      @@auth_user = configs["smokestack_username"]
      @@auth_password = configs["smokestack_password"]

      ssl_key = configs["ssl_key"]
      ssl_cert = configs["ssl_cert"]
      ssl_ca_cert = configs["ssl_ca_cert"]

      url=URI.parse(base_url)
      @@http = Net::HTTP.new(url.host,url.port)

      if base_url =~ /^https/
        @@http.use_ssl = true
        if ssl_ca_cert then
          @@http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        else
          @@http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        if ssl_key then
          pkey_data=IO.read(ssl_key)
          if pkey_data =~ /^-----BEGIN RSA PRIVATE KEY-----/
            @@http.key=OpenSSL::PKey::RSA.new(pkey_data)
          else
            @@http.key=OpenSSL::PKey::DSA.new(pkey_data)
          end
        end
        @@http.cert=OpenSSL::X509::Certificate.new(IO.read(ssl_cert)) if ssl_cert
        @@http.ca_file=ssl_ca_cert if ssl_ca_cert
      end

    end

    def self.file_upload(url_path, file_data={}, post_data={})
      init_connection if @@http.nil?
      req = Net::HTTP::Post.new(url_path)

      post_arr=[]
      post_data.each_pair do |key, value|
        post_arr << "--#{MULTI_PART_BOUNDARY}\r\n"
        post_arr << "Content-Disposition: form-data; name=\"#{key}\"\r\n"
        post_arr << "\r\n"
        post_arr << value
        post_arr << "\r\n"
      end

      file_data.each_pair do |name, file|
        post_arr << "--#{MULTI_PART_BOUNDARY}\r\n"
        post_arr << "Content-Disposition: form-data; name=\"#{name}\"; filename=\"#{File.basename(file)}\"\r\n"
        post_arr << "Content-Type: text/plain\r\n"
        post_arr << "\r\n"
        post_arr << File.read(file)
        post_arr << "\r\n--#{MULTI_PART_BOUNDARY}--\r\n"
      end
      post_arr << "--#{MULTI_PART_BOUNDARY}--\r\n\r\n"

      req.body=post_arr.join

      req.basic_auth @@auth_user, @@auth_password if @@auth_user and @@auth_password
      req["Content-Type"] = "multipart/form-data, boundary=#{MULTI_PART_BOUNDARY}"

      response = @@http.request(req)
      case response
      when Net::HTTPSuccess
        return response.body
      else
        puts response.body
        response.error!
      end
    end

    def self.post(url_path, post_data)
      init_connection if @@http.nil?
      req = Net::HTTP::Post.new(url_path)
      if post_data.kind_of?(String) then
        req.body=post_data
      elsif post_data.kind_of?(Hash) then
        req.form_data=post_data
      else
        raise "Invalid post data type."
      end
      req.basic_auth @@auth_user, @@auth_password if @@auth_user and @@auth_password
      response = @@http.request(req)
      case response
      when Net::HTTPSuccess
        return response.body
      when Net::HTTPRedirection
        return response['location']
      else
        puts response.body
        response.error!
      end
    end

    def self.put(url_path, put_data)
      init_connection if @@http.nil?
      req = Net::HTTP::Put.new(url_path)
      if put_data.kind_of?(String) then
        req.body=put_data
      elsif put_data.kind_of?(Hash) then
        req.form_data=put_data
      else
        raise "Invalid put data type."
      end
      req.basic_auth @@auth_user, @@auth_password if @@auth_user and @@auth_password
      response = @@http.request(req)
      case response
      when Net::HTTPSuccess
        return response.body
      when Net::HTTPRedirection
        return response['location']
      else
        puts response.body
        response.error!
      end
    end

    def self.get(url_path)
      init_connection if @@http.nil?
      req = Net::HTTP::Get.new(url_path)
      req.basic_auth @@auth_user, @@auth_password if @@auth_user and @@auth_password
      response = @@http.request(req)
      case response
      when Net::HTTPSuccess
        return response.body
      else
        response.error!
      end
    end

    def self.delete(url_path)
      init_connection if @@http.nil?
      req = Net::HTTP::Delete.new(url_path)
      req.basic_auth @@auth_user, @@auth_password if @@auth_user and @@auth_password
      response = @@http.request(req)
      case response
      when Net::HTTPSuccess
        return response.body
      when Net::HTTPRedirection
        return response['location']
      else
        response.error!
      end
    end

  end
end
