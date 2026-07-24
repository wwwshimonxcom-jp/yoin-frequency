# YOIN Frequency

YOIN Frequencyは、音楽を聴きながら周波数音やホワイト・ピンク・ブラウンノイズを重ねて使うためのアプリです。

このリポジトリには、現在公開中のWeb版と、SwiftUIで開発しているiPhone・iPad版が入っています。

## 使いたい版を選ぶ

| 種類 | 状態 | 入口 |
| --- | --- | --- |
| Web版（PWA） | 公開中 | [Web版を開く](https://yoin-frequency.netlify.app) / [Web版の説明](./web/README.md) |
| iPhone・iPad版 | Phase 1 開発中 | [iOS版の説明](./ios/README.md) / [実機テスト項目](./ios/DEVICE_TEST_CHECKLIST.md) |

## フォルダ構成

```text
yoin-frequency/
├── web/          Web版（HTML / CSS / JavaScript / PWA）
├── ios/          iPhone・iPad版（SwiftUI / AVAudioEngine）
├── netlify.toml  Web版の公開設定
└── README.md     この総合案内
```

Web版とiOS版は、それぞれのフォルダ内だけで起動・開発できます。

## すぐに開く

### Web版

```bash
python3 -m http.server 8000 --directory web
```

ブラウザで `http://localhost:8000` を開きます。

### iPhone・iPad版

Xcodeで `ios/YOINFrequency.xcodeproj` を開きます。

## 公開とデータ管理

- Netlifyは `web/` だけを公開します。公開URLは従来どおりです。
- Web版のプリセットは `web/app.js`、iOS版のプリセットは `ios/YOINFrequency/Resources/presets.json` で管理しています。
- 録音の再分析結果を反映するときは、両方のプリセットを照合して更新します。

このアプリは医療目的のアプリではありません。最初は小さな音量で試してください。
