# frozen_string_literal: true
require 'mp3info'

class Id3Tagger
  attr_reader :track

  def initialize(track)
    @track = track
  end

  def call
    apply_default_tags
  end

  private

  def apply_default_tags
    service = ActiveStorage::Service::DiskService.new(root: ENV['ACTIVESTORAGE_ROOT'])
    path = service.send(:path_for, track.audio_file.blob.key)
    Mp3Info.open(path) do |mp3|
      apply_tags(mp3)
      apply_v2_tags(mp3)
      mp3.tag2.remove_pictures
    end
  end

  def apply_tags(mp3)
    apply_track_specific_tags(mp3)
    mp3.tag.artist = artist
    mp3.tag.album = album[0..29]
    mp3.tag.year = year
    mp3.tag.comments = comments
  end

  def apply_track_specific_tags(mp3)
    mp3.tag.title = track.title[0..29]
    mp3.tag.tracknum = track.position
  end

  def apply_v2_tags(mp3)
    apply_track_specific_v2_tags(mp3)
    mp3.tag2.TOPE = artist
    mp3.tag2.TALB = album[0..59]
    mp3.tag2.TYER = year
    mp3.tag2.COMM = comments
  end

  def apply_track_specific_v2_tags(mp3)
    mp3.tag2.TIT2 = track.title[0..59]
    mp3.tag2.TRCK = track.position
  end

  def show
    @show ||= track.show
  end

  def comments
    'http://phish.in for more'
  end

  def year
    @year ||= show.date.strftime('%Y').to_i
  end

  def artist
    'Phish'
  end

  def album
    @album ||= "#{show.date} #{show.venue_name}"
  end
end
