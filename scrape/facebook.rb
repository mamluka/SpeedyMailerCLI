require 'koala'
require 'logger'

Koala.http_service.faraday_middleware = Proc.new do |builder|

  # Add Faraday's logger (which outputs to your console)

  builder.use Faraday::Response::Logger

  # Add the default middleware by calling the default Proc that we just replaced
  # SOURCE CODE: https://github.com/arsduo/koala/blob/master/lib/koala/http_service.rb#L20

  Koala::HTTPService::DEFAULT_MIDDLEWARE.call(builder)

end

(Koala::HTTPService.http_options[:ssl] ||= {})[:verify] = false

@graph = Koala::Facebook::API.new('CAACEdEose0cBACRvCGnyns7tphzpxRgNZA85hJZCLYP5t3S9EbhNEBXwJCNULXGzLzb6T1pSrqlSP5WdZCAWTLaIiJhMGb59lf8satHWD1EIIRNkRWeZBrEq6Uko536unjaImZAyMc45ZBLRdImiopTwJJvJTmi4mvwKv2DesgFDO1EP0EfxgUd6Bc6EhRMafw8iZCujKcX9AZDZD')

page = @graph.get_page(ARGV[0])

feed = @graph.get_connections(page['id'], 'feed')

page_feed_ids = Array.new

while page_feed_ids.length < ARGV[1].to_i
  feed.each do |story|
    page_feed_ids << story['id'] if story['from']['id'] == page['id']
  end

  feed.next_page
end

logger= Logger.new 'facebook-scrape.log'

page_feed_ids.take(ARGV[1].to_i).each do |id|
  begin
    likes = @graph.get_connection(id, '/comments', limit: 1000)
  rescue Exception => ex
    logger.error ex.message
    next
  end

  like_users = Array.new

  while not likes.nil?
    like_users.concat(likes.map { |x| x['id'] })
    likes =likes.next_page
  end

  like_users.each_slice(50).each do |x|
    begin
      @graph.get_objects(x).each { |k, v| $stdout.puts "#{v['username']}@facebook.com" if not v['username'].nil? }
    rescue Exception => ex
      logger.error ex.message
      next
    end
  end

end


