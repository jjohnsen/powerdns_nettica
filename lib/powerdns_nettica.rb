require 'rubygems'
require 'nettica/client'
require 'resolv'
require 'idn'

module PowerdnsNettica
	def self.client
		client = Nettica::Client.new(
		  DomainHook.config["nettica_username"],
		  DomainHook.config["nettica_password"]
		)
	end
  
	def self.has_domain?(domain)
	  self.client.list_domain( domain ).result.status == 200
	end
	
  class DomainHook
	  def self.config
	    default = {
	      "nettica_username" => "your-username",
	      "nettica_password" => "your-password"
      }
      @config ||= default.merge Hook::config_for(self)
	  end
		
	  def self.on_create(domain)
			# Only add secondary ns for master zones that are valid
			return unless domain.master?
			return unless domain.valid?
			
			# Resolv ip for primary_ns as nettica requires this
			begin
				ipAddress = Resolv.getaddress domain.primary_ns
			rescue
				domain.errors.add_to_base("Could not resolve primary name server")
				return false
			end
			
			# Nettica requires domains to be added in unicode
			name = IDN::Idna.toUnicode( domain.name )
			
			result = PowerdnsNettica.client.create_secondary_zone( name, domain.primary_ns, ipAddress)
     
			if( result.status == 200 )
				return true
			else
				error = "Could not add domain to seconadry NS (#{result.description})"
				domain.errors.add_to_base(error)
				return false
			end
		end

		def self.on_destroy(domain)
			return unless domain.master?

			# Nettica requires domains to be added in unicode
			name = IDN::Idna.toUnicode( domain.name )

			result = PowerdnsNettica.client.delete_zone(name)
      
			# Don't care if domain didn't already exists
			if( result.status == 200 || result.status == 430)
				return true
			else
				error = "Could not delete domain from secondary NS (#{result.description})"
				domain.errors.add_to_base(error)
				return false
			end
		end
	end
end
