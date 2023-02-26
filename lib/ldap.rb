# -*- coding: utf-8 -*-
require 'net/ldap'

##
# Helper class to retrieve attributes about members
# through the Northwestern LDAP directory
class Ldap

  attr_reader :config
  # Singleton pattern
  @@instance = Ldap.new

  def self.instance
    @@instance
  end

  # The known attributes available to us through LDAP
  ATTRIBUTES = [
    'title',
    'displayname',
    'givenname',
    'cn',
    'sn',
    'mail',
    'ou',
    'uid',
    'uidnumber',
    'dn',
    'facsimiletelephonenumber',
    'telephonenumber',
    'postaladdress'
  ]

  ##
  # Helper method to retrieve an entry via netid
  # @see find_entry
  # @param [String]
  # @return [Net::LDAP::Entry]
  def find_entry_by_netid(netid)
    find_entry(netid, 'uid')
  end

  ##
  # Helper method to retrieve an entry via email address
  # @see find_entry
  # @param [String]
  # @return [Net::LDAP::Entry]
  def find_entry_by_email(email)
    find_entry(email, 'mail')
  end

  def find_entries_by_full_name(first_name, last_name)
    fn = Net::LDAP::Filter.eq('givenname', first_name)
    ln = Net::LDAP::Filter.eq('sn', last_name)
    find_ldap_entries(Net::LDAP::Filter.intersect(fn, ln))
  end

  def find_entries_by_email(email)
    find_ldap_entries(Net::LDAP::Filter.eq('mail', email))
  end

  def find_entries_by_name(name)
    fn = Net::LDAP::Filter.eq('givenname', name)
    ln = Net::LDAP::Filter.eq('sn', name)
    find_ldap_entries(Net::LDAP::Filter.intersect(fn, ln))
  end

  ##
  # Method to retrieve an LDAP entry from a key
  # @see find_entry
  # @param [String]
  # @return [Net::LDAP::Entry]
  def find_entry(value, key = 'uid')
    find_ldap_entry(Net::LDAP::Filter.eq(key, value))
  end

  # Load ldap configuration
  # @return [HashWithIndifferentAccess]
  def get_ldap_config
    ldap_config = File.join(Rails.root, 'config', 'ldap.yml')
    if File.exists?(ldap_config)
      @config ||= ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(ldap_config))[Rails.env]
    end
  end

  ##
  # Create the Net::LDAP object
  # @return [Net:LDAP]
  def get_connection
    get_ldap_config
    ldap_args = {
      host: config[:host],
      port: config[:port],
      base: config[:base],
      auth: {
        method: :simple,
        username: config[:admin_user],
        password: config[:admin_password]
      }
    }

    if config[:ssl]
      ldap_args[:encryption] = ssl_encryption
    end

    Net::LDAP.new(ldap_args)
  end


  private :get_connection

  def ssl_encryption
    {method: :simple_tls, tls_options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS}
  end

  def find_ldap_entry(filter)
    entries = find_ldap_entries(filter)
    return entries[0] unless entries.blank?
  end
  private :find_ldap_entry

  def find_ldap_entries(filter)
    result  = []
    entries = []
    begin
      Timeout::timeout(3) { entries = get_connection.search(base: treebase, filter: filter) }
      entries.each { |e| result << clean_ldap_entry(e) }
    rescue Timeout::Error
      Rails.logger.error('ExternalServices::Ldap.find_ldap_entries - Execution expired.')
    end
    result
  end
  private :find_ldap_entries

  def treebase
    'ou=People,dc=northwestern,dc=edu'
  end
  private :treebase

  ##
  # For each attribute retrieved, clean the value
  # @see clean_ldap_value
  # @param [Net::LDAP::Entry]
  # @retrun [Net::LDAP::Entry]
  def clean_ldap_entry(entry)
    ATTRIBUTES.each do |key|
      entry[key] = clean_ldap_value(entry[key])
    end
    entry
  end
  private :clean_ldap_entry

  ##
  # Remove undesirable characters from the value retrieved
  # e.g. newline("\n"), '-', '[', ']'
  # or replace with a space
  # e.g. '$'
  # @param [String]
  # @return [String]
  def clean_ldap_value(val)
    return nil if val.nil?

    if val.kind_of?(Array)
      return nil if val.length == 0
      val = clean_ldap_value(val[0].to_s)
    else
      val = val.to_s
      replacement_characters.each do |char, new_val|
        val = val.gsub(char, new_val)
      end
      val = val.strip
    end
    val
  end

  private :clean_ldap_value

  def replacement_characters
    [
      ["\n", ''],
      ['[', ''],
      [']', ''],
      ['$', ' ']
    ]
  end
  private :replacement_characters
end
