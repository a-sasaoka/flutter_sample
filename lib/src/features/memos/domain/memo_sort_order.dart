/// メモの並び替え（ソート）のルールを表すデータ（列挙型）
enum MemoSortOrder {
  /// 作成日時：新しい順
  createdAtDesc,

  /// 作成日時：古い順
  createdAtAsc,

  /// 更新日時：新しい順
  updatedAtDesc,

  /// 更新日時：古い順
  updatedAtAsc,

  /// タイトル順：昇順（あいうえお順・アルファベット順）
  titleAsc,

  /// タイトル順：降順（逆順）
  titleDesc,
}
