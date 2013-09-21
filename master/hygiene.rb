#!/usr/bin/env ruby
require 'thor'

require_relative '../core/jobs'

class Hygiene < Thor
  desc 'test_clean email', 'Test cleaning of one email'

  def test_clean(recipient,drone_id)
    Sidekiq::Client.push('queue' => drone_id, 'class' => VerityRecipient, 'args' => [recipient])
  end
end

Hygiene.start