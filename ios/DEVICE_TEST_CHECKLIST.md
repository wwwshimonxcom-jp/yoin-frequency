# Phase 1 実機テスト — iPhone 16・Mac

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
- [ ] Master / Frequency / Noiseを動かしてもApple Music側の音量は変わらない
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

- [ ] 初回起動時がFocus / Master 70% / Frequency 50% / Noise 0% / タイマー無制限になる
- [ ] Business / Creative / Thoughts make things / Schumann / Zone 528 / Focus / Relax / Sleep / Noise Onlyの順に表示される
- [ ] Focus: BinauralでLeft 200Hz / Right 214Hz / Diff 14Hz表示
- [ ] Schumann: BinauralでLeft 200Hz / Right 207.83Hz / Diff 7.83Hz表示
- [ ] Business / Creative / Thoughts make thingsで2層のPulse情報とPitch情報が表示される
- [ ] Business / Creative / Thoughts make thingsで2層Pulseが時間変化し、片方だけでなく両方が音へ反映される
- [ ] Creativeで時間変化するPitchが音へ反映される
- [ ] BusinessとThoughts make thingsで各分析データに収録されたPitchが音へ反映される
- [ ] 3つの分析モードで終端から先頭へ自然にループし、再生が止まらない
- [ ] 3つの分析モードでスクラブ位置を動かすと、その位置から音の変化を確認できる
- [ ] 再生中にスクラブしても、選択中のタイマー残り時間がリセットされない
- [ ] 分析データのループ周期とタイマーが独立し、モード選択だけでタイマー値が自動変更されない
- [ ] Focus: Monauralでモノラル変調になる
- [ ] 再生中にBinaural / Monauralを切り替えても残り時間とループ位置が保たれる
- [ ] Binaural / Monauralの両方をAirPodsとiPhoneスピーカーで再生できる
- [ ] Noise Only: Frequencyが0%かつ操作不可になる
- [ ] White / Pink / Brown / Mixを切り替えられる
- [ ] Master / Frequency / Noiseの値が再起動後も保存される
- [ ] 15分 / 20分 / 30分 / 60分 / 90分 / 無制限を切り替えられる
- [ ] タイマー終了時に約5秒かけて停止する
- [ ] 手動Stop時に急に切れず、短くフェードアウトする

## 不具合を見つけたときに残す情報

- 発生した操作順
- Apple Musicの再生有無
- Binaural / Monauralのどちらか
- AirPodsなどの出力先
- 画面ロック中か、通話前後か
- 表示されたエラーメッセージのスクリーンショット

## Mac Catalyst版

- [ ] `/Applications/YOIN Frequency.app` から起動できる
- [ ] Focusなどを再生し、MacからYOINの音が鳴る
- [ ] MacのMusicアプリを先に再生しても、YOINと同時に聞こえる
- [ ] Musicパネルの再生 / 一時停止 / 前の曲 / 次の曲がMusicアプリに反映される
- [ ] YOINのウィンドウを非アクティブにしても再生が続く
- [ ] 再生中に左上の赤ボタンでウィンドウを閉じても音が続く
- [ ] Dockアイコンから開き直すと、再生状態・タイマー・ループ位置が維持されている
- [ ] `Command + Q`でアプリを終了すると音も止まる
- [ ] Binaural / Monaural、Noise、タイマー、分析モードのループとスクラブが動作する
