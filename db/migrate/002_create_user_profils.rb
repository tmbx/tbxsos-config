class CreateUserProfils < ActiveRecord::Migration
  def self.up
    create_table :user_profils do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :user_profils
  end
end
