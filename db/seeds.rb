ActiveRecord::Base::transaction do
  %w[仕事 学習 プライベート その他].each do |name|
    Category.create!(name: name)
  end
end
