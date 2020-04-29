require 'rails_helper'

RSpec.describe '/tasks', type: :feature do
  let!(:category) { create(:category, name: '学習') }
  let!(:category2) { create(:category, name: 'プライベート') }
  let!(:task) { create(:task, title: 'AWSの勉強をする', category: category) }

  scenario 'タスクを登録して削除する' do
    feature_date = 2.days.since.to_date
    visit tasks_path

    expect(page).to have_content 'タスク一覧'
    expect(page).to have_content 'AWSの勉強をする'

    click_on '新しくタスクを登録する'

    expect(current_path).to eq new_task_path
    expect(page).to have_content 'タスク登録'

    fill_in 'タイトル', with: 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほま'
    fill_in '優先順位', with: 0
    fill_in 'コード', with: '____'
    fill_in '期限日', with: Date.current.yesterday
    check '期限が過ぎたら通知する'

    click_on '登録する'

    expect(page).to have_content 'タスク登録'
    expect(page).to have_content '表示されているエラーを正しく入力してください'
    expect(page).to have_content 'タイトルは30文字以内で入力してください'
    expect(page).to have_content '内容を入力してください'
    expect(page).to have_content '優先順位は0より大きい値にしてください'
    expect(page).to have_content 'ステータスを入力してください'
    expect(page).to have_content 'コードは不正な値です'
    expect(page).to have_content '期限日は未来の日付に設定してください'

    fill_in 'タイトル', with: '食卓を買う'
    fill_in '内容', with: 'IKEAに行って食卓の机と椅子のセットを購入する。'
    select 'プライベート', from: 'カテゴリ'
    fill_in '優先順位', with: 2
    choose '無効'
    fill_in 'コード', with: 'Task05'
    fill_in '期限日', with: feature_date.to_s
    check '期限が過ぎたら通知する'

    click_on '登録する'

    expect(current_path).to eq tasks_path
    expect(page).to have_content '食卓を買う'

    expect(Task.last).to have_attributes(title:     '食卓を買う',
                                         body:      'IKEAに行って食卓の机と椅子のセットを購入する。',
                                         category:  category2,
                                         priority:  2,
                                         status:    'disabled',
                                         notice:    true,
                                         code:      'Task05',
                                         limited_on: feature_date)

    within all('table tr')[1] do
      click_link '削除'
    end

    expect(current_path).to eq tasks_path
    expect(page).to_not have_content '食卓を買う'

    expect(Task.count).to eq 1
  end

  scenario 'タスクを更新する' do
    visit tasks_path

    expect(page).to have_content 'タスク一覧'
    expect(page).to have_content 'AWSの勉強をする'

    click_link '編集'

    expect(current_path).to eq edit_task_path(task)
    expect(page).to have_content 'タスク編集'

    fill_in 'タイトル', with: 'AWSのECSの勉強をする'
    click_on '更新する'

    expect(page).to have_content 'タスク一覧'
    expect(page).to have_content 'AWSのECSの勉強をする'
  end
end