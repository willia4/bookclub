require 'aws-sdk-core'
require 'securerandom'
require 'open-uri'
require 'net/http'

module Database
  module S3
    def self.get_database_client
      if $s3_client.nil?
        config = $config[:aws][:s3]

        $s3_client = Aws::S3::Client.new(
            region: config[:region],
            access_key_id: config[:access_key],
            secret_access_key: config[:secret])
      end

      return $s3_client
    end

    def self.list_buckets
      s3 = get_database_client
      pages = s3.list_buckets
      buckets = []

      pages.each do |page|
        buckets.concat(page.data.buckets.map { |b| b.name })
      end

      return buckets
    end

    def self.upload_url url, file_extension = nil
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      request = Net::HTTP::Head.new(uri.request_uri)
      response = http.request(request)

      content_type = nil
      content_type = response.content_type if response.code == "200"

      io_object = open(url)

      return upload_io_object io_object, file_extension, content_type
    end

    def self.upload_io_object(io_object, file_extension, content_type)
      s3 = get_database_client
      if !file_extension.nil? && file_extension != ""
        file_extension = "." + file_extension unless file_extension.start_with?(".")
      else
        file_extension = ""
      end

      key = SecureRandom.hex(12) + file_extension

      if !content_type.nil? && content_type != ""
        s3.put_object(content_type: content_type, acl: "public-read", bucket: $config[:aws][:s3][:bucket], body: io_object, key: key)
      else
        s3.put_object(acl: "public-read", bucket: $config[:aws][:s3][:bucket], body: io_object, key: key)
      end

      return "http://#{$config[:aws][:s3][:bucket]}.s3.amazonaws.com/#{key}"
    end
  end
end