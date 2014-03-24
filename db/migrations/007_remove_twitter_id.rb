Sequel.migration do
  up do
    drop_column :friends, :twitter_id
  end

  down do
    add_column :friends, :twitter_id, String
  end
end
