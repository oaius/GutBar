package com.example.progressbar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import kotlin.math.roundToInt

class YearProgressWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId, null, newOptions)
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences?,
        options: Bundle = appWidgetManager.getAppWidgetOptions(widgetId),
    ) {
        val fallback = YearProgressSnapshot.current()
        val title = widgetData?.getString(KEY_TITLE, null) ?: fallback.title
        val daysLeft = widgetData?.getString(KEY_DAYS_LEFT, null) ?: fallback.daysLeft
        val date = widgetData?.getString(KEY_DATE, null) ?: fallback.date
        val progress = widgetData?.getInt(KEY_PROGRESS, fallback.progressBasisPoints)
            ?: fallback.progressBasisPoints

        val views = RemoteViews(context.packageName, R.layout.year_progress_widget).apply {
            setTextViewText(R.id.widget_year_title, title)
            setTextViewText(R.id.widget_days_left, daysLeft)
            setTextViewText(R.id.widget_date, date)
            setProgressBar(
                R.id.widget_year_progress_bar,
                PROGRESS_MAX,
                progress.coerceIn(0, PROGRESS_MAX),
                false,
            )

            if (shouldShowOverview(options)) {
                setImageViewBitmap(
                    R.id.widget_year_overview,
                    YearOverviewBitmap.create(context, options),
                )
                setViewVisibility(R.id.widget_year_overview, View.VISIBLE)
            } else {
                setViewVisibility(R.id.widget_year_overview, View.GONE)
            }

            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("progressbar://year"),
            )
            setOnClickPendingIntent(R.id.widget_container, launchIntent)
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun shouldShowOverview(options: Bundle): Boolean {
        val minWidthDp = options.getInt(
            AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,
            DEFAULT_MIN_WIDTH_DP,
        )
        val minHeightDp = options.getInt(
            AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,
            DEFAULT_MIN_HEIGHT_DP,
        )

        return minWidthDp >= OVERVIEW_MIN_WIDTH_DP && minHeightDp >= OVERVIEW_MIN_HEIGHT_DP
    }

    private data class YearProgressSnapshot(
        val title: String,
        val daysLeft: String,
        val date: String,
        val progressBasisPoints: Int,
    ) {
        companion object {
            fun current(): YearProgressSnapshot {
                val now = Calendar.getInstance()
                val year = now.get(Calendar.YEAR)
                val month = now.get(Calendar.MONTH)
                val dayOfMonth = now.get(Calendar.DAY_OF_MONTH)
                val startOfYear = Calendar.getInstance().apply {
                    clear()
                    set(year, Calendar.JANUARY, 1)
                }
                val startOfNextYear = Calendar.getInstance().apply {
                    clear()
                    set(year + 1, Calendar.JANUARY, 1)
                }
                val startOfToday = Calendar.getInstance().apply {
                    clear()
                    set(year, month, dayOfMonth)
                }

                val totalMillis = startOfNextYear.timeInMillis - startOfYear.timeInMillis
                val elapsedMillis = now.timeInMillis - startOfYear.timeInMillis
                val progress = (elapsedMillis.toDouble() / totalMillis.toDouble())
                    .coerceIn(0.0, 1.0)
                val percent = (progress * 100).roundToInt()
                val remainingDays =
                    ((startOfNextYear.timeInMillis - startOfToday.timeInMillis) / DAY_MILLIS - 1)
                        .toInt()
                        .coerceAtLeast(0)

                return YearProgressSnapshot(
                    title = "$percent% of $year has passed",
                    daysLeft = "$remainingDays days left",
                    date = "${MONTH_NAMES[month]} $dayOfMonth",
                    progressBasisPoints = (progress * PROGRESS_MAX).roundToInt()
                        .coerceIn(0, PROGRESS_MAX),
                )
            }
        }
    }

    private object YearOverviewBitmap {
        private val elapsedFillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
            color = Color.rgb(0, 204, 68)
        }
        private val futureStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            color = Color.rgb(42, 42, 42)
        }
        private val placeholderStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            color = Color.rgb(20, 20, 20)
        }
        private val todayStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            color = Color.rgb(204, 204, 204)
        }
        private val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.rgb(102, 102, 102)
            typeface = android.graphics.Typeface.MONOSPACE
        }

        fun create(context: Context, options: Bundle): Bitmap {
            val density = context.resources.displayMetrics.density
            val minWidthDp = options.getInt(
                AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,
                DEFAULT_MIN_WIDTH_DP,
            )
            val availableWidthDp = (minWidthDp - OVERVIEW_HORIZONTAL_INSET_DP)
                .coerceIn(OVERVIEW_MIN_BITMAP_WIDTH_DP, OVERVIEW_MAX_BITMAP_WIDTH_DP)
            val widthPx = (availableWidthDp * density).roundToInt()
                .coerceAtMost(OVERVIEW_MAX_BITMAP_WIDTH_PX)

            val today = Calendar.getInstance().dateOnly()
            val year = today.get(Calendar.YEAR)
            val startOfYear = Calendar.getInstance().dateOnly().apply {
                set(year, Calendar.JANUARY, 1)
            }
            val endOfYear = Calendar.getInstance().dateOnly().apply {
                set(year, Calendar.DECEMBER, 31)
            }
            val gridStart = startOfYear.copy().apply {
                add(Calendar.DAY_OF_YEAR, -weekdayIndex(this))
            }
            val gridEnd = endOfYear.copy().apply {
                add(Calendar.DAY_OF_YEAR, 6 - weekdayIndex(this))
            }
            val weekCount = daysBetween(gridStart, gridEnd) / DAYS_IN_WEEK + 1

            labelPaint.textSize = LABEL_TEXT_SIZE_SP * density
            futureStrokePaint.strokeWidth = STROKE_WIDTH_DP * density
            placeholderStrokePaint.strokeWidth = STROKE_WIDTH_DP * density
            todayStrokePaint.strokeWidth = TODAY_STROKE_WIDTH_DP * density

            val labelHeightPx = LABEL_HEIGHT_DP * density
            val cellPitch = widthPx / weekCount.toFloat()
            val cellSize = (cellPitch - CELL_GAP_DP * density)
                .coerceAtLeast(MIN_CELL_SIZE_DP * density)
            val cellRadius = (cellSize / CELL_RADIUS_DIVISOR)
                .coerceAtLeast(MIN_CELL_RADIUS_DP * density)
            val gridWidth = cellPitch * weekCount
            val gridLeft = (widthPx - gridWidth) / 2f
            val gridTop = labelHeightPx
            val bottomPadding = OVERVIEW_BOTTOM_PADDING_DP * density
            val heightPx = (gridTop + cellPitch * DAYS_IN_WEEK + bottomPadding)
                .roundToInt()
                .coerceAtLeast(1)

            val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)

            drawMonthLabels(canvas, year, gridStart, gridLeft, cellPitch, density)
            drawDayCells(
                canvas = canvas,
                gridStart = gridStart,
                startOfYear = startOfYear,
                endOfYear = endOfYear,
                today = today,
                weekCount = weekCount,
                gridLeft = gridLeft,
                gridTop = gridTop,
                cellPitch = cellPitch,
                cellSize = cellSize,
                cellRadius = cellRadius,
            )

            return bitmap
        }

        private fun drawMonthLabels(
            canvas: Canvas,
            year: Int,
            gridStart: Calendar,
            gridLeft: Float,
            cellPitch: Float,
            density: Float,
        ) {
            val baseline = LABEL_BASELINE_DP * density
            for (month in Calendar.JANUARY..Calendar.DECEMBER) {
                val firstOfMonth = Calendar.getInstance().dateOnly().apply {
                    set(year, month, 1)
                }
                val column = daysBetween(gridStart, firstOfMonth) / DAYS_IN_WEEK
                canvas.drawText(
                    MONTH_ABBREVIATIONS[month],
                    gridLeft + column * cellPitch,
                    baseline,
                    labelPaint,
                )
            }
        }

        private fun drawDayCells(
            canvas: Canvas,
            gridStart: Calendar,
            startOfYear: Calendar,
            endOfYear: Calendar,
            today: Calendar,
            weekCount: Int,
            gridLeft: Float,
            gridTop: Float,
            cellPitch: Float,
            cellSize: Float,
            cellRadius: Float,
        ) {
            val date = gridStart.copy()
            val rect = RectF()

            for (week in 0 until weekCount) {
                for (day in 0 until DAYS_IN_WEEK) {
                    val left = gridLeft + week * cellPitch + (cellPitch - cellSize) / 2f
                    val top = gridTop + day * cellPitch + (cellPitch - cellSize) / 2f
                    rect.set(left, top, left + cellSize, top + cellSize)

                    val isPlaceholder = date.before(startOfYear) || date.after(endOfYear)
                    val isFuture = date.after(today)
                    val isToday = sameDay(date, today)

                    when {
                        isPlaceholder -> canvas.drawRoundRect(
                            rect,
                            cellRadius,
                            cellRadius,
                            placeholderStrokePaint,
                        )
                        isFuture -> canvas.drawRoundRect(
                            rect,
                            cellRadius,
                            cellRadius,
                            futureStrokePaint,
                        )
                        else -> canvas.drawRoundRect(
                            rect,
                            cellRadius,
                            cellRadius,
                            elapsedFillPaint,
                        )
                    }

                    if (isToday) {
                        canvas.drawRoundRect(rect, cellRadius, cellRadius, todayStrokePaint)
                    }

                    date.add(Calendar.DAY_OF_YEAR, 1)
                }
            }
        }
    }

    companion object {
        private const val KEY_TITLE = "year_progress_title"
        private const val KEY_DAYS_LEFT = "year_progress_days_left"
        private const val KEY_DATE = "year_progress_date"
        private const val KEY_PROGRESS = "year_progress_basis_points"
        private const val PROGRESS_MAX = 10000
        private const val DAY_MILLIS = 24L * 60L * 60L * 1000L
        private const val DEFAULT_MIN_WIDTH_DP = 180
        private const val DEFAULT_MIN_HEIGHT_DP = 80
        private const val OVERVIEW_MIN_WIDTH_DP = 220
        private const val OVERVIEW_MIN_HEIGHT_DP = 150
        private const val OVERVIEW_HORIZONTAL_INSET_DP = 44
        private const val OVERVIEW_MIN_BITMAP_WIDTH_DP = 160
        private const val OVERVIEW_MAX_BITMAP_WIDTH_DP = 420
        private const val OVERVIEW_MAX_BITMAP_WIDTH_PX = 900
        private const val DAYS_IN_WEEK = 7
        private const val LABEL_TEXT_SIZE_SP = 8f
        private const val LABEL_HEIGHT_DP = 15f
        private const val LABEL_BASELINE_DP = 9f
        private const val CELL_GAP_DP = 1.5f
        private const val MIN_CELL_SIZE_DP = 2.5f
        private const val CELL_RADIUS_DIVISOR = 3f
        private const val MIN_CELL_RADIUS_DP = 0.75f
        private const val STROKE_WIDTH_DP = 0.8f
        private const val TODAY_STROKE_WIDTH_DP = 1.2f
        private const val OVERVIEW_BOTTOM_PADDING_DP = 2f
        private val MONTH_NAMES = arrayOf(
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December",
        )
        private val MONTH_ABBREVIATIONS = arrayOf(
            "Jan",
            "Feb",
            "Mar",
            "Apr",
            "May",
            "Jun",
            "Jul",
            "Aug",
            "Sep",
            "Oct",
            "Nov",
            "Dec",
        )

        private fun Calendar.copy(): Calendar = (clone() as Calendar)

        private fun Calendar.dateOnly(): Calendar = apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        private fun weekdayIndex(date: Calendar): Int {
            return date.get(Calendar.DAY_OF_WEEK) - Calendar.SUNDAY
        }

        private fun daysBetween(start: Calendar, end: Calendar): Int {
            val cursor = start.copy()
            var days = 0
            while (cursor.before(end)) {
                cursor.add(Calendar.DAY_OF_YEAR, 1)
                days++
            }
            return days
        }

        private fun sameDay(left: Calendar, right: Calendar): Boolean {
            return left.get(Calendar.YEAR) == right.get(Calendar.YEAR) &&
                left.get(Calendar.DAY_OF_YEAR) == right.get(Calendar.DAY_OF_YEAR)
        }
    }
}
