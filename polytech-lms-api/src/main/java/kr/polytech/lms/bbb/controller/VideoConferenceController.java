// polytech-lms-api/src/main/java/kr/polytech/lms/bbb/controller/VideoConferenceController.java
package kr.polytech.lms.bbb.controller;

import kr.polytech.lms.bbb.client.BigBlueButtonClient;
import kr.polytech.lms.security.error.ExternalServiceException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

/**
 * 화상강의 API 컨트롤러
 * BigBlueButton 연동 엔드포인트
 */
@Slf4j
@RestController
@RequestMapping("/api/video-conference")
@RequiredArgsConstructor
public class VideoConferenceController {

    private final BigBlueButtonClient bbbClient;

    /**
     * 강의실 생성
     */
    @PostMapping("/rooms")
    public ResponseEntity<Map<String, Object>> createRoom(
            @RequestParam String roomName,
            @RequestParam(required = false) String courseId) {

        String meetingId = "course-" + (courseId != null ? courseId : UUID.randomUUID().toString());
        String attendeePw = generatePassword();
        String moderatorPw = generatePassword();

        log.info("화상강의실 생성: roomName={}, meetingId={}", roomName, meetingId);

        try {
            Map<String, Object> result = bbbClient.createMeeting(meetingId, roomName, attendeePw, moderatorPw);
            result.put("meetingId", meetingId);
            result.put("attendeePassword", attendeePw);
            result.put("moderatorPassword", moderatorPw);
            return ResponseEntity.ok(Map.of("success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("화상강의실 생성 실패: meetingId={}", meetingId, e);
            throw new ExternalServiceException("BigBlueButton", "CONFERENCE_001",
                "화상 강의 방 생성에 실패했습니다.", e);
        }
    }

    /**
     * 강의실 참여 URL 생성
     */
    @GetMapping("/rooms/{meetingId}/join")
    public ResponseEntity<Map<String, Object>> getJoinUrl(
            @PathVariable String meetingId,
            @RequestParam String userName,
            @RequestParam String password,
            @RequestParam(defaultValue = "false") boolean isModerator) {

        log.info("강의실 참여 URL 생성: meetingId={}, userName={}", meetingId, userName);

        try {
            String joinUrl = bbbClient.getJoinUrl(meetingId, userName, password, isModerator);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("joinUrl", joinUrl, "meetingId", meetingId),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("참여 URL 생성 실패: meetingId={}", meetingId, e);
            throw new ExternalServiceException("BigBlueButton", "CONFERENCE_002",
                "화상 강의 방을 찾을 수 없습니다.", e);
        }
    }

    /**
     * 강의실 정보 조회
     */
    @GetMapping("/rooms/{meetingId}")
    public ResponseEntity<Map<String, Object>> getRoomInfo(@PathVariable String meetingId) {
        log.info("강의실 정보 조회: {}", meetingId);
        try {
            Map<String, Object> info = bbbClient.getMeetingInfo(meetingId);
            return ResponseEntity.ok(Map.of("success", true, "data", info,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("강의실 정보 조회 실패: meetingId={}", meetingId, e);
            throw new ExternalServiceException("BigBlueButton", "CONFERENCE_002",
                "화상 강의 방을 찾을 수 없습니다.", e);
        }
    }

    /**
     * 강의실 종료
     */
    @DeleteMapping("/rooms/{meetingId}")
    public ResponseEntity<Map<String, Object>> endRoom(
            @PathVariable String meetingId,
            @RequestParam String moderatorPassword) {
        log.info("강의실 종료: {}", meetingId);
        try {
            Map<String, Object> result = bbbClient.endMeeting(meetingId, moderatorPassword);
            return ResponseEntity.ok(Map.of("success", true, "data", result,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("강의실 종료 실패: meetingId={}", meetingId, e);
            throw new ExternalServiceException("BigBlueButton", "CONFERENCE_002",
                "화상 강의 방을 찾을 수 없습니다.", e);
        }
    }

    /**
     * 활성 강의실 목록 조회
     */
    @GetMapping("/rooms")
    public ResponseEntity<Map<String, Object>> getActiveRooms() {
        log.info("활성 강의실 목록 조회");
        try {
            Map<String, Object> rooms = bbbClient.getMeetings();
            return ResponseEntity.ok(Map.of("success", true, "data", rooms,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("활성 강의실 목록 조회 실패", e);
            throw new ExternalServiceException("BigBlueButton", "CONFERENCE_002",
                "화상 강의 목록 조회에 실패했습니다.", e);
        }
    }

    /**
     * 녹화 목록 조회
     */
    @GetMapping("/rooms/{meetingId}/recordings")
    public ResponseEntity<Map<String, Object>> getRecordings(@PathVariable String meetingId) {
        log.info("녹화 목록 조회: {}", meetingId);
        try {
            Map<String, Object> recordings = bbbClient.getRecordings(meetingId);
            return ResponseEntity.ok(Map.of("success", true, "data", recordings,
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("녹화 목록 조회 실패: meetingId={}", meetingId, e);
            throw new ExternalServiceException("BigBlueButton", "CONFERENCE_002",
                "녹화 목록 조회에 실패했습니다.", e);
        }
    }

    /**
     * 강의실 실행 상태 확인
     */
    @GetMapping("/rooms/{meetingId}/status")
    public ResponseEntity<Map<String, Object>> getRoomStatus(@PathVariable String meetingId) {
        try {
            boolean running = bbbClient.isMeetingRunning(meetingId);
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", Map.of("meetingId", meetingId, "running", running),
                "timestamp", LocalDateTime.now().toString()));
        } catch (Exception e) {
            log.error("강의실 상태 확인 실패: meetingId={}", meetingId, e);
            throw new ExternalServiceException("BigBlueButton", "CONFERENCE_002",
                "화상 강의 방을 찾을 수 없습니다.", e);
        }
    }

    private String generatePassword() {
        return UUID.randomUUID().toString().substring(0, 8);
    }
}
