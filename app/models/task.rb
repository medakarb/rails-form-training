# == Schema Information
#
# Table name: tasks
#
#  id          :integer          not null, primary key
#  title       :string           not null
#  body        :text             not null
#  category_id :integer          not null
#  priority    :integer          not null
#  status      :string           not null
#  notice      :boolean          default(FALSE), not null
#  code        :string
#  limited_on  :date
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Task < ApplicationRecord
  extend Enumerize
  belongs_to :category

end
