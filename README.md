プライムビデオ、dアニメストア、バンダイCHから番組メタデータを吸い取ります。
Jellyfin用のメタデータファイルを生成します。


## 事前準備

1. install

```
npm i
ln -s  $PWD/create-nfo.js  /usr/local/bin/create-nfo
```

2. ブックマークレットを作成する
    - 名前：`動画情報` (適当でおｋ）
    - アドレス: `javascript:(steal-html.min.jsの中身)`


## 吸い取り手順

1. アマプラ、ｄアニメストア、バンダイChの番組ページを開く

1. ブックマークレットを押す

1. 成功した場合、JSONデータが表示され、テキストファイルが生成されるので、それをダウンロードするか、JSONデータをクリップボードにコピーする

1. 番組ディレクトリから

    ```
    cat 番組.json | create-nfo 1 imgs
    ```

    - season 1 以外の場合、`create-nfo [SEASON番号]`
    - サムネをダウンロードしない場合、第２引数の`imgs`は省略

