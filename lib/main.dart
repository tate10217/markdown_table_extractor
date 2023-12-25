// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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

class MarkdownTableExtractor extends StatefulWidget {
  const MarkdownTableExtractor({super.key});

  @override
  _MarkdownTableExtractorState createState() => _MarkdownTableExtractorState();
}

class _MarkdownTableExtractorState extends State<MarkdownTableExtractor> {
  List<String> tables = []; // マークダウンのテーブルを保持するリスト
  List<TablePosition> tablePositions = []; // テーブルの位置を保持するリスト
  String markdownText = '''
# テスト用マークダウン0
1
これは通常のテキストです。以下にマークダウンのテーブルが続きます。2
3
| ヘッダ1 | ヘッダ2 | ヘッダ3 | 4 |
| ------- | ------- | ------- | --- |
| データ1 | データ2 | データ3 | 6 |
| データ4 | データ5 | データ6 | 7 |

これはテーブルの間に挿入されたテキストです。9
10
## サブセクション11
12
- リストアイテム113
- リストアイテム214
15
> 引用文16
17
### align属性付きテーブル18
19
| 左揃え | 中央揃え | 右揃え | 20 |
| :----- | :------: | -----: | --- |
| 左 | 中央 | 右 | 22 |

これは別のセクションです。 24
25
### さらに小さいセクション 26
27
1. 番号付きリスト1 28
2. 番号付きリスト2 29
30
    コードブロック:31
    ```
    print("Hello World")33
    ```
35
以下、別のテーブルです。36
37
| 単一のセル | 38 |
| ----------- | --- |
| 単一のデータ | 40 |

これでテスト用のマークダウン文字列は終わりです。42
''';

  @override
  void initState() {
    super.initState();
    tables = extractMarkdownTables(markdownText, includeHeading: true);
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
    print(markdownText);
    print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
  }

  /// マークダウンテキストからテーブルを抽出
  List<String> extractMarkdownTables(String markdown,
      {bool includeHeading = true}) {
    List<String> lines = markdown.split('\n'); // Markdownテキストを行に分割
    List<String> tables = [];
    bool inTable = false; // 現在テーブル内かを追跡
    bool textBetweenHeadingAndTable = false; // 見出しとテーブルの間にテキストがあるかを追跡
    StringBuffer currentTable = StringBuffer(); // 現在処理中のテーブルを構築
    String lastHeading = ''; // 最後に見つかった見出しを保持
    int startLineIndex = -1; // テーブルの開始位置を追跡
    int endLineIndex = -1; // テーブルの終了位置を追跡

    for (String line in lines) {
      var trimmedLine = line.trim(); // 行の前後の空白を削除

      // 見出し行を処理
      if (includeHeading && trimmedLine.startsWith('#')) {
        if (inTable) {
          // テーブル内に見出しがある場合は、現在のテーブルを終了
          tables.add(currentTable.toString());
          currentTable.clear();
          inTable = false;
        }
        lastHeading = trimmedLine; // 見出しを更新
        textBetweenHeadingAndTable = false; // 見出しとテーブルの間のテキストフラグをリセット
        continue;
      }

      // 空行を処理
      if (line.isEmpty || line.trim().isEmpty) {
        if (inTable) {
          // テーブル内の空行は、テーブルの終了を意味する
          tables.add(currentTable.toString());
          currentTable.clear();
          inTable = false;
        }
        continue;
      }

      // 見出しとテーブルの間にテキストがあるかをチェック
      if (!trimmedLine.startsWith('|') &&
          !trimmedLine.endsWith('|') &&
          !inTable) {
        textBetweenHeadingAndTable = true;
      }

      // テーブルの境界行を処理
      if (trimmedLine.startsWith('|') && trimmedLine.endsWith('|')) {
        if (!inTable) {
          // 新しいテーブルを開始
          inTable = true;
          if (includeHeading &&
              lastHeading.isNotEmpty &&
              !textBetweenHeadingAndTable) {
            currentTable.writeln(lastHeading); // 見出しをテーブルに追加
            lastHeading = ''; // 見出しをリセット
          }
        }
        currentTable.writeln(trimmedLine); // テーブル行を追加
      } else if (inTable) {
        // テーブル行ではない場合、テーブルの終了
        tables.add(currentTable.toString());
        currentTable.clear();
        inTable = false;
        lastHeading = '';
      }

      // テーブルの開始を追跡
      if (inTable && startLineIndex == -1) {
        startLineIndex = lines.indexOf(line); // テーブルの開始行を設定
        print('--------------------------------------------------');
        print('テーブルの開始行: $startLineIndex');
        print('$line');
      }
      // テーブルの終了を追跡
      if ((!inTable || line.trim() == '') && startLineIndex != -1) {
        endLineIndex = lines.indexOf(line) - 1; // テーブルの終了行を設定
        tablePositions.add(
            TablePosition(startLine: startLineIndex, endLine: endLineIndex));
        startLineIndex = -1; // リセット
        print('テーブルの終了行: $endLineIndex');
        print('${lines[endLineIndex]}');
        print('--------------------------------------------------');
      }
    }

    // 最後のテーブルを処理
    if (inTable) {
      tables.add(currentTable.toString());
    }

    return tables;
  }

