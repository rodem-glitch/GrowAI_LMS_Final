// polytech-lms-android/app/src/main/java/kr/polytech/lms/player/LearningProgressRepository.kt
package kr.polytech.lms.player

import android.content.Context
import android.util.Log
import androidx.room.*
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 학습 진도 Repository
 * 로컬 + 서버 동기화
 */
@Singleton
class LearningProgressRepository @Inject constructor(
    private val progressDao: LearningProgressDao,
    private val progressApi: LearningProgressApi
) {
    companion object {
        private const val TAG = "LearningProgressRepo"
    }

    /**
     * 진도 저장 (로컬 + 서버)
     */
    suspend fun saveProgress(progress: LearningProgress) {
        withContext(Dispatchers.IO) {
            try {
                // 1. 로컬 DB 저장
                val entity = LearningProgressEntity(
                    lessonId = progress.lessonId,
                    courseId = progress.courseId,
                    currentPositionMs = progress.currentPositionMs,
                    durationMs = progress.durationMs,
                    progressPercent = progress.progressPercent,
                    isCompleted = progress.isCompleted,
                    lastWatchedAt = progress.lastWatchedAt,
                    isSynced = false
                )
                progressDao.insertOrUpdate(entity)

                // 2. 서버 동기화 시도
                try {
                    val response = progressApi.saveProgress(progress.lessonId, progress)
                    if (response.isSuccessful) {
                        progressDao.markAsSynced(progress.lessonId)
                        Log.d(TAG, "서버 동기화 완료: lessonId=${progress.lessonId}")
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "서버 동기화 실패 (나중에 재시도): ${e.message}")
                }

            } catch (e: Exception) {
                Log.e(TAG, "진도 저장 실패", e)
            }
        }
    }

    /**
     * 강의별 진도 조회
     */
    suspend fun getProgress(lessonId: Long): LearningProgress? {
        return withContext(Dispatchers.IO) {
            try {
                // 로컬 DB 우선 조회
                val local = progressDao.getProgress(lessonId)
                if (local != null) {
                    return@withContext local.toProgress()
                }

                // 서버에서 조회
                val response = progressApi.getProgress(lessonId)
                if (response.isSuccessful) {
                    response.body()?.let { progress ->
                        // 로컬 저장
                        progressDao.insertOrUpdate(
                            LearningProgressEntity.fromProgress(progress).copy(isSynced = true)
                        )
                        return@withContext progress
                    }
                }

                null
            } catch (e: Exception) {
                Log.e(TAG, "진도 조회 실패", e)
                null
            }
        }
    }

    /**
     * 과정별 전체 진도 조회
     */
    fun getCourseProgressFlow(courseId: Long): Flow<List<LearningProgressEntity>> {
        return progressDao.getCourseProgressFlow(courseId)
    }

    /**
     * 미동기화 진도 동기화
     */
    suspend fun syncUnsyncedProgress() {
        withContext(Dispatchers.IO) {
            try {
                val unsyncedList = progressDao.getUnsyncedProgress()

                for (entity in unsyncedList) {
                    try {
                        val response = progressApi.saveProgress(
                            entity.lessonId,
                            entity.toProgress()
                        )
                        if (response.isSuccessful) {
                            progressDao.markAsSynced(entity.lessonId)
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "동기화 실패: lessonId=${entity.lessonId}")
                    }
                }

                Log.i(TAG, "동기화 완료: ${unsyncedList.size}건")
            } catch (e: Exception) {
                Log.e(TAG, "동기화 작업 실패", e)
            }
        }
    }

    /**
     * 완료된 강의 목록
     */
    suspend fun getCompletedLessons(courseId: Long): List<Long> {
        return withContext(Dispatchers.IO) {
            progressDao.getCompletedLessonIds(courseId)
        }
    }
}

/**
 * Room Entity
 */
@Entity(tableName = "learning_progress")
data class LearningProgressEntity(
    @PrimaryKey
    val lessonId: Long,
    val courseId: Long,
    val currentPositionMs: Long,
    val durationMs: Long,
    val progressPercent: Int,
    val isCompleted: Boolean,
    val lastWatchedAt: Long,
    val isSynced: Boolean = false
) {
    fun toProgress() = LearningProgress(
        lessonId = lessonId,
        courseId = courseId,
        currentPositionMs = currentPositionMs,
        durationMs = durationMs,
        progressPercent = progressPercent,
        isCompleted = isCompleted,
        lastWatchedAt = lastWatchedAt
    )

    companion object {
        fun fromProgress(p: LearningProgress) = LearningProgressEntity(
            lessonId = p.lessonId,
            courseId = p.courseId,
            currentPositionMs = p.currentPositionMs,
            durationMs = p.durationMs,
            progressPercent = p.progressPercent,
            isCompleted = p.isCompleted,
            lastWatchedAt = p.lastWatchedAt
        )
    }
}

/**
 * Room DAO
 */
@Dao
interface LearningProgressDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(progress: LearningProgressEntity)

    @Query("SELECT * FROM learning_progress WHERE lessonId = :lessonId")
    suspend fun getProgress(lessonId: Long): LearningProgressEntity?

    @Query("SELECT * FROM learning_progress WHERE courseId = :courseId ORDER BY lastWatchedAt DESC")
    fun getCourseProgressFlow(courseId: Long): Flow<List<LearningProgressEntity>>

    @Query("SELECT * FROM learning_progress WHERE isSynced = 0")
    suspend fun getUnsyncedProgress(): List<LearningProgressEntity>

    @Query("UPDATE learning_progress SET isSynced = 1 WHERE lessonId = :lessonId")
    suspend fun markAsSynced(lessonId: Long)

    @Query("SELECT lessonId FROM learning_progress WHERE courseId = :courseId AND isCompleted = 1")
    suspend fun getCompletedLessonIds(courseId: Long): List<Long>

    @Query("DELETE FROM learning_progress WHERE lessonId = :lessonId")
    suspend fun delete(lessonId: Long)
}

/**
 * Room Database
 */
@Database(entities = [LearningProgressEntity::class], version = 1, exportSchema = false)
abstract class LmsDatabase : RoomDatabase() {
    abstract fun learningProgressDao(): LearningProgressDao
}

/**
 * Retrofit API
 */
interface LearningProgressApi {
    @POST("api/v1/learning/progress/{lessonId}")
    suspend fun saveProgress(
        @Path("lessonId") lessonId: Long,
        @Body progress: LearningProgress
    ): Response<Unit>

    @GET("api/v1/learning/progress/{lessonId}")
    suspend fun getProgress(@Path("lessonId") lessonId: Long): Response<LearningProgress>
}

/**
 * DI Module
 */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    @Provides
    @Singleton
    fun provideLmsDatabase(@ApplicationContext context: Context): LmsDatabase {
        return Room.databaseBuilder(
            context,
            LmsDatabase::class.java,
            "polytech_lms.db"
        ).build()
    }

    @Provides
    @Singleton
    fun provideLearningProgressDao(database: LmsDatabase): LearningProgressDao {
        return database.learningProgressDao()
    }
}
