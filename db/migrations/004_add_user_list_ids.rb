Sequel.migration do
  change do
    alter_table(:users) do
      add_column :list_ids, 'bigint[]'
    end
  end
end
