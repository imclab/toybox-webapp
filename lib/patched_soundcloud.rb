class Soundcloud
  # monkey patch authorize_url to use response_type=code. We don't
  # want the access_token returned as a URL fragment.
  def authorize_url(options={})
    additional_params = [:display, :state, :scope].map do |param_name|
      value = options.delete(param_name)
      "#{param_name}=#{CGI.escape value}" unless value.nil?
    end.compact.join("&")
    store_options(options)
    "https://#{self.host}#{Soundcloud::AUTHORIZE_PATH}?response_type=code&client_id=#{self.client_id}&redirect_uri=#{URI.escape self.redirect_uri}&#{additional_params}"
  end
end
