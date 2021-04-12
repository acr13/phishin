# frozen_string_literal: true
class AddStorageConvertedAtToTracks < ActiveRecord::Migration[6.1]
  def change
    add_column :tracks, :storage_converted_at, :datetime
  end
end
