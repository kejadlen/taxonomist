Sequel.migration do
  up do
    alter_table(:friends) do
      set_column_not_null :twitter_id
    end
  end

  down do
    alter_table(:friends) do
      set_column_allow_null :twitter_id
    end
  end
end
