defmodule Rumbl.Repo.Migrations.AddSrcAndUrlToAnnotation do
  use Ecto.Migration

  def change do
    alter table(:annotations) do
      add :src, :string
      add :url, :string
    end
  end
end
