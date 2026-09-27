# YOIN Frequency Web版

YOIN Frequency Web版は、周波数音とノイズを再生するPWAです。公開URLは https://yoin-frequency.netlify.app です。

## モード

Web版はスピーカー向けのモノラル再生です。Pitchは音の高さ、Pulseは「トトト」の間隔として別々に扱います。

| Mode | 用途 | Tone / Pitch | Pulse | 初期ノイズ種別 |
| --- | --- | ---: | ---: | --- |
| Business | ビジネス能力の向上 | 95Hz | 解析済み2レイヤー可変Pulse | Pink |
| Creative | クリエイティブ能力の向上 | 可変Pitch | 解析済み2レイヤー可変Pulse | Pink |
| Thoughts make things | 思考の現実化 | 95Hz | 解析済み2レイヤー可変Pulse | Brown |
| Recovery | 体力回復 | 約68.5〜180.25Hzの可変Pitch | 約2.03〜11.96Hzの2レイヤー可変Pulse | Brown |
| Energy | エネルギー | 約69.25〜166Hzの可変Pitch | 約2.03〜11.96Hzの2レイヤー可変Pulse | Pink |

Recoveryは29分50秒、Energyは27分50秒を1周として、無制限時は先頭からループします。再生位置バーでは周回数と現在位置を確認・操作できます。Noise volumeの初期値は0%です。

## ローカル起動

PWAとService Workerの確認にはローカルサーバーを使います。

```bash
python3 -m http.server 8000
```

この`web/`フォルダで実行し、ブラウザで `http://localhost:8000` を開きます。

## 公開

Netlifyはこの`web/`フォルダを公開します。GitHub連携済みのため、`main`へのプッシュでProduction deployが実行されます。

このアプリは医療目的ではありません。小さめの音量で使用し、体調に違和感がある場合は使用を中止してください。
