Sequel.migration do
  up do
    alter_table(:friends) do
      set_column_type :id, Bignum
    end
  end

  down do
    alter_table(:friends) do
      set_column_type :id, Integer
    end
  end
end
