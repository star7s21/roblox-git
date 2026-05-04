# Roblox 津波ゲーム

Roblox上で動作する、津波サバイバル＋収集＋成長システムを組み合わせたゲームです。

---

## ゲーム概要

プレイヤーは津波から逃げながら、マップ上の宝物（Treasure）を回収し、基地に運ぶことでコインを生成できます。  
コインはステータス強化（スピード）に使用できます。

---

## 実装済み機能

### ワールド
- マップ生成
- 津波の自動生成・挙動

### アイテムシステム
- アイテムの自動配置
- アイテム取得（持ち上げ）
- アイテムドロップ機能
- アイテム情報管理（レアリティ対応）

### Bass（基地）
- Bass生成
- アイテムをBassに配置
- 配置アイテムからコイン生成

### 成長システム
- コイン管理
- コイン → スピード変換

### データ
- 設定の保存と復元（Leaderstats）

---

## プロジェクト構成

```bash
Workspace
┗Part：マップ生成用パーツ
ReplicatedStorage
┣Treasures(Folder)：各アイテムのパーツ
┃　┣CommonTreasure(Model)
┃　┣EpicTreasure(Model)
┃　┣LegendaryTreasure(Model)
┃　┗RareTreasure(Model)
┗DropTreasureEvent(RemoteEvent)：アイテム手放すイベント
ServerScriptService
┗Server(Folder)
　┣Services(Folder)
　┃　┣Treasure(ModuleScript)：アイテムに触れたときの動作
　┃　┗TreasureConfig(ModuleScript)：アイテム情報
　┗Controllers(Folder)
　　┣Bass(script)：基地動作（アイテム配置/コイン生成）
　　┣Death(script)：死んだときにもっているアイテムを破棄する動作
　　┣Drop(script)：アイテムを手放す動作
　　┣Leaderstats(script)：情報の保存と復元
　　┣Main(script)：津波の動作
　　┣Speed(script)：コイン消費してスピードをあげる
　　┗TreasureSpawner(script)：アイテムの配置
ServerStorage
┗BassModel(Model)：Bassパーツ
StarterGui
┣Client(Folder)
┃　┣Drop(LocalScript)：ドロップボタンの動作
┃　┗Status(LocalScript)：共有情報の表示
┗DropUI（ScreenGUI）：ドロップボタン
　┗Frame（Frame）
　　┣Progress（Frame）
　　┃　┗Bar（Frame）
　　┗DropBotton（TextBotton）
```

---

## 今後の開発予定

- Rebirth（転生システム）の実装

---

## 開発メモ

- 宝物のレアリティ設計済み（Common / Rare / Epic / Legendary）
- サーバー側中心のロジック設計
- RemoteEventを使ったドロップ処理

---

## 備考

このプロジェクトは現在開発中です。  
バグ修正・バランス調整・新システム追加を随時行っています。
