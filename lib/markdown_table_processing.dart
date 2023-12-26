/// -----------------------------------------------
/// [概要]   : Markdownテキストからテーブルを抽出・操作するクラス
/// [作成者] : TCC S.Tate
/// [作成日] : 2023/12/26
/// -----------------------------------------------
class MarkdownTableProcessor {
  List<TablePosition> tablePositions = []; // テーブルの位置を保持するリスト

  /// マークダウンテキストからテーブルを抽出し、それらのリストを返す。
  ///
  /// - [`markdown`] は処理されるマークダウン形式の文字列です。
  /// - [`includeHeading`] が true の場合、見出しもテーブルと共に抽出されます。
  ///
  /// このメソッドは、マークダウン内のテーブルを識別し、それらを個別の文字列として返します。
  /// 各テーブルは、必要に応じて関連する見出しと共に返されます。
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
      }
      // テーブルの終了を追跡
      if ((!inTable || line.trim() == '') && startLineIndex != -1) {
        endLineIndex = lines.indexOf(line) - 1; // テーブルの終了行を設定
        tablePositions.add(
            TablePosition(startLine: startLineIndex, endLine: endLineIndex));
        startLineIndex = -1; // リセット
      }
    }

    // 最後のテーブルを処理
    if (inTable) {
      tables.add(currentTable.toString());
    }

    return tables;
  }

  /// マークダウンテキストからテーブルを除外したセクションを抽出し、それらのリストを返す。
  ///
  /// - [`markdown`] は処理されるマークダウン形式の文字列です。
  ///
  /// このメソッドは、マークダウン内のテーブルを除外し、
  /// テーブル以外のセクションを個別の文字列として返します。
  List<String> extractNonTableMarkdownSections(String markdown) {
    List<String> lines = markdown.split('\n'); // Markdownテキストを行に分割
    List<String> nonTableSections = [];
    StringBuffer currentSection = StringBuffer(); // 現在処理中のセクションを構築
    bool inTable = false; // 現在テーブル内かを追跡

    for (String line in lines) {
      var trimmedLine = line.trim(); // 行の前後の空白を削除

      // テーブルの境界行を処理
      if (trimmedLine.startsWith('|') && trimmedLine.endsWith('|')) {
        if (!inTable) {
          // 新しいテーブルの開始前に、現在のセクションをリストに追加
          if (currentSection.isNotEmpty) {
            nonTableSections.add(currentSection.toString());
            currentSection.clear();
          }
          inTable = true;
        }
        continue;
      } else if (inTable) {
        // テーブルの終了
        inTable = false;
        continue;
      }

      // テーブル以外の行を現在のセクションに追加
      currentSection.writeln(line);
    }

    // 最後のセクションを処理
    if (currentSection.isNotEmpty) {
      nonTableSections.add(currentSection.toString());
    }

    return nonTableSections;
  }

  /// 編集されたテーブルを元のマークダウンテキストにマージする。
  ///
  /// - [originalMarkdown] は元のマークダウンテキストです。
  /// - [editedTables] は編集されたテーブルのリストです。
  ///
  /// このメソッドは、編集されたテーブルを元のマークダウンテキストに統合し、
  /// 新しいマークダウンテキストを生成して返します。
  String mergeEditedTablesIntoMarkdown(
      String originalMarkdown, List<String> editedTables) {
    List<String> originalLines = originalMarkdown.split('\n');
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
      if (currentTableIndex < editedTables.length &&
          i == tablePositions[currentTableIndex].startLine) {
        List<String> newTableLines =
            editedTables[currentTableIndex].split('\n');
        int offset = 0; // 現在のオフセット（行数の変化）

        // 新しいテーブルの内容を追加
        mergedLines.addAll(newTableLines);

        // オフセット（行数の変化）を計算
        int originalTableLength = tablePositions[currentTableIndex].endLine -
            tablePositions[currentTableIndex].startLine +
            1;
        int editedTableLength = newTableLines.length;
        offset = editedTableLength - originalTableLength;

        // 元のテーブルの範囲をスキップ
        i = tablePositions[currentTableIndex].endLine;

        // 次のテーブルの位置を更新
        for (int j = currentTableIndex + 0; j < tablePositions.length; j++) {
          if (j > currentTableIndex) newTablePositions[j].startLine += offset;
          newTablePositions[j].endLine += offset;
        }

        currentTableIndex++;
      } else if (currentTableIndex >= editedTables.length ||
          i < tablePositions[currentTableIndex].startLine) {
        mergedLines.add(originalLines[i]);
      }
    }
    tablePositions = newTablePositions;
    final mergedMarkdown = mergedLines.join('\n');
    return mergedMarkdown;
  }
}

/// -----------------------------------------------
/// [概要]   : マークダウン内のテーブルの位置情報を保持するクラス
/// [作成者] : TCC S.Tate
/// [作成日] : 2023/12/26
/// -----------------------------------------------
class TablePosition {
  /// テーブルの開始行インデックス
  int startLine;

  /// テーブルの終了行インデックス
  int endLine;

  /// [TablePosition] コンストラクタは、テーブルの位置情報を初期化する。
  ///
  /// [startLine] はテーブルの開始行を指定し、
  /// [endLine] はテーブルの終了行を指定します。
  TablePosition({required this.startLine, required this.endLine});
}
