require "dnsbl/client"

c = DNSBL::Client.new

p c.lookup('211.150.99.133')

