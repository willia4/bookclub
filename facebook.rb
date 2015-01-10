module Facebook
  def self.login_finish_redirect_url
    return URI.join($config[:general][:base_url], '/signin/facebook/finish').to_s
  end

  class FacebookAPIError < StandardError
  end

  def self.make_graph_api_call(endpoint: nil, parameters: {})
    raise ArgumentError, "Endpoint not specified" if endpoint.nil? or endpoint.length <= 0

    url = "https://graph.facebook.com"
    url = URI.join(url, endpoint)

    if parameters
      query = URI.encode_www_form parameters
      url.query = query 
    end

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url.request_uri)
    response = http.request(request)

    if response.code != "200"
      body = JSON.parse(response.body)
      message = body["error"]["message"]
      message = "Tried to access #{url} \n\n Got Error #{message}"

      raise FacebookAPIError, message
    end

    originalException = nil
    body = response.body 
    response = nil

    begin
      response = JSON.parse(body)
    rescue JSON::ParserError => json_error
      begin 
        response = Rack::Utils.parse_nested_query(body)
      rescue query_error
        message = "Could not parse response from Facebook API \n\n"
        message = message + "When trying to parse as JSON, got: #{json_error.message}"
        message = message + "\n\n"
        message = message + "When trying to parse as a query string, got: #{query_error.message}"

        raise FacebookAPIError, message
      end
    end

    return response
  end

  def self.get_app_token
    if $facebook_app_token.nil?
      response = make_graph_api_call  endpoint: "/oauth/access_token",
                      parameters: {
                        "client_id" => $config[:facebook][:app_id].to_s,
                        "client_secret" => $config[:facebook][:secret].to_s,
                        "grant_type" => "client_credentials"
                      }

      $facebook_app_token = response["access_token"]
    end

    return $facebook_app_token
  end

  def self.get_facebook_token_from_code(code)
    response = make_graph_api_call  endpoint: "/oauth/access_token", 
                    parameters: {
                        "client_id" => $config[:facebook][:app_id].to_s,
                        "redirect_uri" => login_finish_redirect_url,
                        "client_secret" => $config[:facebook][:secret].to_s,
                        "code" => code
                      }

    if !response.has_key? "access_token"
      raise FacebookAPIError, "Could not retrieve user token from Facebook."
    end

    short_lived_token = response["access_token"]

    response = make_graph_api_call  endpoint: "/oauth/access_token",
                    parameters: {
                      "grant_type" => "fb_exchange_token",
                      "client_id" => $config[:facebook][:app_id].to_s,
                      "client_secret" => $config[:facebook][:secret].to_s,
                      "fb_exchange_token" => short_lived_token
                    }

    return response["access_token"]
  end

  def self.inspect_facebook_token token
    bio = make_graph_api_call   endpoint: "/me",
                  parameters: {
                    "access_token" => token
                  }

      photo = make_graph_api_call endpoint: "/me/picture",
                    parameters: {
                      "access_token" => token,
                      "type" => "large",
                      "redirect" => false
                    }
    return {"bio" => bio, "photo" => photo["url"]}
  end
end