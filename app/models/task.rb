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

  enumerize :status, in: %i(enabled disabled)

  validates :title, presence: true, length: { maximum: 30 }
  validates :body, presence: true
  validates :priority, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :status, presence: true
  validates :code, uniqueness: true, format: { with: /\A[0-9a-zA-Z]{6,}\z/ }, allow_blank: true

  validate :require_future, if: proc { |record| record.limited_on != record.limited_on_was }

  def require_future
    errors.add(:limited_on, 'は未来の日付に設定してください') if limited_on.present? && limited_on < Date.current
  end
end
