package jp.example.sample

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * ホーム画面ウィジェットの更新およびイベントハンドリングを担当するProviderクラス
 */
class MemoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.memo_widget).apply {
                val memoCount = widgetData.getInt("widget_memo_count", 0)
                val latestTitle = widgetData.getString("widget_memo_title", "メモがありません") ?: "メモがありません"
                val latestContent = widgetData.getString("widget_memo_content", "＋ボタンから最初のメモを作成しましょう！") ?: "＋ボタンから最初のメモを作成しましょう！"
                val latestUpdatedAt = widgetData.getString("widget_memo_updated_at", "") ?: ""

                setTextViewText(R.id.widget_memo_title, latestTitle)
                setTextViewText(R.id.widget_memo_content, latestContent)
                setTextViewText(R.id.widget_memo_updated_at, latestUpdatedAt)
                setTextViewText(
                    R.id.widget_memo_count,
                    if (memoCount > 0) "$memoCount 件" else ""
                )

                // ウィジェット全体タップ: メモ一覧画面へジャンプ
                val listPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("sampleapp://memos")
                )
                setOnClickPendingIntent(R.id.widget_container, listPendingIntent)

                // 「+ 新規追加」ボタンタップ: メモ新規作成画面へ直接ジャンプ
                val addPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("sampleapp://memos/create")
                )
                setOnClickPendingIntent(R.id.widget_btn_add, addPendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
