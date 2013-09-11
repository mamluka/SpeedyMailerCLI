require 'redis'
require 'json'
require 'base64'
require 'erb'
require 'ostruct'
require 'mail'

require_relative 'drone-config'
require_relative 'creative'


class Drone
  def send(creative_id, email)
    creative = Creative.get creative_id

    deal_url = create_deal_url creative_id, email

    unsubscribe_template = creative[:unsubscribe_template]
    if not unsubscribe_template.nil?
      rendered_unsubscribe_template = render_creative_template unsubscribe_template, {unsubscribe_url: create_unsubscribe_url(creative_id, email)}
      email_body = render_creative_template creative[:body], {deal_url: deal_url}
      whole_email = email_body + rendered_unsubscribe_template
    else
      email_template_hash = {
          deal_url: deal_url,
          unsubscribe_url: create_unsubscribe_url(creative_id, email)
      }

      whole_email= render_creative_template creative[:body], email_template_hash
    end

    from_prefix = creative[:from_prefix]
    from_name = creative[:from_name]

    mail = Mail.new do
      to email
      from "<#{from_name}> #{from_prefix}@mobilewebforyou.info"
      subject creative[:subject]
      body whole_email
    end

    mail.header['Speedy-Creative-Id'] = creative_id


    if not ENV['DRONE_DEBUG'].nil?
      File.open(File.dirname(__FILE__) + '/tests/' + creative_id + '_' + email, 'w') { |f| f.write(mail.to_s) }
    else
      mail.deliver!
    end

  end

  def create_unsubscribe_url(creative_id, email)
    create_url(creative_id, email, 'unsubscribe')
  end

  def create_deal_url(creative_id, email)
    create_url(creative_id, email, 'deal')
  end

  def create_url(creative_id, email, route)
    payload = Base64.encode64("#{creative_id},#{email}")
    "#{$config[:domain]}/#{route}/#{payload}"
  end

  def render_creative_template(template, values)
    opts = OpenStruct.new(values)

    renderer = ERB.new template
    renderer.result(opts.instance_eval { binding })
  end

  def config_smpt
    options = {:address => '127.0.0.1',
               :port => 25,
               :domain => $config[:domain],
               :authentication => 'none',
               :ssl => false,
               :enable_starttls_auto => false
    }


    Mail.defaults do
      delivery_method :smtp, options
    end
  end

end