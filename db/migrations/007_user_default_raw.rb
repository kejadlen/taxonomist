Sequel.migration do
  change do
    from(:users).where(raw: nil).update(raw: Sequel.pg_json({}))

    alter_table(:users) do
      set_column_default(:raw, Sequel::LiteralString.new("'{}'::json"))
      set_column_not_null(:raw)
    end
  end
end