  /// 編集されたテーブルを元のマークダウンテキストにマージ
  void mergeEditedTablesIntoMarkdown() {
    List<String> originalLines = markdownText.split('\n');
    List<String> mergedLines = [];
    int currentTableIndex = 0;
    // tablePositionsをdeepコピー
    List<TablePosition> newTablePositions = [];
    for (int i = 0; i < tablePositions.length; i++) {
      newTablePositions.add(TablePosition(
          startLine: tablePositions[i].startLine,
          endLine: tablePositions[i].endLine));
    }

    for (int i = 0; i < originalLines.length; i++) {
      List<String> aaa = []; //! debug
      if (currentTableIndex < tables.length &&
          i == tablePositions[currentTableIndex].startLine) {
        List<String> newTableLines = tables[currentTableIndex].split('\n');
        int offset = 0; // 現在のオフセット（行数の変化）

        // デバッグ出力: 編集前のテーブル位置と内容
        print('...................................................');
        print('編集前 - テーブル $currentTableIndex: '
            '開始行 ${tablePositions[currentTableIndex].startLine}, '
            '終了行 ${tablePositions[currentTableIndex].endLine}');
        print('編集前のテーブル内容:');
        for (int k = tablePositions[currentTableIndex].startLine;
            k <= tablePositions[currentTableIndex].endLine;
            k++) {
          print(originalLines[k]);
        }

        // 新しいテーブルの内容を追加
        mergedLines.addAll(newTableLines);

        // オフセット（行数の変化）を計算
        int originalTableLength = tablePositions[currentTableIndex].endLine -
            tablePositions[currentTableIndex].startLine +
            1;
        int editedTableLength = newTableLines.length;
        offset = editedTableLength - originalTableLength;

        // デバッグ出力: 編集されたテーブルの内容と行数
        print('編集されたテーブルの内容（$editedTableLength行）:');
        newTableLines.forEach((line) => print(line));

        // 元のテーブルの範囲をスキップ
        i = tablePositions[currentTableIndex].endLine;

        // 次のテーブルの位置を更新
        for (int j = currentTableIndex + 0; j < tablePositions.length; j++) {
          if (j > currentTableIndex) newTablePositions[j].startLine += offset;
          newTablePositions[j].endLine += offset;
          // デバッグ出力: offset
          aaa.add('\noffset: $offset  -> テーブル $j: '
              '開始行 ${newTablePositions[j].startLine}, '
              '終了行 ${newTablePositions[j].endLine}');
        }

        // デバッグ出力: 編集後のテーブル位置
        print('編集後 - テーブル $currentTableIndex: '
            '開始行 ${tablePositions[currentTableIndex].startLine}, '
            '終了行 ${tablePositions[currentTableIndex].endLine}');
        print(aaa);
        print('...................................................');

        currentTableIndex++;
      } else if (currentTableIndex >= tables.length ||
          i < tablePositions[currentTableIndex].startLine) {
        mergedLines.add(originalLines[i]);
      }
    }

    tablePositions = newTablePositions;
    markdownText = mergedLines.join('\n');
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
                            allowColumnEditing: true,
                            allowRowEditing: true,
                            onTableChanged: (markdown) {
                              setState(() {
                                tables[index] = markdown;
                                mergeEditedTablesIntoMarkdown();
                                print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
                                print(markdownText);
                                print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ]),
              ),
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

/* ---------------------------------------------------------------------------------------------------------------------------------------------------- */
class EditableTableWidget extends StatefulWidget {
  final String tableMarkdown;
  final bool readOnly;
  final TextStyle titleStyle;
  final TextAlign titleAlignment;
  final TextAlign headerAlignment;
  final bool allowRowEditing; // 行編集の許可フラグ
  final bool allowColumnEditing; // 列編集の許可フラグ
  final Function(String)? onTableChanged; // テーブルの変更を検知するコールバック関数

  const EditableTableWidget({
    Key? key,
    required this.tableMarkdown,
    this.readOnly = false,
    this.titleStyle = const TextStyle(fontWeight: FontWeight.bold),
    this.titleAlignment = TextAlign.left,
    this.headerAlignment = TextAlign.left,
    this.allowRowEditing = false,
    this.allowColumnEditing = false,
    this.onTableChanged,
  }) : super(key: key);

  @override
  _EditableTableWidgetState createState() => _EditableTableWidgetState();
}

class _EditableTableWidgetState extends State<EditableTableWidget> {
  List<List<TextEditingController>> _controllers = [];
  List<TextEditingController> headerControllers = [];
  String title = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeHeaderControllers();
  }

  // ヘッダーのテキストフィールドコントローラーを初期化
  void _initializeHeaderControllers() {
    if (widget.allowColumnEditing) {
      var headerRow = _controllers.first;
      headerControllers = headerRow
          .map((controller) => TextEditingController(text: controller.text))
          .toList();
    }
  }

  // ヘッダーの変更を処理
  void _onHeaderChanged() {
    if (widget.allowColumnEditing) {
      for (int i = 0; i < headerControllers.length; i++) {
        _controllers.first[i].text = headerControllers[i].text;
      }
      _onFieldChanged();
    }
  }

  void _initializeControllers() {
    // テーブルの各行を取得
    var rows = widget.tableMarkdown.trim().split('\n');
    // rowsの最初の行に"#"が含まれている場合は、見出し行として扱う
    if (rows.first.startsWith('#')) {
      rows.removeAt(0);
    }
    // テーブルデータを取得
    var tableData = rows
        .map((row) => row
            .split('|')
            .where((cell) => cell.isNotEmpty)
            .map((cell) => cell.trim())
            .toList())
        .toList();
    // テキストフィールドのコントローラーにテーブルデータを設定
    _controllers = tableData
        .map((row) =>
            row.map((cell) => TextEditingController(text: cell)).toList())
        .toList();
  }

  void _onFieldChanged() {
    var markdownTable = '';
    markdownTable += _controllers.map((row) {
      // 2行目だけテーブルの区切り文字が設定されていなければ、区切り文字を追加
      if (_controllers.indexOf(row) == 1) {
        for (int i = 0; i < row.length; i++) {
          if (row[i].text.trim() == '') {
            row[i].text = '---';
          }
        }
      }
      return '| ${row.map((cell) => cell.text).join(' | ')} |';
    }).join('\n');
    markdownTable += '\n';

    if (widget.onTableChanged != null) widget.onTableChanged!(markdownTable);
  }

  TextAlign _getTextAlignment(String separator) {
    if (separator.startsWith(':') && separator.endsWith(':')) {
      return TextAlign.center;
    } else if (separator.endsWith(':')) {
      return TextAlign.right;
    }
    return TextAlign.left;
  }

  void _addRow() {
    if (!widget.allowRowEditing) return;
    // すべての列に空のテキストフィールドコントローラーを追加
    setState(() {
      _controllers.add(List.generate(
          _controllers[0].length, (_) => TextEditingController()));
    });
    _onFieldChanged();
  }

  void _removeRow(int index) {
    if (!widget.allowRowEditing) return;
    // 指定された行を削除
    setState(() {
      _controllers.removeAt(index);
    });
    _onFieldChanged();
  }

  void _addColumn() {
    if (!widget.allowColumnEditing) return;
    // すべての行に新しい列を追加
    setState(() {
      // ヘッダー行に新しいコントローラーを追加
      if (headerControllers != null) {
        headerControllers.add(TextEditingController());
      }

      // 各データ行に新しいコントローラーを追加
      for (var row in _controllers) {
        row.add(TextEditingController());
      }
    });
    _onFieldChanged();
  }

  void _removeColumn(int index) {
    if (!widget.allowColumnEditing) return;
    // すべての行から指定された列を削除
    setState(() {
      for (var row in _controllers) {
        row.removeAt(index);
      }
    });
    _onFieldChanged();
  }

  @override
  Widget build(BuildContext context) {
    List<String> rows = widget.tableMarkdown.trim().split('\n');
    // rowsの最初の行に"#"が含まれている場合は、見出し行として扱う
    if (rows[0].startsWith('#')) {
      title = rows[0];
      rows.removeAt(0);
    }
    // テーブルデータを取得
    List<List<String>> tableData = rows
        .map((row) => row
            .split('|')
            .where((cell) => cell.isNotEmpty)
            .map((cell) => cell.trim())
            .toList())
        .toList();

    List<String> separators = tableData[1]; // テーブルの区切り文字を取得
    List<TextAlign> alignments =
        separators.map(_getTextAlignment).toList(); // 区切り文字からテキストの配置を取得

    // ヘッダー行の処理
    List<String> headers = tableData[0];
    List<Widget> headerWidgets = [];
    for (int i = 0; i < headers.length; i++) {
      headerWidgets.add(
        Expanded(
          child: widget.allowColumnEditing
              ? TextField(
                  controller: headerControllers[i],
                  readOnly: widget.readOnly,
                  textAlign: alignments[i],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  onChanged: (_) {
                    _onHeaderChanged();
                  },
                )
              : Text(
                  headers[i],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: widget.headerAlignment,
                ),
        ),
      );
      headerWidgets.add(const SizedBox(width: 8));
    }

    // データ行の処理
    List<Widget> rowWidgets = [];
    for (int i = 2; i < tableData.length; i++) {
      List<Widget> cellWidgets = [];
      for (int j = 0; j < tableData[i].length; j++) {
        cellWidgets.add(Expanded(
          child: TextField(
            controller: _controllers[i][j],
            readOnly: widget.readOnly,
            textAlign: alignments[j],
            onChanged: (_) {
              _onFieldChanged(); // テキストフィールドの変更を検知
            },
          ),
        ));
        cellWidgets.add(const SizedBox(width: 8));
      }
      // 行削除ボタン
      if (widget.allowRowEditing) {
        cellWidgets.add(
          IconButton.filled(
              tooltip: '行を削除',
              icon: Stack(children: [
                const Icon(Icons.table_rows_outlined),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                      color: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.remove_circle,
                          size: 14, weight: 700, grade: 200, opticalSize: 48)),
                ),
              ]),
              onPressed: () => _removeRow(i)),
        );
      } else if (widget.allowColumnEditing) {
        // 幅を調整するためのダミーウィジェット(透明な本物のボタンを表示)
        cellWidgets.add(const IconButton(icon: Icon(null), onPressed: null));
      }
      // 項目
      rowWidgets.add(Row(children: cellWidgets));
    }
    // 行追加ボタン
    if (widget.allowRowEditing) {
      rowWidgets.add(
        Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: IconButton.filledTonal(
                tooltip: '行を追加',
                icon: Stack(children: [
                  const Icon(Icons.table_rows_outlined),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.add_circle,
                            size: 14,
                            weight: 700,
                            grade: 200,
                            opticalSize: 48)),
                  ),
                ]),
                onPressed: _addRow,
              ),
            ),
          ),
        ]),
      );
    }

    return Column(children: [
      if (title.trim() != '')
        Row(children: [
          Expanded(
            child: Text(
              title.replaceAll('#', '').trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: widget.titleAlignment,
            ),
          ),
        ]),
      // テーブルヘッダー
      Row(
        children: [
          Expanded(child: Row(children: headerWidgets)),
          // 列追加ボタン
          widget.allowColumnEditing
              ? IconButton.filledTonal(
                  tooltip: '列を追加',
                  icon: Stack(children: [
                    const Icon(Icons.view_column_outlined),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.add_circle,
                              size: 14,
                              weight: 700,
                              grade: 200,
                              opticalSize: 48)),
                    ),
                  ]),
                  onPressed: _addColumn)
              : widget.allowRowEditing
                  ? const IconButton(onPressed: null, icon: Icon(null))
                  : Container(),
        ],
      ),
      // テーブルデータ
      Column(children: rowWidgets),
    ]);
  }
}

/* ---------------------------------------------------------------------------------------------------------------------------------------------------- */
class TablePosition {
  int startLine;
  int endLine;

  TablePosition({required this.startLine, required this.endLine});
}
