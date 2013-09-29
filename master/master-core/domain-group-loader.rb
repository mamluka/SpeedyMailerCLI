class DomainGroupsLoader
  def load(file_name)
    domains = {
        gmail: %w(gmail.com googlemail.com),
        hotmail: %w(hotmail.com msn.com),
        yahoo: %w(yahoo.com),
        aol: %w(aol.com),
        sbcglobal: %w(sbcglobal.net),
        verizon: %w(verizon.net),
        comcast: %w(comcast.net),
        charter: %w(charter.net),
        juno: %w(juno.com),
        roadrunner: %w(roadrunner.com),
        earthlink: %w(earthlink.net)
    }

    domain_groups = Hash.new

    domains.each { |k, v|
      domain_groups[k] = Array.new
    }

    domain_groups[:other] = Array.new
    full_filename = file_name

    File.open(full_filename, 'r').each do |line|
      line = line.strip

      matched = false
      domains.each { |k, v|
        if v.any? { |domain| line.match(domain) }
          domain_groups[k] << line.scan(/[A-Z0-9._%a-z\-]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}/)[0]
          matched = true
          break
        end
      }
      domain_groups[:other] << line unless matched
    end

    domain_groups
  end
end