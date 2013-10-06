require 'koala'

@graph = Koala::Facebook::API.new('CAACEdEose0cBALAZBY4uW9yxMfiRuMML9HbBkyNJ5VvY3bcO554U2WWdhjvu2xibZA3ZBZC4VGqulI41HVgqbtlczRx7jlDmwvtNk6PZB51ZCnSDu89NSZAgvEEt2IZBtSqyjWtoJKZBZCAeEPwUNCZCNxjlJgh3IjyxMVz8AnW9LklI3asw0E1aIW30hBuZBVXbaJfDZC4R5Ei3ICgZDZD')

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
    like_users.concat(likes.map { |x| x['id'] })
    likes =likes.next_page
  end

  like_users.each_slice(50).each do |x|
    @graph.get_objects(x).each { |k, v| $stdout.puts "#{v['username']}@facebook.com" if not v['username'].nil? }
  end

end


