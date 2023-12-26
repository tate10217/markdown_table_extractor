// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

/// -----------------------------------------------
/// [概要]   : Markdown形式のテーブルを編集可能なウィジェットとして表示するクラス
/// [作成者] : TCC S.Tate
/// [作成日] : 2023/12/26
/// -----------------------------------------------
class EditableTableWidget extends StatefulWidget {
  final String tableMarkdown; // テーブルのマークダウンデータ
  final bool readOnly; // 編集不可にするかどうか
  final TextStyle titleStyle; // タイトルのスタイル
  final TextAlign titleAlignment; // タイトルのテキスト揃え
  final TextAlign headerAlignment; // ヘッダーのテキスト揃え
  final bool isRowEditingEnabled; // 行編集が有効かどうか
  final bool isColumnEditingEnabled; // 列編集が有効かどうか
  final bool isAlignmentControlEnabled; // 文字寄せの制御が有効かどうか
  final Function(String)? onTableChanged; // テーブルの変更を検知するコールバック関数

  /// コンストラクタは、テーブルウィジェットの設定を初期化する。
  ///
  /// - [tableMarkdown] にはマークダウン形式のテーブルデータを渡す。
  /// - [readOnly] が true の場合、テーブルは編集不可になる。
  /// - [titleStyle] でタイトルのスタイルを設定できる。
  /// - [titleAlignment] でタイトルのテキスト揃えを設定できる。
  /// - [headerAlignment] でヘッダーのテキスト揃えを設定できる。
  /// - [isRowEditingEnabled] が true の場合、行編集が有効になる。
  /// - [isColumnEditingEnabled] が true の場合、列編集が有効になる。
  /// - [isAlignmentControlEnabled] が true の場合、文字寄せの制御が有効になる。
  /// - [onTableChanged] はテーブルの変更を検知するコールバック関数。
  const EditableTableWidget({
    Key? key,
    required this.tableMarkdown,
    this.readOnly = false,
    this.titleStyle = const TextStyle(fontWeight: FontWeight.bold),
    this.titleAlignment = TextAlign.left,
    this.headerAlignment = TextAlign.left,
    this.isRowEditingEnabled = false,
    this.isColumnEditingEnabled = false,
    this.isAlignmentControlEnabled = false,
    this.onTableChanged,
  }) : super(key: key);

  @override
  _EditableTableWidgetState createState() => _EditableTableWidgetState();
}

