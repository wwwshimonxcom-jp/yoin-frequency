# YOIN frequency

YOIN frequencyは、YOIN用の周波数音とノイズを再生する、HTML/CSS/JavaScriptだけのシンプルなPWAです。

現在のアプリはスピーカー再生専用です。Business / Creative / Thoughts make thingsは解析済みの2レイヤー版だけを通常名で残し、Pitchは音の高さ、Pulseは「トトト」の間隔として分けて扱います。

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

| Mode | 用途 | Tone / Pitch | Pulse | ノイズ種別 |
| --- | --- | ---: | ---: | --- |
| Business | ビジネス能力の向上 | 95Hz | 約2.03〜11.96Hzの2レイヤー可変パルス | Pink |
| Creative | クリエイティブ能力の向上 | 約69.49〜248.75Hzの可変Pitch | 約2.03〜11.96Hzの2レイヤー可変パルス | Pink |
| Thoughts make things | 思考の現実化 | 95Hz | 約2.03〜11.96Hzの2レイヤー可変パルス | Brown |
| Schumann | シューマン共振7.83Hzをイメージした瞑想・リラックス向け | 200Hz | 7.83Hz | Brown |
| Zone 528 | 528Hzをベースにした深い集中・ゾーン作業向け | 528Hz | 14Hz | Pink |
| Focus | 作業・読書・デザイン作業向け | 200Hz | 14Hz | Pink |
| Relax | 休憩・ストレッチ・夜のリラックス向け | 200Hz | 10Hz | Brown |
| Sleep | 入眠・寝落ち向け | 200Hz | 4Hz | Brown |
| Noise Only | 周波数なしでノイズだけ流すモード | - | - | Pink |

## ノイズ

Noise volumeの初期値は0%です。Noise type欄ではPink / Brown / White / Mixを選べます。モードを選び直したときは、そのモードに合うノイズ種別へ戻ります。

## 初期設定

- 出力: スピーカー固定
- Timer: 無制限
- Frequency: 50%
- Noise: 0%
- Master: 70%

## 再生位置

Business / Creative / Thoughts make thingsは解析された長さで1周として扱います。無制限タイマーでは終端後に先頭へ戻り、画面上のバーで現在の周回数と周回内の再生位置を表示します。このバーはスライダーとして操作でき、選んだ位置からPitch/Pulseを再開できます。

通常の固定周波数モードとNoise Onlyでは、再生位置バーは「通常再生」と表示します。

## 表示モード

- Full: 情報量が多い通常UIです。
- Compact: iPhoneの画面内で再生、停止、音量、モード、ノイズ、タイマーを操作しやすい圧縮UIです。

## 技術メモ

- HTML/CSS/JavaScriptのみ
- Web Audio API使用
- スピーカー専用のMono再生
- 固定周波数モードは1本のサイン波をLFOでゆらがせる
- 解析モードのPitch timelineは`OscillatorNode.frequency`へループスケジュール
- 解析モードのPulse timelineは2本のGain変調レイヤーとして再現
- ノイズはPink / Brown / White / Mixを内部生成
- 再生時はマスター音量0からフェードイン、停止時とタイマー終了時はフェードアウト
- `localStorage`で前回の設定を保存
- `manifest.json`と`service-worker.js`でPWA対応

## 注意事項

小さめの音量で使用してください。運転中や危険を伴う作業中の使用は避けてください。効果には個人差があります。

このアプリは医療目的のアプリではなく、効果を保証するものではありません。体調に違和感がある場合は使用を中止してください。
