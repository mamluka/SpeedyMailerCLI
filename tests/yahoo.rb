require 'oauth2'

oauth_consumer_key = 'dj0yJmk9YnFHQzV6bld2TVRwJmQ9WVdrOU9EUmhjMEp5TXpRbWNHbzlNakEyT1RFME1ESTJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD1iMg--'
oauth_consumer_secret = 'e4eb332df92309a70891dd417cfcaa91b2533ebb'

client = OAuth2::Client.new(oauth_consumer_key, oauth_consumer_secret, {
    access_token_path: '/oauth/v2/get_token',
    authorize_path: '/oauth/v2/request_auth',
    authorize_url: 'https://api.login.yahoo.com/oauth/v2/request_auth',
    request_token_path: '/oauth/v2/get_request_token',
    site: 'https://api.login.yahoo.com',
    ssl: {verify: false}
})

p client.auth_code.authorize_url(:redirect_uri => 'http://localhost:8080/oauth2/callback')
