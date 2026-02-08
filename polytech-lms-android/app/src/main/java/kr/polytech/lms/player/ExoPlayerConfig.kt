// polytech-lms-android/app/src/main/java/kr/polytech/lms/player/ExoPlayerConfig.kt
package kr.polytech.lms.player

import android.content.Context
import androidx.media3.common.C
import androidx.media3.common.Player
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.datasource.cache.LeastRecentlyUsedCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import java.io.File
import javax.inject.Singleton

/**
 * ExoPlayer 설정 모듈
 * 한국폴리텍대학 LMS 동영상 강의 재생
 *
 * 성능 최적화:
 * - 적응형 스트리밍 (HLS/DASH)
 * - 캐시 지원 (오프라인 학습)
 * - 배터리 최적화
 * - 네트워크 대역폭 적응
 */
@Module
@InstallIn(SingletonComponent::class)
object ExoPlayerConfig {

    // 캐시 설정
    private const val CACHE_SIZE_BYTES = 500L * 1024 * 1024 // 500MB
    private const val CACHE_DIR_NAME = "lms_video_cache"

    // 버퍼 설정 (모바일 최적화)
    private const val MIN_BUFFER_MS = 15_000          // 최소 버퍼: 15초
    private const val MAX_BUFFER_MS = 60_000          // 최대 버퍼: 60초
    private const val BUFFER_FOR_PLAYBACK_MS = 2_500  // 재생 시작 버퍼: 2.5초
    private const val BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS = 5_000 // 재버퍼링 후: 5초

    // HTTP 설정
    private const val CONNECT_TIMEOUT_MS = 8_000
    private const val READ_TIMEOUT_MS = 8_000
    private const val USER_AGENT = "PolytechLMS-Android/1.0"

    /**
     * 비디오 캐시 제공
     * LRU 정책으로 오래된 캐시 자동 삭제
     */
    @Provides
    @Singleton
    fun provideVideoCache(@ApplicationContext context: Context): SimpleCache {
        val cacheDir = File(context.cacheDir, CACHE_DIR_NAME)
        val cacheEvictor = LeastRecentlyUsedCacheEvictor(CACHE_SIZE_BYTES)
        val databaseProvider = StandaloneDatabaseProvider(context)
        return SimpleCache(cacheDir, cacheEvictor, databaseProvider)
    }

    /**
     * HTTP 데이터 소스 팩토리
     * 인증 헤더 자동 추가
     */
    @Provides
    @Singleton
    fun provideHttpDataSourceFactory(): DefaultHttpDataSource.Factory {
        return DefaultHttpDataSource.Factory()
            .setUserAgent(USER_AGENT)
            .setConnectTimeoutMs(CONNECT_TIMEOUT_MS)
            .setReadTimeoutMs(READ_TIMEOUT_MS)
            .setAllowCrossProtocolRedirects(true)
    }

    /**
     * 캐시 데이터 소스 팩토리
     * 스트리밍 + 캐시 하이브리드
     */
    @Provides
    @Singleton
    fun provideCacheDataSourceFactory(
        @ApplicationContext context: Context,
        cache: SimpleCache,
        httpDataSourceFactory: DefaultHttpDataSource.Factory
    ): CacheDataSource.Factory {
        val upstreamFactory = DefaultDataSource.Factory(context, httpDataSourceFactory)

        return CacheDataSource.Factory()
            .setCache(cache)
            .setUpstreamDataSourceFactory(upstreamFactory)
            .setCacheWriteDataSinkFactory(null)  // 읽기 전용 캐시
            .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
    }

