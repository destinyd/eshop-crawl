class SiteBase
  attr_accessor :url
  attr_accessor :id

  def initialize(args)
    @id = args[:id]
    @url = @format_url % @id if @id
  end

  def url
    @url
  end

  def is?(url)
    !!regex_id.match(url)
  end

  def get_id
    @id ||= regex_id.match(url)['id']
  end
end
