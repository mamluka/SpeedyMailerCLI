require 'koala'

@graph = Koala::Facebook::API.new('CAACEdEose0cBAHggvR5xl7zIDeffgZAhcwxpRYK3LkyfB0uaU1IptTkVjCqy6YuhryZCFwgEVdi7jImD83S1jz6tO9pSMzHoVFZBltvXq21YYCoZApOsW59UkUzrdo2wZBRJo6jnpc5JU0ZCkVEDro6Q3ZABUPTx4aPRiwLO3ZCbFATdzVO0vbQkMRoikuhCL7wZD')

page = @graph.get_page(ARGV[0])

feed = @graph.get_connections(page['id'], 'feed')

page_feed_ids = Array.new

while page_feed_ids.length < ARGV[1].to_i
  feed.each do |story|
    page_feed_ids << story['id'] if story['from']['id'] == page['id']
  end

  feed.next_page
end

page_feed_ids.take(ARGV[1].to_i).each do |id|

  likes = @graph.get_connection(id, '/likes', limit: 1000)
  like_users = Array.new

  while not likes.nil?
    p likes.length
    like_users.concat(likes.map { |x| x['id'] })

    likes =likes.next_page
  end

  like_users.each_slice(100).each do |x|
    @graph.get_objects(x).each { |k, v| $stdout.puts "#{v['username']}@facebook.com" if not v['username'].nil? }
  end

end


