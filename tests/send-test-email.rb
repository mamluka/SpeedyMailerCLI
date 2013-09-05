require 'mail'

options = {:address => 'localhost',
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
  to 'davidm@sears.co.il'
  from 'david@ubunt.com'
  subject 'testing sendmail'
  body 'testing sendmail'
  message_id 'Create1'
end

mail.header['Speedy-Creative-Id'] = '1'

mail.deliver!