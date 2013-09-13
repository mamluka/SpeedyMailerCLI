class CreativeId
  def self.generate_id(id)
    "#{prefix}:#{id}"
  end

  def self.prefix
    'creative'
  end

end