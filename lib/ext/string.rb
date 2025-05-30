class String
  def to_bool
    return true if self == true || self =~ /(true|t|yes|y|1)$/i
    return false if self == false || blank? || self =~ /(false|f|no|n|0)$/i

    raise ArgumentError, "invalid value for Boolean: \"#{self}\""
  end

  def strip_tags
    ActionController::Base.helpers.strip_tags(self)
  end

  def is_float?
    to_f.to_s == to_s
  end

  def is_number?
    to_f.to_s == to_s || to_i.to_s == to_s
  end

  def is_bool?
    self == 'false' || self == 'true'
  end

  # check if current string is true or false
  # cases for true: '1' | 'true'
  # cases for false: '0' | 'false' | ''
  # return boolean
  def cama_true?
    self == 'true' || self == '1'
  end

  def to_var
    if is_float?
      to_f
    elsif is_number?
      to_i
    elsif is_bool?
      to_bool
    else
      self
    end
  end

  # parse string into slug format
  def slug
    # strip the string
    ret = strip

    # blow away apostrophes
    ret.gsub!(/['`]/, '')

    # @ --> at, and & --> and
    ret.gsub!(/\s*@\s*/, ' at ')
    ret.gsub!(/\s*&\s*/, ' and ')

    # replace all non alphanumeric, underscore or periods with underscore
    ret.gsub!(/\s*[^A-Za-z0-9.-]\s*/, '_')

    # convert double underscores to single
    ret.gsub!(/_+/, '_')

    # strip off leading/trailing underscore
    ret.gsub!(/\A[_.]+|[_.]+\z/, '')
    ret
  end

  # parse string into domain
  # https://owen.camaleon.website into owen.camaleon.website
  def parse_domain
    url = self
    uri = URI.parse(url)
    uri = URI.parse("https://#{url}") if uri.scheme.nil?
    host = (uri.host || self).downcase
    h = host.start_with?('www.') ? host[4..] : host
    "#{h}#{":#{uri.port}" unless [80, 443].include?(uri.port)}"
  end

  # parse all codes in current text to replace with values
  # sample: "Hello [c1]".cama_replace_codes({c1: 'World'}) ==> Hello World
  def cama_replace_codes(values, format_code = '[')
    res = self
    values.each do |k, v|
      v = v.join(',') if v.is_a?(Array)
      res = res.gsub("[#{k}]", v.to_s) if format_code == '['
      res = res.gsub("{#{k}}", v.to_s) if format_code == '{'
      res = res.gsub("%{#{k}}", v.to_s) if format_code == '%{'
    end
    res
  end

  # remove double or more secuencial slashes, like: '/a//b/c/d///abs'.cama_fix_slash => /a/b/c/d/abs
  def cama_fix_slash
    gsub(%r{(/){2,}}, '/')
  end

  # fix file media keys: avoid duplicated slashes and force to start with slash
  def cama_fix_media_key
    res = gsub('../', '/').gsub('./', '/').gsub(%r{(/){2,}}, '/')
    res = "/#{res}" unless res.start_with?('/')
    res = res.slice(0...-1) if res.end_with?('/') && res.length > 1
    res
  end

  def cama_fix_filename
    # Sanitize the filename, to prevent hacking
    # https://github.com/carrierwaveuploader/carrierwave/blob/6a1445e0daef29a5d4f799a016359b62d82dbc24/lib/carrierwave/sanitized_file.rb#L322
    sanitize_regexp = /[^[:word:].\-+]/
    name = tr('\\', '/') # work-around for IE
    name = File.basename(name)
    name = name.gsub(sanitize_regexp, '_')
    name = "_#{name}" if name =~ /\A\.+\z/
    name = 'unnamed' if name.empty?
    name.mb_chars.to_s
  end

  # return cleaned model class name
  # remove decorate
  # remove Cama prefix
  def parseCamaClass
    gsub('Decorator', '').gsub('CamaleonCms::', '')
  end

  # convert url into custom url with postfix,
  # sample: "http://localhost/company/rack_multipart20160124_2288_8xcdjs.jpg".cama_add_postfix_url('thumbs/') into http://localhost/company/thumbs/rack_multipart20160124_2288_8xcdjs.jpg
  def cama_add_postfix_url(postfix)
    File.join(File.dirname(self), "#{postfix}#{File.basename(self)}")
  end

  # Sample:
  #  '/var/www/media/132/logo.png'.cama_add_postfix_file_name('_2') ==> /var/www/media/132/logo_2.png
  def cama_add_postfix_file_name(postfix)
    File.join(File.dirname(self), "#{File.basename(self, File.extname(self))}#{postfix}#{File.extname(self)}")
  end

  # Parse the url to get the image version
  #   version_name: (String, default empty) version name,
  #     if this is empty, this will return the image version for thumb of the image, sample: 'http://localhost/my_image.png'.cama_parse_image_version('') => http://localhost/thumb/my_image.png
  #     if this is present, this will return the image version generated, sample: , sample: 'http://localhost/my_image.png'.cama_parse_image_version('200x200') => http://localhost/thumb/my_image_200x200.png
  #   check_url: (boolean, default false) if true the image version will be verified, i.e. if the url exist will return version url, if not will return current url
  def cama_parse_image_version(version_name = '', check_url = false)
    res = File.join(File.dirname(self), 'thumb', "#{File.basename(self).parameterize}#{File.extname(self)}")
    res = res.cama_add_postfix_file_name("_#{version_name}") if version_name.present?
    return self if check_url && !res.cama_url_exist?

    res
  end

  # check if the url exist
  # sample: "https://mydomain.com/myimg.png".cama_url_exist?
  # return (Boolean) true if the url exist
  def cama_url_exist?
    Net::HTTP.get_response(URI.parse(self)).is_a?(Net::HTTPSuccess)
  rescue StandardError
    false
  end

  # Colorized Ruby output
  # color: (:red, :green, :blue, :pink, :light_blue, :yellow)
  def cama_log_style(color = :red)
    colors = { red: 31, green: 32, blue: 34, pink: 35, light_blue: 36, yellow: 33 }
    "\e[#{colors[color]}m#{self}\e[0m"
  end
end
