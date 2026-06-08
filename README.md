# Roblox 津波サバイバル タイクーン （仮）

Roblox上で動作する、津波サバイバル、アイテム収集、および基地建設を組み合わせたゲームです。

---

## ゲーム概要

プレイヤーは迫りくる津波から逃げながら、マップ上に出現する宝物（Treasure）を回収します。  
回収した宝物を自分の基地のスロットに持ち帰ることで、コインを自動生成できます。  
貯まったコインを使って移動速度の強化や、リバース（転生）によるさらなる成長を目指します。

---

## 実装済み機能

### サバイバル & ウェーブ
- 津波の自動生成と動的な物理挙動
- ウェーブ制によるゲーム進行管理（`Main.server.lua`）

### 宝物（Treasure）システム
- マップ上へのランダムスポーン機能（`TreasureSpawner.server.lua`）
- レアリティ設定（Common / Rare / Epic / Legendary）
- 自動取得、持ち運び、およびUIボタンによる手動ドロップ機能

### 基地システム
- プレイヤーごとの基地自動割り当てとスロット管理（`Base.server.lua`）
- 基地に配置した宝物から、リバース倍率に応じたコインを自動生成
- 基地内の配置アイテム情報の永続化（セーブ・ロード対応）

### 成長 & 強化
- コインを消費した移動速度（WalkSpeed）のアップグレード（`Speed.server.lua`）
- コインを消費したジャンプ力（JumpPower）のアップグレード（`Jump.server.lua`）
- リバース（Rebirth）システムによるステータスリセットと収益倍率の強化

### 管理ツール & 課金
- 管理者権限を持つプレイヤー専用のデバッグ・操作UI（`AdminPanel.client.lua` / `AdminManager.server.lua`）
- ゲームパスや開発者プロダクト（Robux購入）の処理と設定（`MarketplaceManager.lua` / `MarketplaceConfig.lua`）

### データ管理
- DataStoreを使用したコイン、スピード、ジャンプ、リバース回数、基地内アイテムの保存（`Leaderstats.server.lua`）

---

## プロジェクト構成

Rojoを利用したディレクトリ構成を採用しています。

```text
Src
┣ Client                 -- クライアント側スクリプト
┃ ┣ AdminPanel.client.lua -- 管理者パネルのUI制御
┃ ┣ Drop.client.lua      -- 宝物のドロップUI表示・通信
┃ ┣ Jump.client.lua      -- ジャンプ強化プロンプトの更新
┃ ┣ Speed.client.lua     -- スピード強化プロンプトの更新
┃ ┣ Status.client.lua    -- 画面上部ステータス（リバース/コイン/スピード/ジャンプ等）表示
┃ ┗ TreasurePrompt.client.lua -- 宝物の取得プロンプト制御
┣ Server                 -- サーバー側スクリプト（ServerScriptService）
┃ ┣ AdminManager.server.lua -- 管理者判定および管理機能の制御
┃ ┣ Controllers          -- 各種ゲームロジック
┃ ┃ ┣ Base.server.lua            -- 基地生成、スロット、コイン生成、アップグレード
┃ ┃ ┣ Death.server.lua           -- 死亡時のアイテムドロップ
┃ ┃ ┣ Drop.server.lua            -- 手動ドロップ要求の処理
┃ ┃ ┣ Jump.server.lua            -- ジャンプ力強化の検証と適用
┃ ┃ ┣ Leaderstats.server.lua     -- データのセーブ・ロード
┃ ┃ ┣ Main.server.lua            -- 津波の生成・ウェーブループ
┃ ┃ ┣ Rebirth.server.lua         -- リバース処理
┃ ┃ ┣ Speed.server.lua           -- スピード強化の検証と適用
┃ ┃ ┗ TreasureSpawner.server.lua -- 宝物のスポーン管理
┃ ┗ Services              -- サービス・共通設定モジュール
┃   ┣ MarketplaceConfig.lua -- 課金プロダクト・ゲームパスの設定
┃   ┣ MarketplaceManager.lua -- 課金トランザクションの処理
┃   ┣ Treasure.lua        -- 宝物オブジェクトの初期化と取得ロジック
┃   ┗ TreasureConfig.lua  -- 宝物のパラメータ・レアリティ定義
┣ Shared                 -- サーバー・クライアント共通
┃ ┗ Utils.lua            -- 数値フォーマット等の共通関数ユーティリティ
┗ default.project.json    -- Rojoプロジェクト構成ファイル
```

Roblox Studioでのディレクトリ構成
```bash
Workspace
┗Part：マップ生成用パーツ
ReplicatedStorage
┣Treasures（Folder）：各アイテムのパーツ
┃　┣CommonTreasure（Model）
┃　┣EpicTreasure（Model）
┃　┣LegendaryTreasure（Model）
┃　┗RareTreasure（Model）
┗DropTreasureEvent（RemoteEvent）：アイテム手放すイベント
ServerStorage
┗BaseModel（Model）：基地パーツ
StarterGui
┗DropUI（ScreenGUI）：ドロップボタン
　┗Frame（Frame）
　　┗DropBotton（TextBotton）
```

---

## 今後の開発予定

- 基地の拡張機能
- 津波のバリエーション（高さ、速度、特殊ウェーブ）
- 新たなアビリティの追加

---

## 開発メモ

- サーバーサイド主導の設計により、セキュリティとデータの整合性を確保
- Rojo + Git による現代的なRoblox開発フロー
