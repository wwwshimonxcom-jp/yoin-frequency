# YOIN Frequency iPhone・iPad版

SwiftUIとAVAudioEngineで作るネイティブ版です。Web版は [`../web/`](../web/README.md)、iOS版はこのディレクトリで分けて管理します。

## Phase 1

- Web版と同じ全10モード
  - Focus / Zone 528 / Relax / Sleep / Schumann
  - Business / Business Pitch / Creative / Creative Pitch
  - Noise Only
- Business / Creative系の時間変化するPulse・Pitchカーブとループ
- White / Pink / Brown / Mix noise
- Binaural（左右別）/ Monaural（左右同一・モノラル変調）
- Binaural / Monauralとも、ヘッドホンと本体スピーカーの両方に対応
- Master / Tone / Noise volume
- 15分 / 20分 / 29:50 / 30分 / 60分 / 90分 / 無制限タイマー
- Apple Musicなどとの同時再生（`mixWithOthers`）
- 下から引き出すApple Music再生・一時停止・前後送りパネル
- バックグラウンド再生
- 通話割り込み後の安全な復帰
- AirPods・有線・本体スピーカー間の出力切替後も再生を継続

周波数や録音分析結果は `YOINFrequency/Resources/presets.json` から読み込みます。Pulse / Pitchの制御点もデータ化してあるため、後日の再分析時は主にこのJSONを差し替えて更新できます。

## 実機確認

1. `YOINFrequency.xcodeproj` をXcodeで開く
2. Signing & Capabilitiesで自分のTeamを選ぶ
3. iPhoneを接続し、実行先に選んでRunする
4. 初回だけApple Music操作へのアクセスを許可する
5. Apple Music再生中、バックグラウンド、画面ロック、通話、出力切替を確認する

詳しい合格条件は `DEVICE_TEST_CHECKLIST.md` にまとめています。

医療機器ではありません。最初は小さな音量で試してください。
