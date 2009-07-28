require 'test/unit'
require File.dirname(__FILE__) + '/test_helper.rb' 
require File.dirname(__FILE__) + '/test_mock.rb'

class PowerdnsNetticaTest < Test::Unit::TestCase
  NS_PRIMARY      = "your.nameserver.com"
  NS_PRIMARY_IP   = "your.nameserver.ip.address" 
  EX_DOMAIN       = "does-exist-as89nkahis.com"
  NX_DOMAIN       = "does-not-exist-sanu89ah.com"
  IDN_DOMAIN      = "does-not-ex-æøå-1234.no"

  def setup
    PowerdnsNettica.client.create_secondary_zone( EX_DOMAIN, NS_PRIMARY, NS_PRIMARY_IP)
    [NX_DOMAIN, IDN_DOMAIN].each do |domain|
      if PowerdnsNettica.has_domain?(domain)
        PowerdnsNettica.client.delete_zone(domain)
      end
    end
  end

  def teardown
    [EX_DOMAIN, NX_DOMAIN, IDN_DOMAIN].each do |domain|      
      if PowerdnsNettica.has_domain?(domain)
        PowerdnsNettica.client.delete_zone(domain)
      end
    end
  end

  def test_should_not_create_ns_for_slave_domain
	  domain = MockDomain.new( {:name => NX_DOMAIN, :type => "SLAVE"} )
	  assert_equal nil, PowerdnsNettica::DomainHook.on_create( domain )
  end

  def test_should_not_create_ns_for_invalid_domain
	  domain = MockDomain.new( {:name => NX_DOMAIN, :valid => false } )
	  assert_equal nil, PowerdnsNettica::DomainHook.on_create( domain )
  end
  
  def test_should_not_create_ns_with_nx_primary_ns
	  domain = MockDomain.new( {:name => NX_DOMAIN, :primary_ns => "does-not-exist-78ashuansjS.com"} )
  	assert_equal false, PowerdnsNettica::DomainHook.on_create( domain )
	  assert_equal true, domain.errors.on_base.include?("Could not resolve primary name server")
  end
  
  def test_should_create_ns_with_valid_domain
    domain = MockDomain.new( {:name => NX_DOMAIN, :primary_ns => NS_PRIMARY} )
	  assert_equal true, PowerdnsNettica::DomainHook.on_create( domain )
	  assert_equal true, PowerdnsNettica.has_domain?(NX_DOMAIN)
  end
  
  def test_should_not_create_ns_with_existing_domain
	  domain = MockDomain.new( {:name => EX_DOMAIN, :primary_ns => NS_PRIMARY} )
	  assert_equal false, PowerdnsNettica::DomainHook.on_create( domain )
  end

  def test_should_delete_ns_on_domain_destroy
  	domain = MockDomain.new( {:name => EX_DOMAIN, :primary_ns => NS_PRIMARY} )
  	assert_equal true, PowerdnsNettica::DomainHook.on_destroy( domain )
  	assert_equal false, PowerdnsNettica.has_domain?(EX_DOMAIN)
  end
  
  def test_shoud_create_ns_with_idn_domain
    ascii = IDN::Idna.toASCII( IDN_DOMAIN )
    domain = MockDomain.new( {:name => ascii, :primary_ns => NS_PRIMARY} )
	  assert_equal true, PowerdnsNettica::DomainHook.on_create( domain )
	  assert_equal true, PowerdnsNettica.has_domain?(IDN_DOMAIN)
  end
end
