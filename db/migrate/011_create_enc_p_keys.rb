class CreateEncPKeys < ActiveRecord::Migration
  def self.up
    create_table :enc_p_keys do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :enc_p_keys
  end
end
