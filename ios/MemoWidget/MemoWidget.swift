import SwiftUI
import WidgetKit

/// ホーム画面ウィジェットに渡すタイムライン用データモデル
struct MemoWidgetEntry: TimelineEntry {
    let date: Date
    let memoCount: Int
    let latestMemoId: String
    let latestMemoTitle: String
    let latestMemoContent: String
    let latestMemoUpdatedAt: String
}

/// ウィジェットの更新スケジュールとデータを管理するプロバイダー
struct MemoWidgetTimelineProvider: TimelineProvider {
    /// 自身（ウィジェット）のBundle Identifierから親アプリのApp Group IDを動的に導出する
    private var appGroupId: String {
        if let widgetBundleId = Bundle.main.bundleIdentifier {
            let parentBundleId = widgetBundleId.replacingOccurrences(of: ".MemoWidget", with: "")
            return "group.\(parentBundleId)"
        }
        return "group.jp.example.sample"
    }

    /// App Group領域のUserDefaultsから最新データを読み取る
    private func loadEntry(date: Date = Date()) -> MemoWidgetEntry {
        let prefs = UserDefaults(suiteName: appGroupId)
        let memoCount = prefs?.integer(forKey: "widget_memo_count") ?? 0
        let latestMemoId = prefs?.string(forKey: "widget_memo_id") ?? ""
        let latestMemoTitle = prefs?.string(forKey: "widget_memo_title") ?? "メモがありません"
        let latestMemoContent = prefs?.string(forKey: "widget_memo_content") ?? "＋ボタンから最初のメモを作成しましょう！"
        let latestMemoUpdatedAt = prefs?.string(forKey: "widget_memo_updated_at") ?? ""

        return MemoWidgetEntry(
            date: date,
            memoCount: memoCount,
            latestMemoId: latestMemoId,
            latestMemoTitle: latestMemoTitle,
            latestMemoContent: latestMemoContent,
            latestMemoUpdatedAt: latestMemoUpdatedAt
        )
    }

    func placeholder(in context: Context) -> MemoWidgetEntry {
        MemoWidgetEntry(
            date: Date(),
            memoCount: 3,
            latestMemoId: "sample",
            latestMemoTitle: "買い出しリスト",
            latestMemoContent: "牛乳、卵、パン、コーヒー豆を買うこと",
            latestMemoUpdatedAt: "9/27 10:30"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MemoWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoWidgetEntry>) -> Void) {
        let entry = loadEntry()
        // ウィジェットはFlutterアプリ側からの明示的な更新リクエスト（HomeWidget.updateWidget）で都度リフレッシュされるため、
        // 次回の自動更新は .never（または必要に応じた間隔）に設定します。
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

/// ウィジェットの見た目（SwiftUI View）
struct MemoWidgetEntryView: View {
    var entry: MemoWidgetTimelineProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // --- ヘッダー部分（アプリアイコン・タイトル・件数バッジ） ---
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14, weight: .bold))
                Text("最新メモ")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                if entry.memoCount > 0 {
                    Text("\(entry.memoCount) 件")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
            }

            // --- メモ本文プレビュー ---
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.latestMemoTitle)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Text(entry.latestMemoContent)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            // --- フッター部分（更新日時 ＆ 「＋ 新規追加」アクションボタン） ---
            HStack(alignment: .center) {
                if !entry.latestMemoUpdatedAt.isEmpty {
                    Text(entry.latestMemoUpdatedAt)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // タップするとアプリのメモ新規作成画面へ直接ジャンプするLinkボタン
                Link(destination: URL(string: "sampleapp://memos/create?homeWidget")!) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13))
                        Text("新規追加")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        // ウィジェット全体のタップはメモ一覧画面へジャンプ
        .widgetURL(URL(string: "sampleapp://memos?homeWidget"))
    }
}

/// ウィジェットの設定エントリポイント
struct MemoWidget: Widget {
    let kind: String = "MemoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MemoWidgetTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                MemoWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MemoWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("メモウィジェット")
        .description("最新のメモをホーム画面で素早く確認・新規追加できます。")
        .supportedFamilies([.systemMedium])
    }
}
