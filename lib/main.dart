// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'editable_table_widget.dart';
import 'markdown_table_processing.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Markdown Table Extractor',
      home: MarkdownTableExtractor(),
    );
  }
}

/// -----------------------------------------------
/// [概要]   : Markdownテキストからテーブルを抽出し、編集可能なフォームとして表示するウィジェット
/// [作成者] : TCC S.Tate
/// [作成日] : 2023/12/26
/// -----------------------------------------------
class MarkdownTableExtractor extends StatefulWidget {
  /// コンストラクタは、Markdownテキスト処理ウィジェットを初期化する。
  ///
  /// `MarkdownTableExtractor` クラスは、Markdownテキストからテーブルを抽出し、
  /// それらを編集可能なフォームとしてユーザーに表示する機能を提供する。
  const MarkdownTableExtractor({super.key});

  @override
  _MarkdownTableExtractorState createState() => _MarkdownTableExtractorState();
}

class _MarkdownTableExtractorState extends State<MarkdownTableExtractor> {
  List<String> tables = []; // マークダウンのテーブルを保持するリスト
  List<String> nonTableTexts = []; // マークダウンのテーブル以外のテキストを保持するリスト
  String markdownText = '''
| ヘッダ1 | ヘッダ2 | ヘッダ3 |
| --- | --- | --- |
| データ1 | データ2 | データ3 |
| データ4 | データ5 | データ6 |

これはテーブルの間に挿入されたテキストです。

## サブセクション

- リストアイテム1
- リストアイテム2

> 引用文

## 見出し付きテーブル

| 左揃え | 中央揃え | 右揃え |
| :--- | :----: | ---: |
| 左 | 中央 | 右 |

これは別のセクションです。

### さらに小さいセクション

1. 番号付きリスト1
2. 番号付きリスト2

    コードブロック:
    ```
    print("Hello World")
    ```

以下、別のテーブルです。

| 単一のセル |
| :---: |
| 単一のデータ |

これでテスト用のマークダウン文字列は終わりです。
''';
  final MarkdownTableProcessor tableProcessor = MarkdownTableProcessor();
  @override
  void initState() {
    super.initState();
    // 初期化時にMarkdownテキストからテーブルを抽出する
    tables = tableProcessor.extractMarkdownTables(markdownText,
        includeHeading: true);
    // 初期化時にMarkdownテキストからテーブル以外のテキストを抽出する
    nonTableTexts =
        tableProcessor.extractNonTableMarkdownSections(markdownText);

    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
    print(markdownText);
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
    print('+++++++++++++++++++++++++++++++++++++');
    for (var bbb in nonTableTexts) {
      print(bbb);
    }
    print('+++++++++++++++++++++++++++++++++++++');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Table Extractor and Editor'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(children: [
                  ListView.builder(
                    shrinkWrap: true, // このリストの高さをそのコンテンツに合わせる
                    physics:
                        const NeverScrollableScrollPhysics(), // このリストのスクロールを無効にする
                    itemCount: tables.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: EditableTableWidget(
                            tableMarkdown: tables[index],
                            readOnly: false,
                            titleAlignment: TextAlign.left,
                            headerAlignment: TextAlign.center,
                            isRowEditingEnabled: true, // 行編集を有効にする
                            isColumnEditingEnabled: true, // 列編集を有効にする
                            isAlignmentControlEnabled: true, // 文字寄せの制御を有効にする
                            onTableChanged: (markdown) {
                              setState(() {
                                tables[index] = markdown;
                                markdownText = tableProcessor
                                    .mergeEditedTablesIntoMarkdown(
                                        markdownText, tables);
                                print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
                                print(markdownText);
                                print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');

                                // 初期化時にMarkdownテキストからテーブル以外のテキストを抽出する
                                nonTableTexts = tableProcessor
                                    .extractNonTableMarkdownSections(
                                        markdownText);
                                print('+++++++++++++++++++++++++++++++++++++');
                                for (var bbb in nonTableTexts) {
                                  print(bbb);
                                }
                                print('+++++++++++++++++++++++++++++++++++++');
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ]),
              ),
              // テーブル以外のmarkdownを表示する
              // Card(
              //   child: Container(
              //     width: 500,
              //     padding: const EdgeInsets.all(8.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: nonTableTexts.map((text) => Text(text)).toList(),
              //     ),
              //   ),
              // ),
              // markdownを表示する
              const SizedBox(height: 24),
              Card(
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(8.0),
                  child: MarkdownBody(data: markdownText),
                ),
              ),
              // markdown文字列を表示する
              const SizedBox(height: 24),
              Card(
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(8.0),
                  child: Text(markdownText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