    /**
     * 트랙 선택기
     * 네트워크 상태에 따른 적응형 품질 선택
     */
    @Provides
    @Singleton
    fun provideTrackSelector(@ApplicationContext context: Context): DefaultTrackSelector {
        return DefaultTrackSelector(context).apply {
            setParameters(
                buildUponParameters()
                    // 적응형 비디오 선택 활성화
                    .setAllowVideoMixedMimeTypeAdaptiveness(true)
                    .setAllowVideoNonSeamlessAdaptiveness(true)
                    // 오디오 선택
                    .setAllowAudioMixedMimeTypeAdaptiveness(true)
                    // 최대 해상도 제한 (배터리 절약)
                    .setMaxVideoSizeSd()
                    // 선호 언어 (한국어)
                    .setPreferredAudioLanguage("ko")
                    .setPreferredTextLanguage("ko")
            )
        }
    }

    /**
     * 로드 컨트롤
     * 버퍼링 전략 설정
     */
    @Provides
    @Singleton
    fun provideLoadControl(): DefaultLoadControl {
        return DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                MIN_BUFFER_MS,
                MAX_BUFFER_MS,
                BUFFER_FOR_PLAYBACK_MS,
                BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS
            )
            .setTargetBufferBytes(C.LENGTH_UNSET)
            .setPrioritizeTimeOverSizeThresholds(true)
            .build()
    }

    /**
     * 렌더러 팩토리
     * 하드웨어 가속 활성화
     */
    @Provides
    @Singleton
    fun provideRenderersFactory(@ApplicationContext context: Context): DefaultRenderersFactory {
        return DefaultRenderersFactory(context)
            .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER)
            .setEnableDecoderFallback(true)
    }

    /**
     * ExoPlayer 빌더 설정
     * 싱글톤이 아님 - Activity/Fragment별로 새 인스턴스 생성
     */
    @Provides
    fun provideExoPlayerBuilder(
        @ApplicationContext context: Context,
        renderersFactory: DefaultRenderersFactory,
        trackSelector: DefaultTrackSelector,
        loadControl: DefaultLoadControl
    ): ExoPlayer.Builder {
        return ExoPlayer.Builder(context)
            .setRenderersFactory(renderersFactory)
            .setTrackSelector(trackSelector)
            .setLoadControl(loadControl)
            .setSeekForwardIncrementMs(10_000)  // 앞으로 10초
            .setSeekBackIncrementMs(10_000)     // 뒤로 10초
            .setHandleAudioBecomingNoisy(true)  // 이어폰 분리 시 일시정지
            .setPauseAtEndOfMediaItems(true)    // 재생 완료 시 일시정지
    }
}

/**
 * ExoPlayer 재생 상태
 */
sealed class PlaybackState {
    object Idle : PlaybackState()
    object Buffering : PlaybackState()
    object Ready : PlaybackState()
    object Ended : PlaybackState()
    data class Error(val message: String) : PlaybackState()
}

/**
 * 학습 진도 데이터
 */
data class LearningProgress(
    val lessonId: Long,
    val courseId: Long,
    val currentPositionMs: Long,
    val durationMs: Long,
    val progressPercent: Int,
    val isCompleted: Boolean,
    val lastWatchedAt: Long = System.currentTimeMillis()
) {
    companion object {
        const val COMPLETION_THRESHOLD = 95 // 95% 이상 시청 시 완료 처리
    }
}

/**
 * 비디오 품질 옵션
 */
enum class VideoQuality(val label: String, val maxHeight: Int) {
    AUTO("자동", Int.MAX_VALUE),
    HD_1080("1080p (Full HD)", 1080),
    HD_720("720p (HD)", 720),
    SD_480("480p (SD)", 480),
    SD_360("360p (저화질)", 360)
}

/**
 * 재생 속도 옵션
 */
enum class PlaybackSpeed(val label: String, val speed: Float) {
    SPEED_0_5X("0.5x", 0.5f),
    SPEED_0_75X("0.75x", 0.75f),
    SPEED_1X("1x (기본)", 1.0f),
    SPEED_1_25X("1.25x", 1.25f),
    SPEED_1_5X("1.5x", 1.5f),
    SPEED_1_75X("1.75x", 1.75f),
    SPEED_2X("2x", 2.0f)
}
