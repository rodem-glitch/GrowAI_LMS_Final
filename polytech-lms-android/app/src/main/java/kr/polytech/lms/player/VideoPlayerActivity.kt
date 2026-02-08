// polytech-lms-android/app/src/main/java/kr/polytech/lms/player/VideoPlayerActivity.kt
package kr.polytech.lms.player

import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.media3.ui.PlayerView
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kr.polytech.lms.databinding.ActivityVideoPlayerBinding
import javax.inject.Inject

/**
 * 비디오 플레이어 Activity
 * 한국폴리텍대학 LMS 동영상 강의 재생 화면
 *
 * 기능:
 * - 전체화면 지원
 * - 가로/세로 모드 전환
 * - 재생 속도 조절
 * - 화질 선택
 * - PIP (Picture-in-Picture) 지원
 * - 학습 진도 표시
 */
@AndroidEntryPoint
class VideoPlayerActivity : AppCompatActivity() {

    companion object {
        private const val EXTRA_LESSON_ID = "extra_lesson_id"
        private const val EXTRA_COURSE_ID = "extra_course_id"
        private const val EXTRA_VIDEO_URL = "extra_video_url"
        private const val EXTRA_TITLE = "extra_title"
        private const val EXTRA_START_POSITION = "extra_start_position"
        private const val EXTRA_IS_HLS = "extra_is_hls"

        fun createIntent(
            context: Context,
            lessonId: Long,
            courseId: Long,
            videoUrl: String,
            title: String,
            startPositionMs: Long = 0,
            isHls: Boolean = false
        ): Intent {
            return Intent(context, VideoPlayerActivity::class.java).apply {
                putExtra(EXTRA_LESSON_ID, lessonId)
                putExtra(EXTRA_COURSE_ID, courseId)
                putExtra(EXTRA_VIDEO_URL, videoUrl)
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_START_POSITION, startPositionMs)
                putExtra(EXTRA_IS_HLS, isHls)
            }
        }
    }

    @Inject
    lateinit var videoPlayerService: VideoPlayerService

    private lateinit var binding: ActivityVideoPlayerBinding
    private val viewModel: VideoPlayerViewModel by viewModels()

    private var isFullscreen = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 전체화면 설정
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        binding = ActivityVideoPlayerBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupPlayer()
        setupControls()
        loadVideo()
        observeState()
    }

    /**
     * 플레이어 설정
     */
    private fun setupPlayer() {
        val player = videoPlayerService.initializePlayer()
        binding.playerView.player = player

        // 컨트롤러 설정
        binding.playerView.apply {
            setShowNextButton(false)
            setShowPreviousButton(false)
            setShowShuffleButton(false)
            setShowSubtitleButton(true)
            controllerShowTimeoutMs = 3000
            controllerHideOnTouch = true
        }
    }

    /**
     * 컨트롤 버튼 설정
     */
    private fun setupControls() {
        // 뒤로가기
        binding.btnBack.setOnClickListener {
            onBackPressedDispatcher.onBackPressed()
        }

        // 전체화면 토글
        binding.btnFullscreen.setOnClickListener {
            toggleFullscreen()
        }

        // 재생 속도
        binding.btnSpeed.setOnClickListener {
            showSpeedDialog()
        }

        // 화질 선택
        binding.btnQuality.setOnClickListener {
            showQualityDialog()
        }

        // 앞으로 10초
        binding.btnForward.setOnClickListener {
            videoPlayerService.seekForward()
        }

        // 뒤로 10초
        binding.btnRewind.setOnClickListener {
            videoPlayerService.seekBack()
        }

        // 화면 회전
        binding.btnRotate.setOnClickListener {
            toggleOrientation()
        }
    }

    /**
     * 비디오 로드
     */
    private fun loadVideo() {
        val lessonId = intent.getLongExtra(EXTRA_LESSON_ID, -1)
        val courseId = intent.getLongExtra(EXTRA_COURSE_ID, -1)
        val videoUrl = intent.getStringExtra(EXTRA_VIDEO_URL) ?: return
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "강의"
        val startPosition = intent.getLongExtra(EXTRA_START_POSITION, 0)
        val isHls = intent.getBooleanExtra(EXTRA_IS_HLS, false)

        binding.tvTitle.text = title

        if (isHls) {
            videoPlayerService.loadHlsLesson(lessonId, courseId, videoUrl, title)
        } else {
            videoPlayerService.loadLesson(lessonId, courseId, videoUrl, title, startPositionMs = startPosition)
        }
    }

    /**
     * 상태 관찰
     */
    private fun observeState() {
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                launch {
                    videoPlayerService.playbackState.collectLatest { state ->
                        handlePlaybackState(state)
                    }
                }

                launch {
                    videoPlayerService.currentPosition.collectLatest { position ->
                        updateProgress(position)
                    }
                }

                launch {
                    videoPlayerService.currentSpeed.collectLatest { speed ->
                        binding.btnSpeed.text = speed.label
                    }
                }

                launch {
                    videoPlayerService.currentQuality.collectLatest { quality ->
                        binding.btnQuality.text = quality.label
                    }
                }
            }
        }
    }

    /**
     * 재생 상태 처리
     */
    private fun handlePlaybackState(state: PlaybackState) {
        when (state) {
            is PlaybackState.Idle -> {
                binding.progressBar.visibility = View.GONE
            }
            is PlaybackState.Buffering -> {
                binding.progressBar.visibility = View.VISIBLE
            }
            is PlaybackState.Ready -> {
                binding.progressBar.visibility = View.GONE
            }
            is PlaybackState.Ended -> {
                binding.progressBar.visibility = View.GONE
                showCompletionDialog()
            }
            is PlaybackState.Error -> {
                binding.progressBar.visibility = View.GONE
                showErrorDialog(state.message)
            }
        }
    }

    /**
     * 진도 업데이트
     */
    private fun updateProgress(positionMs: Long) {
        val duration = videoPlayerService.duration.value
        if (duration > 0) {
            val progress = ((positionMs.toFloat() / duration) * 100).toInt()
            binding.tvProgress.text = "$progress%"
        }
    }

    /**
     * 전체화면 토글
     */
    private fun toggleFullscreen() {
        isFullscreen = !isFullscreen

        val windowInsetsController = WindowCompat.getInsetsController(window, binding.root)

        if (isFullscreen) {
            windowInsetsController.hide(WindowInsetsCompat.Type.systemBars())
            windowInsetsController.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            binding.topBar.visibility = View.GONE
            binding.btnFullscreen.setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
        } else {
            windowInsetsController.show(WindowInsetsCompat.Type.systemBars())
            binding.topBar.visibility = View.VISIBLE
            binding.btnFullscreen.setImageResource(android.R.drawable.ic_menu_view)
        }
    }

    /**
     * 화면 방향 토글
     */
    private fun toggleOrientation() {
        requestedOrientation = if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        } else {
            ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        }
    }

    /**
     * 재생 속도 선택 다이얼로그
     */
    private fun showSpeedDialog() {
        val speeds = PlaybackSpeed.values()
        val labels = speeds.map { it.label }.toTypedArray()
        val currentIndex = speeds.indexOf(videoPlayerService.currentSpeed.value)

        AlertDialog.Builder(this)
            .setTitle("재생 속도")
            .setSingleChoiceItems(labels, currentIndex) { dialog, which ->
                videoPlayerService.setPlaybackSpeed(speeds[which])
                dialog.dismiss()
            }
            .setNegativeButton("취소", null)
            .show()
    }

    /**
     * 화질 선택 다이얼로그
     */
    private fun showQualityDialog() {
        val qualities = VideoQuality.values()
        val labels = qualities.map { it.label }.toTypedArray()
        val currentIndex = qualities.indexOf(videoPlayerService.currentQuality.value)

        AlertDialog.Builder(this)
            .setTitle("화질 선택")
            .setSingleChoiceItems(labels, currentIndex) { dialog, which ->
                videoPlayerService.setVideoQuality(qualities[which])
                dialog.dismiss()
            }
            .setNegativeButton("취소", null)
            .show()
    }

    /**
     * 학습 완료 다이얼로그
     */
    private fun showCompletionDialog() {
        AlertDialog.Builder(this)
            .setTitle("학습 완료")
            .setMessage("강의 시청을 완료하였습니다.\n다음 강의로 이동하시겠습니까?")
            .setPositiveButton("다음 강의") { _, _ ->
                // TODO: 다음 강의로 이동
                finish()
            }
            .setNegativeButton("목록으로") { _, _ ->
                finish()
            }
            .setCancelable(false)
            .show()
    }

    /**
     * 에러 다이얼로그
     */
    private fun showErrorDialog(message: String) {
        AlertDialog.Builder(this)
            .setTitle("재생 오류")
            .setMessage(message)
            .setPositiveButton("다시 시도") { _, _ ->
                loadVideo()
            }
            .setNegativeButton("닫기") { _, _ ->
                finish()
            }
            .show()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)

        // 가로 모드일 때 자동 전체화면
        if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE && !isFullscreen) {
            toggleFullscreen()
        }
    }

    override fun onStart() {
        super.onStart()
        binding.playerView.onResume()
    }

    override fun onStop() {
        super.onStop()
        binding.playerView.onPause()
    }

    override fun onDestroy() {
        super.onDestroy()
        videoPlayerService.releasePlayer()
    }

    override fun onBackPressed() {
        if (isFullscreen) {
            toggleFullscreen()
        } else {
            super.onBackPressed()
        }
    }
}
