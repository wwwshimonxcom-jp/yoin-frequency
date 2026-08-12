# YOIN frequency

YOIN frequencyは、音源解析から作ったYOIN用の周波数メニューを再生する、HTML/CSS/JavaScriptだけのシンプルなPWAです。

現在のアプリはスピーカー再生専用です。Pitchは音の高さ、Pulseは「トトト」の間隔として分けて扱い、各メニューの解析カーブをループ再生します。

## ローカルでの起動方法

PWAとService Workerの確認をする場合は、`file://`ではなくローカルサーバーで開いてください。

```bash
cd yoin-frequency
python3 -m http.server 8000
```

ブラウザで `http://localhost:8000` を開きます。

## 公開方法

NetlifyでGitHub連携済みの場合は、`main`へpushすると自動でProduction deployされます。Netlify Drop運用の場合は、このフォルダをドラッグ&ドロップして公開します。

GitHub Pagesで公開する場合は、`index.html`、`style.css`、`app.js`、`business-pulse-data.js`、`raw-menu-data.js`、`manifest.json`、`service-worker.js`、`icons/` をリポジトリへ配置し、Pagesの公開元を対象ブランチのルートに設定します。

## モード

| Mode | 用途 | Pitch | Pulse | ノイズ種別 |
| --- | --- | ---: | ---: | --- |
| Business | ビジネス能力の向上 | 95Hz | 約2.03〜11.96Hzの2レイヤー可変パルス | Pink |
| Creative | クリエイティブ能力の向上 | 約69.49〜248.75Hzの可変Pitch | 約2.03〜11.96Hzの2レイヤー可変パルス | Pink |
| Thoughts make things | 思考の現実化 | 95Hz | 約2.03〜11.96Hzの2レイヤー可変パルス | Brown |

ノイズ音量の初期値は0%なので、最初はノイズなしで再生されます。Noiseを上げた場合だけ、モードごとに選ばれたノイズ種別が鳴ります。

## 初期設定

- 出力: スピーカー固定
- Timer: 無制限
- Frequency: 50%
- Noise: 0%
- Master: 70%

## 再生位置

各メニューは解析された長さで1周として扱います。無制限タイマーでは終端後に先頭へ戻り、画面上のバーで現在の周回数と周回内の再生位置を表示します。

## 表示モード

- Full: 情報量が多い通常UIです。
- Compact: iPhoneの画面内で再生、停止、音量、モード、タイマーを操作しやすい圧縮UIです。

## 技術メモ

- HTML/CSS/JavaScriptのみ
- Web Audio API使用
- スピーカー専用のMono再生
- Pitch timelineは`OscillatorNode.frequency`へループスケジュール
- Pulse timelineは2本のGain変調レイヤーとして再現
- ノイズはPink/Brownを内部生成し、モードごとに自動選択
- 再生時はマスター音量0からフェードイン、停止時とタイマー終了時はフェードアウト
- `localStorage`で前回の設定を保存
- `manifest.json`と`service-worker.js`でPWA対応

## 注意事項

小さめの音量で使用してください。運転中や危険を伴う作業中の使用は避けてください。効果には個人差があります。

このアプリは医療目的のアプリではなく、効果を保証するものではありません。体調に違和感がある場合は使用を中止してください。
