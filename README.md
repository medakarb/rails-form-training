## 概要
- RailsのModelのバリデーションとgemのSimpleFormの学習用

### Version
- ruby 2.6.5
- rails 6.0.2.2
- sqlite3 1.4.2

## 環境構築
### アプリ初期設定
```
bundle install --path vendor/bundle
yarn install
```

### データベース初期設定

```
$ bundle exec rails db:create
$ bundle exec rails db:migrate
$ bundle exec rails db:seed
```

## トレーニング
### 手順
１. ブランチ切り替え

```
$ git checkout start-training
```

２. 課題の実装スタート

### 課題1 バリデーション実装
- Rspecが通るようにバリデーションを設定しよう
  - 以下のコマンドを実行して全てテストが通るように `app/model/task.rb` にコードを追加する
    - `bundle exec rspec ./spec/models/task_spec.rb`
- 項目毎の仕様
  - `title`
    - 必須
    - 30文字以内
  - `body`
    - 必須
  - `priority`
    - 必須
    - 整数で0より大きい数字
  - `status`
    - 必須
    - 文字列で `enabled` もしくは `disabled` のみ 
      - gemの `enumerize` を使用
  - `code`
    - 必須ではないがユニーク
    - 半角英数字で6文字以上
  - `limited_on`
    - 現在日以降
      - 独自バリデーションを利用
    - 値が変わった時のみチェックする

### 課題2 フォーム実装
- Rspecが通るようにフォームを実装しよう
  - 以下のコマンドを実行してテストが通るように `app/views/tasks/_form.html.slim` にコードを追加しよう
    - `bundle exec rspec ./spec/features/task_spec.rb`
- 項目毎の仕様
  - `title`
    - テキストボックス
  - `body`
    - テキストエリア
  - `category`
    - 選択リスト
      - 空は許容しない
  - `priority`
    - テキストボックス(数値入力)
  - `status`
    - ラジオボタン
      - 有効・無効
  - `code`
    - テキストボックス
  - `limited_on`
    - テキストボックス
      - フォームをクリックするとカレンダーが表示するように
        - `bootstrap-datepicker` を利用
  - `notice`
    - チェックボックス

### 完成画面
#### 登録画面
<img width="953" alt="RailsFormTraining" src="https://user-images.githubusercontent.com/592230/80862324-08060880-8caf-11ea-8208-9dbf4ad4d722.png">


#### 登録画面(エラー時)
<img width="855" alt="RailsFormTraining" src="https://user-images.githubusercontent.com/592230/80862351-38e63d80-8caf-11ea-9f12-729cedafd177.png">
