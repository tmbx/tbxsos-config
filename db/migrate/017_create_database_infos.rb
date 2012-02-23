class CreateDatabaseInfos < ActiveRecord::Migration
  def self.up
    create_table :database_infos do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :database_infos
  end
end
