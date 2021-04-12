# frozen_string_literal: true
namespace :storage do
  desc 'Populate activestorage records from paperclip fields'
  task records: :environment do
    # relation = Track.unscoped.where(storage_converted_at: nil).order(id: :asc)
    relation = 
      Track.unscoped
           .where(storage_converted_at: nil)
<<<<<<< HEAD
           .where('id >= ? AND id <= ?', 34_003, 34_013)
=======
           .where('id > ? AND id < ?', 34_003, 34_013)
>>>>>>> 94e6d51 (ActiveStorage conversion phase 1)
           .order(id: :asc)
    pbar = ProgressBar.create(total: relation.count, format: '%a %B %c/%C %p%% %E')

    blob_sql = 
      <<~SQL.squish
        INSERT INTO active_storage_blobs (
          key, filename, content_type, metadata, byte_size, checksum, created_at, service_name
        ) VALUES ($1, $2, $3, '{}', $4, $5, $6, 'local')
      SQL
    attachment_sql =
      <<~SQL.squish
        INSERT INTO active_storage_attachments (
          name, record_type, record_id, blob_id, created_at
        ) VALUES ('audio_file', $1, $2, #{"(SELECT max(id) from active_storage_blobs)"}, $3)
      SQL
    blob_statement = ActiveRecord::Base.connection.raw_connection.prepare('blob_statement', blob_sql)
    attachment_statement = ActiveRecord::Base.connection.raw_connection.prepare('attachment_statement', attachment_sql)

    missing_files = []
    relation.find_each do |track|
      next missing_files << track.id if (attachment = track.audio_file).blank?

      ActiveRecord::Base.transaction do
        filename = track.audio_file.original_filename
        audio_file_path = track.audio_file.path
        blob_key = SecureRandom.alphanumeric(24)

        # Create ActiveStorage records
        ActiveRecord::Base.connection.raw_connection.exec_prepared(
          'blob_statement', 
          [
            blob_key,
            filename,
            track.audio_file.content_type,
            track.audio_file.size,
            Digest::MD5.base64digest(File.read(audio_file_path)),
            track.updated_at.iso8601
          ]
        )
        ActiveRecord::Base.connection.raw_connection.exec_prepared(
          'attachment_statement', 
          [
            'Track',
            track.id,
            track.updated_at.iso8601,
          ]
        )

        # Copy file from local storage to S3
        new_folder = "#{ENV['ACTIVESTORAGE_ROOT']}/#{blob_key[0..1]}/#{blob_key[2..3]}"
        FileUtils.mkdir_p(new_folder)
        FileUtils.cp(audio_file_path, "#{new_folder}/#{blob_key}")

        # Mark track as converted
        track.update_columns(storage_converted_at: Time.current)
      end
      
      pbar.increment
    end

    pbar.finish
    puts "Total missing files: #{missing_files.size}"
    puts "IDs: #{missing_files}"
  end
end
