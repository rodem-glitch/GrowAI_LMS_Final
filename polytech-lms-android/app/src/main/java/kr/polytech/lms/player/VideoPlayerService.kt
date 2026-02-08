// polytech-lms-android/app/src/main/java/kr/polytech/lms/player/VideoPlayerService.kt
package kr.polytech.lms.player

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 비디오 플레이어 서비스
 * 한국폴리텍대학 LMS 동영상 강의 재생 관리
 *
 * 기능:
 * - HLS/DASH 적응형 스트리밍
 * - 학습 진도 자동 저장
 * - 오프라인 재생 지원
 * - 배경 재생 (오디오 전용)
 */
@Singleton
class VideoPlayerService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val exoPlayerBuilder: ExoPlayer.Builder,
    private val cacheDataSourceFactory: CacheDataSource.Factory,
    private val trackSelector: DefaultTrackSelector,
    private val progressRepository: LearningProgressRepository
) {
    companion object {
        private const val TAG = "VideoPlayerService"
        private const val PROGRESS_SAVE_INTERVAL_MS = 10_000L  // 10초마다 진도 저장
        private const val SEEK_FORWARD_MS = 10_000L
        private const val SEEK_BACK_MS = 10_000L
    }

    private var exoPlayer: ExoPlayer? = null
    private var progressSaveJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // 현재 재생 중인 강의 정보
    private var currentLessonId: Long = -1
    private var currentCourseId: Long = -1

    // 상태 Flow
    private val _playbackState = MutableStateFlow<PlaybackState>(PlaybackState.Idle)
    val playbackState: StateFlow<PlaybackState> = _playbackState.asStateFlow()

    private val _currentPosition = MutableStateFlow(0L)
    val currentPosition: StateFlow<Long> = _currentPosition.asStateFlow()

    private val _duration = MutableStateFlow(0L)
    val duration: StateFlow<Long> = _duration.asStateFlow()

    private val _bufferedPosition = MutableStateFlow(0L)
    val bufferedPosition: StateFlow<Long> = _bufferedPosition.asStateFlow()

    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private val _currentQuality = MutableStateFlow(VideoQuality.AUTO)
    val currentQuality: StateFlow<VideoQuality> = _currentQuality.asStateFlow()

    private val _currentSpeed = MutableStateFlow(PlaybackSpeed.SPEED_1X)
    val currentSpeed: StateFlow<PlaybackSpeed> = _currentSpeed.asStateFlow()

    /**
     * 플레이어 초기화
     */
    fun initializePlayer(): ExoPlayer {
        if (exoPlayer != null) {
            return exoPlayer!!
        }

        val mediaSourceFactory = DefaultMediaSourceFactory(context)
            .setDataSourceFactory(cacheDataSourceFactory)

        exoPlayer = exoPlayerBuilder
            .setMediaSourceFactory(mediaSourceFactory)
            .build()
            .apply {
                addListener(playerListener)
                playWhenReady = false
                repeatMode = Player.REPEAT_MODE_OFF
            }

        startPositionUpdates()
        Log.i(TAG, "ExoPlayer 초기화 완료")

        return exoPlayer!!
    }

    /**
     * 강의 영상 로드
     */
    fun loadLesson(
        lessonId: Long,
        courseId: Long,
        videoUrl: String,
        title: String,
        subtitle: String? = null,
        startPositionMs: Long = 0
    ) {
        val player = exoPlayer ?: initializePlayer()

        currentLessonId = lessonId
        currentCourseId = courseId

        val mediaItem = MediaItem.Builder()
            .setUri(Uri.parse(videoUrl))
            .setMediaId(lessonId.toString())
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle(title)
                    .setSubtitle(subtitle)
                    .setArtist("한국폴리텍대학")
                    .build()
            )
            .build()

        player.setMediaItem(mediaItem)
        player.prepare()

        // 이전 시청 위치로 이동
        if (startPositionMs > 0) {
            player.seekTo(startPositionMs)
        }

        Log.i(TAG, "강의 로드: lessonId=$lessonId, url=$videoUrl, startPos=$startPositionMs")

        // 진도 저장 시작
        startProgressSaving()
    }

    /**
     * HLS 스트리밍 URL로 강의 로드
     */
    fun loadHlsLesson(
        lessonId: Long,
        courseId: Long,
        hlsUrl: String,
        title: String,
        drmLicenseUrl: String? = null
    ) {
        val player = exoPlayer ?: initializePlayer()

        currentLessonId = lessonId
        currentCourseId = courseId

        val mediaItemBuilder = MediaItem.Builder()
            .setUri(Uri.parse(hlsUrl))
            .setMediaId(lessonId.toString())
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle(title)
                    .build()
            )

        // DRM 라이선스 URL이 있으면 설정
        drmLicenseUrl?.let { licenseUrl ->
            mediaItemBuilder.setDrmConfiguration(
                MediaItem.DrmConfiguration.Builder(androidx.media3.common.C.WIDEVINE_UUID)
                    .setLicenseUri(licenseUrl)
                    .build()
            )
        }

        player.setMediaItem(mediaItemBuilder.build())
        player.prepare()

        Log.i(TAG, "HLS 강의 로드: lessonId=$lessonId, url=$hlsUrl")
        startProgressSaving()
    }

    /**
     * 재생 / 일시정지 토글
     */
    fun togglePlayPause() {
        exoPlayer?.let { player ->
            if (player.isPlaying) {
                player.pause()
            } else {
                player.play()
            }
        }
    }

    /**
     * 재생
     */
    fun play() {
        exoPlayer?.play()
    }

    /**
     * 일시정지
     */
    fun pause() {
        exoPlayer?.pause()
    }

    /**
     * 특정 위치로 이동
     */
    fun seekTo(positionMs: Long) {
        exoPlayer?.seekTo(positionMs)
    }

    /**
     * 앞으로 10초
     */
    fun seekForward() {
        exoPlayer?.let { player ->
            val newPosition = minOf(player.currentPosition + SEEK_FORWARD_MS, player.duration)
            player.seekTo(newPosition)
        }
    }

    /**
     * 뒤로 10초
     */
    fun seekBack() {
        exoPlayer?.let { player ->
            val newPosition = maxOf(player.currentPosition - SEEK_BACK_MS, 0)
            player.seekTo(newPosition)
        }
    }

    /**
     * 재생 속도 설정
     */
    fun setPlaybackSpeed(speed: PlaybackSpeed) {
        exoPlayer?.setPlaybackSpeed(speed.speed)
        _currentSpeed.value = speed
        Log.d(TAG, "재생 속도 변경: ${speed.label}")
    }

    /**
     * 비디오 품질 설정
     */
    fun setVideoQuality(quality: VideoQuality) {
        trackSelector.setParameters(
            trackSelector.buildUponParameters()
                .setMaxVideoSize(Int.MAX_VALUE, quality.maxHeight)
        )
        _currentQuality.value = quality
        Log.d(TAG, "비디오 품질 변경: ${quality.label}")
    }

    /**
     * 진도 저장 시작
     */
    private fun startProgressSaving() {
        progressSaveJob?.cancel()
        progressSaveJob = serviceScope.launch {
            while (isActive) {
                delay(PROGRESS_SAVE_INTERVAL_MS)
                saveCurrentProgress()
            }
        }
    }

    /**
     * 현재 진도 저장
     */
    private suspend fun saveCurrentProgress() {
        val player = exoPlayer ?: return
        if (currentLessonId < 0) return

        val position = player.currentPosition
        val duration = player.duration

        if (duration <= 0) return

        val progressPercent = ((position.toFloat() / duration) * 100).toInt()
        val isCompleted = progressPercent >= LearningProgress.COMPLETION_THRESHOLD

        val progress = LearningProgress(
            lessonId = currentLessonId,
            courseId = currentCourseId,
            currentPositionMs = position,
            durationMs = duration,
            progressPercent = progressPercent,
            isCompleted = isCompleted
        )

        progressRepository.saveProgress(progress)
        Log.d(TAG, "진도 저장: lessonId=$currentLessonId, progress=$progressPercent%")
    }

    /**
     * 위치 업데이트 시작
     */
    private fun startPositionUpdates() {
        serviceScope.launch {
            while (isActive) {
                exoPlayer?.let { player ->
                    _currentPosition.value = player.currentPosition
                    _duration.value = player.duration.coerceAtLeast(0)
                    _bufferedPosition.value = player.bufferedPosition
                    _isPlaying.value = player.isPlaying
                }
                delay(500) // 0.5초마다 업데이트
            }
        }
    }

    /**
     * 플레이어 리스너
     */
    private val playerListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            _playbackState.value = when (playbackState) {
                Player.STATE_IDLE -> PlaybackState.Idle
                Player.STATE_BUFFERING -> PlaybackState.Buffering
                Player.STATE_READY -> PlaybackState.Ready
                Player.STATE_ENDED -> {
                    // 재생 완료 시 진도 저장
                    serviceScope.launch { saveCurrentProgress() }
                    PlaybackState.Ended
                }
                else -> PlaybackState.Idle
            }
            Log.d(TAG, "재생 상태 변경: ${_playbackState.value}")
        }

        override fun onPlayerError(error: PlaybackException) {
            val errorMessage = when (error.errorCode) {
                PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED ->
                    "네트워크 연결에 실패했습니다."
                PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT ->
                    "네트워크 연결 시간이 초과되었습니다."
                PlaybackException.ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED ->
                    "지원하지 않는 영상 형식입니다."
                PlaybackException.ERROR_CODE_DRM_LICENSE_ACQUISITION_FAILED ->
                    "DRM 라이선스를 가져올 수 없습니다."
                else -> "영상 재생 중 오류가 발생했습니다. (${error.errorCode})"
            }

            _playbackState.value = PlaybackState.Error(errorMessage)
            Log.e(TAG, "재생 오류: $errorMessage", error)
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            _isPlaying.value = isPlaying
        }
    }

    /**
     * 현재 플레이어 인스턴스 반환
     */
    fun getPlayer(): ExoPlayer? = exoPlayer

    /**
     * 플레이어 해제
     */
    fun releasePlayer() {
        // 마지막 진도 저장
        serviceScope.launch {
            saveCurrentProgress()
        }

        progressSaveJob?.cancel()
        exoPlayer?.removeListener(playerListener)
        exoPlayer?.release()
        exoPlayer = null
        currentLessonId = -1
        currentCourseId = -1

        Log.i(TAG, "ExoPlayer 해제 완료")
    }

    /**
     * 서비스 종료
     */
    fun destroy() {
        releasePlayer()
        serviceScope.cancel()
    }
}
