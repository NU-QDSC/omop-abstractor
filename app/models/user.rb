require './lib/ldap'
require './lib/study_tracker_api'
class User < ApplicationRecord
  has_paper_trail
  has_many :role_assignments
  has_many :roles, through: :role_assignments
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :trackable, :timeoutable

  def self.find_ldap_entry_by_username(username)
    user = Ldap.instance.find_entry_by_netid(username)
    if user
      user = { username: User.extract_uid_from_dn(user.dn), first_name: user.givenname.first, last_name: user.sn.first, email: user.mail.first }
    else
      user = {}
    end
    user
  end

  def hydrate_from_ldap
    if !Rails.env.development? && !Rails.env.test?
      user = User.find_ldap_entry_by_username(self.username)
      if user
        self.first_name = user[:first_name]
        self.last_name = user[:last_name]
        self.email = user[:email]
      end
    end
  end

  def self.extract_uid_from_dn(dn)
    dn.match(/(?<=uid=)(\w*)(?=,)/).to_s
  end

  def after_ldap_authentication
    login_audit = LoginAudit.new(username: self.username, login_type: LoginAudit::LOGIN_TYPE_INTERACTIVE)
    login_audit.save!
    hydrate_from_ldap
  end

  def valid_ldap_authentication?(password)
    valid_ldap_authentication = authorized?
    if valid_ldap_authentication
      super
    end
  end

  def authorized?
    study_tracker_api = StudyTrackerApi.new
    study_tracker_api.authorized_personnel?(self.username)
  end
end