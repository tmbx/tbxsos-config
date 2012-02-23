class CreateLogins < ActiveRecord::Migration
  def self.up
    create_table :logins do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :logins
  end
end
