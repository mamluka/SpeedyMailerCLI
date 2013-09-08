require 'mail'

options = {:address => '127.0.0.1',
           :port => 25,
           :domain => 'ubuntu',
           :authentication => 'none',
           :ssl => false,
           :enable_starttls_auto => false
}


Mail.defaults do
  delivery_method :smtp, options
end


mail = Mail.new do
  to ARGV[0]
  from 'david@mobilewebforyou.info'
  subject 'testing sendmail'
  body 'testing sendmail'
  message_id 'Create1'
end

mail.header['Speedy-Creative-Id'] = '1'

mail.deliver!
