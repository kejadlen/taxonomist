Sequel.migration do
  up do
    drop_column :friends, :friends
    add_column :friends, :friend_ids, 'Text[]'
  end

  down do
    add_column :friends, :friends, 'Text[]'
    drop_column :friends, :friend_ids
  end
end
