# Phase 1 実機テスト — iPhone 16

対象: iPhone 16 / iOS 26.3.1(a)

## 最初のインストール

- [ ] iPhoneをMacへ接続し、ロックを解除する
- [ ] Xcodeで `YOINFrequency.xcodeproj` を開く
- [ ] `YOINFrequency` targetのSigning & Capabilitiesで自分のTeamを選ぶ
- [ ] 実行先を接続したiPhone 16にしてRunする
- [ ] iPhone側で開発者モードや信頼確認が出た場合は案内に従う

## 最優先の確認

### Apple Musicとの同時再生

- [ ] Apple Musicを先に再生する
- [ ] YOIN Frequencyを開き、AirPods接続中にFocusを再生する
- [ ] Apple Musicが止まらず、2つの音が重なって聞こえる
- [ ] Master / Tone / Noiseを動かしてもApple Music側の音量は変わらない
- [ ] 下部の音符ボタンからApple Musicパネルを引き出せる
- [ ] 初回だけApple Music操作へのアクセス確認が表示される
- [ ] パネルの再生 / 一時停止 / 前の曲 / 次の曲がMusicアプリに反映される

### バックグラウンド・画面ロック

- [ ] 2つを同時再生したままホーム画面へ戻る
- [ ] iPhoneをロックして2分以上待ってもYOINの音が続く
- [ ] ロック画面の再生操作はApple Music側のままになっている

Phase 1ではApple Musicとの競合を避けるため、YOIN独自のロック画面ボタンはまだ表示しません。

### 出力先の切替

- [ ] BinauralをAirPodsとiPhoneスピーカーの両方で再生できる
- [ ] MonauralをAirPodsとiPhoneスピーカーの両方で再生できる
- [ ] 再生中にAirPodsを接続すると、タイマーとモードを保ったままAirPodsへ移る
- [ ] 再生中にAirPodsを外すと、タイマーとモードを保ったまま本体出力へ移る
- [ ] 出力切替で二重再生、再起動ループ、タイマーのリセットが起きない

### 電話・音声割り込み

- [ ] 再生中に着信または通話を開始するとYOINが止まる
- [ ] 通話中にiPhoneスピーカーへYOIN音が混ざらない
- [ ] 通話後はiOSが再開を許可した場合だけYOINが再開する
- [ ] 通話中に出力先が変わっても、通話中はYOINが鳴らない

## 機能確認

- [ ] Focus / Zone 528 / Relax / Sleep / Schumannを順に選べる
- [ ] Focus: BinauralでLeft 200Hz / Right 214Hz / Diff 14Hz表示
- [ ] Schumann: BinauralでLeft 200Hz / Right 207.83Hz / Diff 7.83Hz表示
- [ ] Business / Business PitchでPulse 3.54–11.92Hz、タイマー29:50になる
- [ ] Creative / Creative PitchでPulse 2.53–11.7Hz、タイマー20:00になる
- [ ] Business Pitch / Creative PitchでPitch範囲が表示され、再生できる
- [ ] Focus: Monauralでモノラル変調になる
- [ ] 再生中にBinaural / Monauralを切り替えても残り時間と曲線位置が保たれる
- [ ] Noise Only: Toneが0%かつ操作不可になる
- [ ] White / Pink / Brown / Mixを切り替えられる
- [ ] Master / Tone / Noiseの値が再起動後も保存される
- [ ] 15分 / 20分 / 29:50 / 30分 / 60分 / 90分 / 無制限を切り替えられる
- [ ] タイマー終了時に約5秒かけて停止する
- [ ] 手動Stop時に急に切れず、短くフェードアウトする

## 不具合を見つけたときに残す情報

- 発生した操作順
- Apple Musicの再生有無
- Binaural / Monauralのどちらか
- AirPodsなどの出力先
- 画面ロック中か、通話前後か
- 表示されたエラーメッセージのスクリーンショット