class _EditableTableWidgetState extends State<EditableTableWidget> {
  List<List<TextEditingController>> _controllers = [];
  List<TextEditingController> headerControllers = [];
  List<TextAlign> columnAlignments = []; // 列ごとの文字揃えを管理するためのリスト
  String title = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeHeaderControllers();
    _initializeColumnAlignments(widget.tableMarkdown); // マークダウンから列揃えを初期化
  }

  @override
  void dispose() {
    for (var row in _controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var controller in headerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// ヘッダーのテキストフィールドコントローラーを初期化
  void _initializeHeaderControllers() {
    if (widget.isColumnEditingEnabled) {
      var headerRow = _controllers.first;
      headerControllers = headerRow
          .map((controller) => TextEditingController(text: controller.text))
          .toList();
    }
  }

  /// ヘッダーの変更を処理
  void _onHeaderChanged() {
    if (widget.isColumnEditingEnabled) {
      for (int i = 0; i < headerControllers.length; i++) {
        _controllers.first[i].text = headerControllers[i].text;
      }
      _onFieldChanged();
    }
  }

  /// 列揃えの初期化
  void _initializeColumnAlignments(String markdown) {
    List<String> lines = markdown.split('\n');
    // 区切り行（通常は2行目）を探す
    if (lines.length >= 2) {
      // 見出し行を除外
      if (lines[0].startsWith('#')) {
        lines.removeAt(0);
      }
      String separatorLine = lines[1];
      List<String> separators =
          separatorLine.split('|').map((s) => s.trim()).toList();

      // 区切り行の最初と最後のセパレータを削除
      separators.removeAt(0);
      separators.removeLast();

      // 各セパレータに基づいて揃え方向を判定
      columnAlignments = separators.map((sep) {
        if (sep.startsWith(':') && sep.endsWith(':')) {
          return TextAlign.center;
        } else if (sep.endsWith(':')) {
          return TextAlign.right;
        } else if (sep.startsWith(':')) {
          return TextAlign.left;
        } else {
          return TextAlign.left; // デフォルトは左寄せ
        }
      }).toList();
    }
  }

  /// 列揃えコントロールを生成
  Widget _buildAlignmentControl(int columnIndex) {
    return SegmentedButton(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          icon: Icon(Icons.format_align_left),
          value: TextAlign.left,
        ),
        ButtonSegment(
          icon: Icon(Icons.format_align_center),
          value: TextAlign.center,
        ),
        ButtonSegment(
          icon: Icon(Icons.format_align_right),
          value: TextAlign.right,
        ),
      ],
      selected: {columnAlignments[columnIndex]},
      onSelectionChanged: (value) {
        setState(() {
          columnAlignments[columnIndex] = value.first;
          _onFieldChanged();
        });
      },
    );
  }

  /// テキストフィールドコントローラーを初期化
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

  /// テキストフィールドの変更を処理
  void _onFieldChanged() {
    var markdownTable = '';
    // ヘッダー行と区切り行を特別に扱う
    for (int i = 0; i < _controllers.length; i++) {
      var row = _controllers[i];
      if (i == 1) {
        // 区切り行
        markdownTable += '| ${List.generate(row.length, (index) {
          switch (columnAlignments[index]) {
            case TextAlign.left:
              return '---';
            case TextAlign.center:
              return ':---:';
            case TextAlign.right:
              return '---:';
            default:
              return '---';
          }
        }).join(' | ')} |\n';
      } else {
        markdownTable += '| ${row.map((cell) => cell.text).join(' | ')} |\n';
      }
    }
    if (widget.onTableChanged != null) widget.onTableChanged!(markdownTable);
  }

  /// 区切り文字からテキストの配置を取得
  TextAlign _getTextAlignment(String separator) {
    if (separator.startsWith(':') && separator.endsWith(':')) {
      return TextAlign.center;
    } else if (separator.endsWith(':')) {
      return TextAlign.right;
    }
    return TextAlign.left;
  }

  /// 行を追加
  void _addRow() {
    if (!widget.isRowEditingEnabled) return;
    // すべての列に空のテキストフィールドコントローラーを追加
    setState(() {
      _controllers.add(List.generate(
          _controllers[0].length, (_) => TextEditingController()));
    });
    _onFieldChanged();
  }

  /// 行を削除
  void _removeRow(int index) {
    if (!widget.isRowEditingEnabled) return;
    // 指定された行を削除
    setState(() {
      _controllers.removeAt(index);
    });
    _onFieldChanged();
  }

  /// 列を追加
  void _addColumn(int index) {
    if (!widget.isColumnEditingEnabled) return;
    // すべての行に新しい列を追加
    setState(() {
      // ヘッダー行に新しいコントローラーを追加
      headerControllers.insert(index, TextEditingController());
      // 各データ行に新しいコントローラーを追加
      for (var row in _controllers) {
        row.insert(index, TextEditingController());
      }
      // 新しい列のデフォルトの文字寄せを設定（ここでエラーが発生していた）
      columnAlignments.insert(index, TextAlign.left);
    });
    _onFieldChanged();
  }

  /// 列を削除
  void _removeColumn(int index) {
    if (!widget.isColumnEditingEnabled) return;
    // すべての行から指定された列を削除
    setState(() {
      for (var row in _controllers) {
        if (row.length > index) {
          row.removeAt(index);
        }
      }
      if (headerControllers.length > index) {
        headerControllers.removeAt(index);
      }
      // 対応する列の寄せ方向を削除
      if (columnAlignments.length > index) {
        columnAlignments.removeAt(index);
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
          child: widget.isColumnEditingEnabled
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
      if (widget.isRowEditingEnabled) {
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
      } else if (widget.isColumnEditingEnabled) {
        // 幅を調整するためのダミーウィジェット(透明な本物のボタンを表示)
        cellWidgets.add(const IconButton(icon: Icon(null), onPressed: null));
      }
      // 項目
      rowWidgets.add(Row(children: cellWidgets));
    }
    // 行追加ボタン
    if (widget.isRowEditingEnabled) {
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

    // 列の追加・削除を行うウィジェット行の生成
    List<Widget> columnControlWidgets = List.generate(
      headers.length,
      (index) => Expanded(
        child: Row(children: [
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                // 列揃えコントロール
                if (widget.isAlignmentControlEnabled)
                  _buildAlignmentControl(index),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    // 列削除ボタン
                    if (headers.length > 1 && widget.isColumnEditingEnabled)
                      IconButton.filled(
                        icon: Stack(children: [
                          const Icon(Icons.view_column_outlined),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                                color: Theme.of(context).colorScheme.primary,
                                child: const Icon(Icons.remove_circle,
                                    size: 14,
                                    weight: 700,
                                    grade: 200,
                                    opticalSize: 48)),
                          ),
                        ]),
                        onPressed: () => _removeColumn(index),
                      ),
                    // 列追加ボタン
                    if (widget.isColumnEditingEnabled)
                      IconButton.filledTonal(
                        icon: Stack(children: [
                          const Icon(Icons.view_column_outlined),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: const Icon(Icons.add_circle,
                                    size: 14,
                                    weight: 700,
                                    grade: 200,
                                    opticalSize: 48)),
                          ),
                        ]),
                        onPressed: () => _addColumn(index + 1),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ]),
      ),
    );

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
          Expanded(
            child: Column(children: [
              Row(children: columnControlWidgets),
              Row(children: headerWidgets),
            ]),
          ),
          // 列追加ボタン
          widget.isColumnEditingEnabled
              ? const IconButton(onPressed: null, icon: Icon(null))
              : widget.isRowEditingEnabled
                  ? const IconButton(onPressed: null, icon: Icon(null))
                  : Container(),
        ],
      ),
      // テーブルデータ
      Column(children: rowWidgets),
    ]);
  }
}
