FactoryBot.define do
  factory :task do
    title { 'タイトル' }
    body { '内容' }
    association :category
    sequence(:priority) { |n| n }
    status { :enabled }
    notice { false }
  end
end
