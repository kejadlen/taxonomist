DEFAULT_JSON = Sequel::LiteralString.new("'{}'::json")

Sequel.migration do
  change do
    alter_table :users do
      drop_column :list_ids
    end

    drop_table :lists
  end
end
