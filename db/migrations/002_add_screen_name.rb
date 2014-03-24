Sequel.migration do
  up do
    add_column :users, :screen_name, String
  end

  down do
    drop_column :users, :screen_name
  end
end
