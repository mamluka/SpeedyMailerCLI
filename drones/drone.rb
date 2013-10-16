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

    from_prefix = creative[:from_prefix]
    from_name = creative[:from_name]

    body_html = create_email_body(:body_html, creative_id, email) if not creative[:body_html].nil?
    body_text = create_email_body(:body_text, creative_id, email) if not creative[:body_text].nil?

    mail = Mail.new do
      to email
      from "#{from_name} <#{from_prefix}@#{$config[:domain]}>"
      subject creative[:subject].kind_of?(Array) ? creative[:subject].sample : creative[:subject]

      if not creative[:body_html].nil?

        html_part do
          body body_html
        end
      end

      if not creative[:body_text].nil?

        text_part do
          body body_text
        end
      end
    end

    mail.header['Speedy-Creative-Id'] = creative_id

    if not ENV['DRONE_DEBUG'].nil?
      File.open(File.dirname(__FILE__) + '/tests/' + creative_id + '_' + email, 'w') { |f| f.write(mail.to_s) }
    else
      mail.deliver!
    end

  end

  def create_email_body(body_type_key, creative_id, email)

    creative = Creative.get creative_id
    deal_url = create_deal_url creative_id, email
    open_tracking_url = create_open_track_url creative_id, email

    unsubscribe_template = creative[:unsubscribe_template]
    creative_body = creative[body_type_key]

    if creative_body.kind_of?(Array)
      creative_body = creative_body.sample
    end

    if not unsubscribe_template.nil?
      rendered_unsubscribe_template = render_creative_template unsubscribe_template, {unsubscribe_url: create_unsubscribe_url(creative_id, email)}

      email_template_hash = {
          deal_url: deal_url,
          open_tracking_url: open_tracking_url
      }

      email_body = render_creative_template creative_body, email_template_hash
      whole_email = email_body + rendered_unsubscribe_template
    else

      email_template_hash = {
          deal_url: deal_url,
          unsubscribe_url: create_unsubscribe_url(creative_id, email),
          open_tracking_url: open_tracking_url
      }

      whole_email = render_creative_template creative_body, email_template_hash
    end

    whole_email
  end

  def create_unsubscribe_url(creative_id, email)
    create_url(creative_id, email, 'unsubscribe')
  end

  def create_open_track_url(creative_id, email)
    create_url(creative_id, email, 'small-logo')
  end

  def create_deal_url(creative_id, email)
    create_url(creative_id, email, 'deal')
  end

  def create_url(creative_id, email, route)
    payload = Base64.encode64("#{creative_id},#{email}")
    "http://#{$config[:domain]}/#{route}/#{payload}".strip
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