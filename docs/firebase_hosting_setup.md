# 🚀 Firebase Hosting のデプロイ・反映手順

このドキュメントでは、`firebase.json` 内の `hosting` 設定や、公開用フォルダ（`public` フォルダなど）の変更内容を、本番環境の Firebase Hosting に反映させる手順を解説します。

---

## 📋 事前確認

### 1. `firebase.json` の設定内容

`firebase.json` にて、公開するディレクトリ（フォルダ）がどのように設定されているか確認します。  
通常は以下のように `public` ディレクトリが指定されています。

```json
"hosting": {
  "public": "public",
  "ignore": [
    "firebase.json",
    "**/.*",
    "**/node_modules/**"
  ]
}
```

- **`public`**: この設定の場合、プロジェクトのルートにある `public/` フォルダの中身（`index.html` など）がウェブ上に公開されます。

---

## 🛠️ デプロイ手順（ステップ・バイ・ステップ）

### ステップ 1: デプロイ先（対象プロジェクト）の確認

デプロイを実行する前に、意図したFirebaseプロジェクト（開発環境や本番環境など）に接続されているか確認します。  
ターミナルでプロジェクトのルートディレクトリに移動し、以下のコマンドを実行します。

```bash
firebase use
```

- **出力例**: `* dev (flutter-template-dev-ef459)`
- 現在アクティブなプロジェクトの横に `*` マークが表示されます。もし接続先を変更したい場合は `firebase use <プロジェクト名>` で切り替えてください。

---

### ステップ 2: Hosting のみのデプロイを実行

Functionsなど他のモジュールに影響を与えず、Hostingの設定と公開用ファイルのみを安全に反映させるため、**`--only hosting`** オプションを指定して実行します。

```bash
firebase deploy --only hosting
```

---

### ステップ 3: 反映完了の確認

デプロイが正常に完了すると、ターミナルに以下のような完了ログと公開用のURLが表示されます。

```text
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/your-project-id/overview
Hosting URL: https://your-project-id.web.app
```

表示された `Hosting URL` （ `https://[プロジェクトID].web.app` など）にブラウザでアクセスし、変更内容（ページ内容やヘッダー設定等）が正しく反映されていることを確認します。

---

## 💡 便利なTips

- **Firebase Hosting サーバーへのアップロード（デプロイ）から除外したい場合**：  
  Firebase Hosting への公開時にアップロード対象から除外したいファイルやパターンは、`firebase.json` の `"ignore"` 配列の中に指定します。
  > ⚠️ **【重要】**  
  > `"ignore"` に記述したファイルは Hosting へのデプロイから除外されるだけであり、**Git のコミット（管理）は防止されません。**  
  > APIキーやローカルの秘密ファイルなどの秘密情報が GitHub 等に誤ってコミットされて流出するのを防ぐ場合は、本設定ではなく、必ず **`.gitignore`** ファイルに対象のファイルを追加してください。
- **ローカルでの事前確認（エミュレータ起動）**：  
  実際にデプロイする前に、PCローカル上で表示を確認したい場合は、以下のコマンドでHostingエミュレータを立ち上げることができます。

  ```bash
  firebase emulators:start --only hosting
  ```
