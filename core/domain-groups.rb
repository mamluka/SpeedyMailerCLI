class DomainGroups
  def self.extract_domain(recipient)
    scan = recipient.scan /@(.+?)$/

    scan.empty? ? 'None' : scan[0][0]
  end
end