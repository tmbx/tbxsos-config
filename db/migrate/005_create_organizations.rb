class CreateOrganizations < ActiveRecord::Migration
  def self.up
    create_table :organizations do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :organizations
  end
end
