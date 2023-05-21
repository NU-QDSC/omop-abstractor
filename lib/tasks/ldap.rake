namespace :ldap do
  desc 'Start LDAP sever'
  task(start: :environment) do  |t, args|
    sh "ruby #{Rails.root}/spec/ldap/run-server"
  end

  desc 'Truncate LDAP sever'
  task(truncate: :environment) do  |t, args|
    truncate_ldap_server!
  end

  desc 'Insert into LDAP sever'
  task(insert: :environment) do  |t, args|
    insert_ldap_server!
  end
end

def ldap_root
  "#{Rails.root}/spec/ldap/"
end

def ldap_connect_string
  "-x -h localhost -p 3389 -D 'cn=admin,dc=test,dc=com' -w secret"
end

def truncate_ldap_server!
  `ldapmodify #{ldap_connect_string} -f #{File.join(ldap_root, 'clear.ldif')} -c`
end

def insert_ldap_server!
  `ldapadd #{ldap_connect_string} -f #{File.join(ldap_root, 'base.ldif')} -c`
end

def reset_ldap_server!
  truncate_ldap_server!
  insert_ldap_server!
end
