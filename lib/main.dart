import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Markdown Table Extractor',
      home: MarkdownTableExtractor(),
    );
  }
}

class MarkdownTableExtractor extends StatefulWidget {
  @override
  _MarkdownTableExtractorState createState() => _MarkdownTableExtractorState();
}

class _MarkdownTableExtractorState extends State<MarkdownTableExtractor> {
  List<String> tables = [];

  @override
  void initState() {
    super.initState();
    String markdownText = '''
    # テスト用マークダウン

    これは通常のテキストです。以下にマークダウンのテーブルが続きます。

    | ヘッダ1 | ヘッダ2 | ヘッダ3 |
    | ------- | ------- | ------- |
    | データ1 | データ2 | データ3 |
    | データ4 | データ5 | データ6 |

    これはテーブルの間に挿入されたテキストです。

    ## サブセクション

    - リストアイテム1
    - リストアイテム2

    > 引用文

    ### align属性付きテーブル

    | 左揃え | 中央揃え | 右揃え |
    | :----- | :------: | -----: |
    | 左     | 中央     | 右     |

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
    | ----------- |
    | 単一のデータ |

    これでテスト用のマークダウン文字列は終わりです。
    ''';

    tables = extractMarkdownTables(markdownText, includeHeading: true);
  }

  List<String> extractMarkdownTables(String markdown,
      {bool includeHeading = true}) {
    List<String> lines = markdown.split('\n'); // Markdownテキストを行に分割
    List<String> tables = [];
    bool inTable = false; // 現在テーブル内かを追跡
    bool textBetweenHeadingAndTable = false; // 見出しとテーブルの間にテキストがあるかを追跡
    StringBuffer currentTable = StringBuffer(); // 現在処理中のテーブルを構築
    String lastHeading = ''; // 最後に見つかった見出しを保持

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
    }

    // 最後のテーブルを処理
    if (inTable) {
      tables.add(currentTable.toString());
    }

    return tables;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Table Extractor and Editor'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true, // このリストの高さをそのコンテンツに合わせる
              physics:
                  const NeverScrollableScrollPhysics(), // このリストのスクロールを無効にする
              itemCount: tables.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // markdownテーブル文字列を表示する
            ListView.builder(
              shrinkWrap: true, // このリストの高さをそのコンテンツに合わせる
              physics:
                  const NeverScrollableScrollPhysics(), // このリストのスクロールを無効にする
              itemCount: tables.length,
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(tables[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
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
  String title = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
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
    var markdownTable = title != '' ? '$title\n' : '';
    markdownTable += _controllers.map((row) {
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
    List<Widget> headerWidgets = headers
        .map((header) => Expanded(
            child: Text(header,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: widget.headerAlignment)))
        .toList();

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
              icon: const Icon(Icons.remove),
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
                  icon: const Icon(Icons.add),
                  onPressed: _addRow),
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
                  icon: const Icon(Icons.add),
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
