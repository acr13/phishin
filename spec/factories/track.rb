# frozen_string_literal: true
FactoryBot.define do
  factory :track do
    sequence(:title) { |n| "Track #{n}" }
    songs { [build(:song)] }
    set { '1' }
    sequence(:position, 1)

    show

    trait :with_audio_file do
      after :create do |track|
        track.audio_file.attach(
          io: File.open("#{Rails.root}/spec/fixtures/test.mp3"),
          filename: 'test.mp3',
          content_type: 'audio/mpeg'
        )
      end
    end

    trait :with_likes do
      after(:build) do |track|
        create_list(:like, 2, likable: track)
      end
    end
  end
end
