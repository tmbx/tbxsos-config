class CreateEmails < ActiveRecord::Migration
  def self.up
    create_table :emails do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :emails
  end
end
