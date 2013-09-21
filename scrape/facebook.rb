require 'fb_graph'


#FbGraph.debug!

#users = FbGraph::User.search('smith', limit: 5000, access_token: 'CAACEdEose0cBANjju2GovPoxgG0EqAEfNWIOOrfLyfLgZACKMbBcyog36JGtKZAZBm9TL1S6UpKDxAlyfkDkM6c3801ZBCPFHZBKZC7cGRn4goQbuXCxybNeiS61KAXP5XkSO3f1cvldbZC9rAn9gi2SLEugODBqpDHpnseH6VdAYXEVoBHKUMQToeeZBtiZCV0gZD')

posts = FbGraph::Searchable.search('solar panels', limit: 10, access_token: 'CAACEdEose0cBAFAXfYkbjc8650W9Yw7qFCZCKzayeQMPZAVprEspZA93SklNPtPdb0OcVpLtZBYXBysjIHfV3RNUiVQi6r5oGHXyXt9qTKOIYgYZAknOPgyJMTwt89wY27NTASROZCSytwI2H8z8oPnaagRIlZCiCfwpeTVAPulY7PvsjUOXtTjdDUii5G9oqcZD')

puts posts.length

puts posts.first

