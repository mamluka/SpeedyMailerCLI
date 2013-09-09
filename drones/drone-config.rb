$config = JSON.parse(File.read(File.dirname(__FILE__) + '/config.json'), symbolize_names: true)

ENV['REDIS_URL'] = "redis://#{$config[:master]}:6379/0"