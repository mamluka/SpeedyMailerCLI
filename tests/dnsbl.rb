require "dnsbl/client"

c = DNSBL::Client.new

p c.lookup('162.210.39.165')

