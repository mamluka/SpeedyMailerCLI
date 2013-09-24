require 'koala'

@graph = Koala::Facebook::API.new('CAACEdEose0cBABGiO7W082A9so0KklGlw0GM6Jf91Iz5J5KY0e09W6pZBZBkeZAFbeAUHEe7GhLmoKT23ABLZCjldnxfjZAyJ3KOD5ooZBrS3MIgg9BfMEQc8PZCld2QZA6Fzits51nZCPZCfONeQKDszxIZCDXo21VACyJRNRPZAjYYWUmq3MCuIsL7JMceuay2m0NsKLzpHRAb4AZDZD')

page = @graph.get_page('nike')

feed = @graph.get_connections(page['id'], 'feed')

first_post = feed.first['id']

likes = @graph.get_connection(first_post, '/likes', limit: 1000)

counter = 0
like_users = Array.new

while like_users.length < 5000
  #likes.each { |x| $stdout.puts x['id'] }

  like_users.concat(likes.map { |x| x['id'] })

  likes =likes.next_page
end

like_users.each_slice(100).each do |x|
  @graph.get_objects(x).each { |k, v| $stdout.puts "#{v['username']}@facebook.com" if not v['username'].nil? }
end

