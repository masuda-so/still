# Still

[日本語](README.md) | [English](README.en.md)

## 概要

Stillは、完了した休憩の履歴を端末内に保存する、プライベートな休憩タイマーです。有効なProの利用権があれば、対応する端末と言語で端末上のアシスタントも利用できます。

## 主な機能と制約

### 主な画面

- Pauses
- Assistant
- Pro
- Settings

### 主な機能

完了した休憩はSwiftDataで端末内に保存します。1〜10分の時間設定、実行中の休憩の終了、最近の履歴の確認、個別の履歴削除に対応しています。

### アシスタントと購入

アシスタントには有効なProの利用権が必要です。対応する端末と言語でApple Foundation Modelsを使用します。外部のAIサービスは使用しません。

ローカルのStoreKit設定には、次の商品を定義しています。

- `llc.ether.still.pro.daily`：自動更新しない24時間のDaily Pass。
- `llc.ether.still.pro.monthly`：自動更新の月額プラン。
- `llc.ether.still.pro.yearly`：自動更新の年額プラン。

App Store Connectの商品登録、本番価格、審査用情報の準備は、別途必要なリリース作業です。

## 導入と使い方

Xcodeで`still.xcodeproj`を開き、共有スキーム`still`を選択します。
ビルドとテストの手順は[構成と検証](Docs/Structure.md)、端末要件とリリース条件は[リリース条件](Docs/Release.md)を参照してください。
ローカルStoreKit設定は購入テスト用で、本番販売が可能であることの証明ではありません。

## サポートと関連資料

- [リポジトリ構成と検証](Docs/Structure.md)
- [製品の範囲](Docs/Product.md)
- [プライバシーポリシー](Docs/Privacy.md)
- [利用規約](Docs/Terms.md)
- [実装の参照元](Docs/References.md)
- [リリース条件](Docs/Release.md)
- [App Store提出記録](Docs/App-Store-Submission.md)
- [第三者の権利表記](THIRD_PARTY_NOTICES.md)

公開サイトのパス：

- `https://ether-llc.com/apps/still/privacy/`
- `https://ether-llc.com/apps/still/terms/`
- `https://ether-llc.com/apps/still/support/`

署名、検証、アップロード、公開、リリースには、リポジトリ外での作業も必要です。

## 開発と貢献

GitHub Actionsでは通常CIに加え、StoreKit専用CIで購入関連の9件を検証します。同じ取引IDの完了処理を確認し、対象1件の単独実行と全9件の実行を比較します。実行環境・残る警告・検証範囲は[構成と検証](Docs/Structure.md#continuous-integration)を参照してください。CIでの成功は、実機や本番ストアでの動作を保証するものではありません。

製品の問い合わせ先は上記のサポートURLです。リポジトリを変更する場合は、上記の実装の参照元とリリース条件を確認し、変更内容と検証結果をPRに記載してください。PRの説明とレビューコメントは日本語を基本とします。利用者が別の言語を指定した場合は、その指定を優先します。

作業時の共通方針は[AGENTS.md](AGENTS.md)を参照してください。
