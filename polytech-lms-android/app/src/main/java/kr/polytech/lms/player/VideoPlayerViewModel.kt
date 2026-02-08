// polytech-lms-android/app/src/main/java/kr/polytech/lms/player/VideoPlayerViewModel.kt
package kr.polytech.lms.player

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 비디오 플레이어 ViewModel
 */
@HiltViewModel
class VideoPlayerViewModel @Inject constructor(
    private val savedStateHandle: SavedStateHandle,
    private val progressRepository: LearningProgressRepository
) : ViewModel() {

    // 현재 강의 정보
    private val _lessonInfo = MutableStateFlow<LessonInfo?>(null)
    val lessonInfo: StateFlow<LessonInfo?> = _lessonInfo.asStateFlow()

    // 학습 진도
    private val _progress = MutableStateFlow<LearningProgress?>(null)
    val progress: StateFlow<LearningProgress?> = _progress.asStateFlow()

    // 과정 내 완료된 강의 수
    private val _completedCount = MutableStateFlow(0)
    val completedCount: StateFlow<Int> = _completedCount.asStateFlow()

    /**
     * 강의 정보 로드
     */
    fun loadLessonInfo(lessonId: Long, courseId: Long) {
        viewModelScope.launch {
            // 이전 진도 조회
            val savedProgress = progressRepository.getProgress(lessonId)
            _progress.value = savedProgress

            // 완료된 강의 수 조회
            val completedLessons = progressRepository.getCompletedLessons(courseId)
            _completedCount.value = completedLessons.size
        }
    }

    /**
     * 진도 동기화
     */
    fun syncProgress() {
        viewModelScope.launch {
            progressRepository.syncUnsyncedProgress()
        }
    }
}

/**
 * 강의 정보
 */
data class LessonInfo(
    val lessonId: Long,
    val courseId: Long,
    val title: String,
    val description: String?,
    val videoUrl: String,
    val duration: Long,
    val order: Int,
    val isRequired: Boolean = true
)
