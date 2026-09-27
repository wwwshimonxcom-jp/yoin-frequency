# YOIN Frequency iPhone・iPad・Mac版

SwiftUIとAVAudioEngineで作るネイティブ版です。iPhone・iPadに加え、AppleシリコンMacではMac Catalystアプリとして動作します。Web版はリポジトリの`main`ブランチ直下、ネイティブ版は`feature/ios-phase1`ブランチのこのディレクトリで管理します。

## Phase 1

- 最新Web版と同じ全9モード（表示順）
  - Business / Creative / Thoughts make things
  - Schumann / Zone 528 / Focus / Relax / Sleep / Noise Only
- Business / Creative / Thoughts make thingsの2層PulseとPitchカーブ
- 分析データの終端まで再生したあとのループと、ループ内の位置を動かせるスクラブ操作
- White / Pink / Brown / Mix noise
- Binaural（左右別）/ Monaural（左右同一・モノラル変調）
- Binaural / Monauralとも、ヘッドホンと本体スピーカーの両方に対応
- Master / Frequency / Noise volume
- 15分 / 20分 / 30分 / 60分 / 90分 / 無制限タイマー
- Apple Musicなどとの同時再生（`mixWithOthers`）
- 下から引き出すApple Music再生・一時停止・前後送りパネル
- バックグラウンド再生
- 通話割り込み後の安全な復帰
- AirPods・有線・本体スピーカー間の出力切替後も再生を継続

初回起動時はFocus、Master 70%、Frequency 50%、Noise 0%、タイマー無制限です。Business / Creative / Thoughts make thingsの分析データの長さはループ周期として扱い、タイマーはユーザーが選んだ設定で独立して動作します。

周波数や録音分析結果は `YOINFrequency/Resources/presets.json` から読み込みます。2層Pulse / Pitchの制御点もデータ化してあるため、後日の再分析時は主にこのJSONを差し替えて更新できます。

## 実機確認

1. `YOINFrequency.xcodeproj` をXcodeで開く
2. Signing & Capabilitiesで自分のTeamを選ぶ
3. iPhoneを接続し、実行先に選んでRunする
4. 初回だけApple Music操作へのアクセスを許可する
5. Apple Music再生中、バックグラウンド、画面ロック、通話、出力切替を確認する

詳しい合格条件は `DEVICE_TEST_CHECKLIST.md` にまとめています。

## Macで使う

1. `YOINFrequency.xcodeproj` をXcodeで開く
2. 実行先から `My Mac (Mac Catalyst)` を選ぶ
3. Runする

Mac版もiPhone版と同じプリセット・音声エンジン・画面を共有します。通常は `/Applications/YOIN Frequency.app` から起動できます。MacのMusicアプリとの同時再生、Music操作ボタン、ウィンドウを非アクティブにした後の再生継続を初回に確認してください。

医療機器ではありません。最初は小さな音量で試してください。
