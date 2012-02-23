class CreatePipeExecs < ActiveRecord::Migration
  def self.up
    create_table :pipe_execs do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :pipe_execs
  end
end
