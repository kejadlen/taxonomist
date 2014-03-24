Sequel.migration do
  up do
    alter_table(:friends) do
      set_column_type :id, Integer
      add_column :twitter_id, Bignum, index: true
    end
  end

  down do
    alter_table(:friends) do
      set_column_type :id, Bignum
      drop_column :twitter_id
    end
  end
end
