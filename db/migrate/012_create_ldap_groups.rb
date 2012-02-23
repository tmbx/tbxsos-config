class CreateLdapGroups < ActiveRecord::Migration
  def self.up
    create_table :ldap_groups do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :ldap_groups
  end
end
