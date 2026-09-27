# YOIN Frequency

YOIN Frequencyは、周波数音とノイズを再生するアプリです。このリポジトリには公開中のWeb版と、SwiftUIで開発中のiPhone・iPad版が入っています。

| 種類 | 状態 | 入口 |
| --- | --- | --- |
| Web版（PWA） | 公開中 | [Web版を開く](https://yoin-frequency.netlify.app) / [Web版の説明](./web/README.md) |
| iPhone・iPad版 | Phase 1 開発中 | [iOS版の説明](./ios/README.md) |

## Web版

Web版は`web/`にあり、Netlifyはこのフォルダを公開します。`main`へプッシュするとProduction deployが走ります。

Web版はスピーカー向けのモノラル再生です。Business、Creative、Thoughts make things、Recovery、Energyは、解析済みの可変Pitchと2レイヤーPulseを使います。Pitchは音の高さ、Pulseは「トトト」の間隔です。元の録音ファイルはアプリへ含めません。

Recoveryは29分50秒、Energyは27分50秒を1周として、無制限時は先頭からループします。再生位置バーでは周回数と現在位置を確認・操作できます。

## ローカル起動

```bash
python3 -m http.server 8000 --directory web
```

ブラウザで `http://localhost:8000` を開きます。

このアプリは医療目的ではありません。小さめの音量で使用し、体調に違和感がある場合は使用を中止してください。
