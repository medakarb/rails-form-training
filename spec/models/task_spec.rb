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
require 'rails_helper'

RSpec.describe Task, type: :model do
  describe '#valid?' do
    let(:task) { build(:task, title: title, body: body, priority: priority, status: status, code: code, limited_on: limited_on) }
    let(:title) { 'タイトル' }
    let(:body) { '本文' }
    let(:priority) { 1 }
    let(:status) { :enabled }
    let(:code) { 'Task01' }
    let(:limited_on) { Date.current }
    subject { task.valid? }

    context 'title' do
      context '空の場合' do
        let(:title) { nil }
        it { is_expected.to be_falsey }
      end

      context '30文字以上の場合' do
        let(:title) { 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほま' }
        it { is_expected.to be_falsey }
      end

      context '正しく入力されている場合' do
        let(:title) { 'AWS学習' }
        it { is_expected.to be_truthy }
      end
    end

    context 'body' do
      context '空の場合' do
        let(:body) { nil }
        it { is_expected.to be_falsey }
      end

      context '正しく入力されている場合' do
        let(:body) { 'AWSの書籍を読む' }
        it { is_expected.to be_truthy }
      end
    end

    context 'priority' do
      context '空の場合' do
        let(:priority) { nil }
        it { is_expected.to be_falsey }
      end

      context '数字じゃない場合' do
        let(:priority) { 'test' }
        it { is_expected.to be_falsey }
      end

      context '数字じゃない場合' do
        let(:priority) { 'test' }
        it { is_expected.to be_falsey }
      end

      context '0の場合' do
        let(:priority) { 0 }
        it { is_expected.to be_falsey }
      end

      context '整数かつ0より大きい場合' do
        let(:priority) { 10 }
        it { is_expected.to be_truthy }
      end
    end

    context 'status' do
      context '空の場合' do
        let(:status) { nil }
        it { is_expected.to be_falsey }
      end

      context '利用できない文字の場合' do
        let(:status) { 'test' }
        it { is_expected.to be_falsey }
      end

      context '利用できる文字の場合' do
        let(:status) { 'enabled' }
        it { is_expected.to be_truthy }
      end
    end

    context 'code' do
      context '空の場合' do
        let(:code) { nil }
        it { is_expected.to be_truthy }
      end

      context '桁数が6に満たない場合' do
        let(:code) { 'test' }
        it { is_expected.to be_falsey }
      end

      context 'すでに同じコードのタスクがある場合' do
        let(:code) { 'Task02' }
        let!(:task2) { create(:task, code: 'Task02') }
        it { is_expected.to be_falsey }
      end

      context '半角英数字以外の文字が含まれている場合' do
        let(:code) { 'Task02_' }
        it { is_expected.to be_falsey }
      end

      context '半角英数字のみの場合' do
        let(:code) { 'Task03' }
        it { is_expected.to be_truthy }
      end
    end

    context 'limited_on' do
      context '空の場合' do
        let(:limited_on) { nil }
        it { is_expected.to be_truthy }
      end

      context '過去の日付の場合' do
        let(:limited_on) { Date.current.yesterday }
        it { is_expected.to be_falsey }
      end

      context '現在の日付の場合' do
        let(:limited_on) { Date.current }
        it { is_expected.to be_truthy }
      end

      context '未来の日付の場合' do
        let(:limited_on) { Date.current.tomorrow }
        it { is_expected.to be_truthy }
      end
    end

    context 'タスクを登録後にlimited_onが過去になってからlimited_on以外の項目を更新する場合' do
      let(:task) { create(:task) }
      before do
        task.update_column(:limited_on, 2.days.ago.to_date)
        task.title = 'テスト'
      end

      it { is_expected.to be_truthy }
    end
  end
end
