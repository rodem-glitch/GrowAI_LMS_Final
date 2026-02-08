// polytech-lms-api/src/main/java/kr/polytech/lms/bbb/controller/VideoConferenceController.java
package kr.polytech.lms.bbb.controller;

import kr.polytech.lms.bbb.client.BigBlueButtonClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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

        Map<String, Object> result = bbbClient.createMeeting(meetingId, roomName, attendeePw, moderatorPw);
        result.put("meetingId", meetingId);
        result.put("attendeePassword", attendeePw);
        result.put("moderatorPassword", moderatorPw);

        return ResponseEntity.ok(result);
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

        String joinUrl = bbbClient.getJoinUrl(meetingId, userName, password, isModerator);

        return ResponseEntity.ok(Map.of(
            "joinUrl", joinUrl,
            "meetingId", meetingId
        ));
    }

    /**
     * 강의실 정보 조회
     */
    @GetMapping("/rooms/{meetingId}")
    public ResponseEntity<Map<String, Object>> getRoomInfo(@PathVariable String meetingId) {
        log.info("강의실 정보 조회: {}", meetingId);
        return ResponseEntity.ok(bbbClient.getMeetingInfo(meetingId));
    }

    /**
     * 강의실 종료
     */
    @DeleteMapping("/rooms/{meetingId}")
    public ResponseEntity<Map<String, Object>> endRoom(
            @PathVariable String meetingId,
            @RequestParam String moderatorPassword) {
        log.info("강의실 종료: {}", meetingId);
        return ResponseEntity.ok(bbbClient.endMeeting(meetingId, moderatorPassword));
    }

    /**
     * 활성 강의실 목록 조회
     */
    @GetMapping("/rooms")
    public ResponseEntity<Map<String, Object>> getActiveRooms() {
        log.info("활성 강의실 목록 조회");
        return ResponseEntity.ok(bbbClient.getMeetings());
    }

    /**
     * 녹화 목록 조회
     */
    @GetMapping("/rooms/{meetingId}/recordings")
    public ResponseEntity<Map<String, Object>> getRecordings(@PathVariable String meetingId) {
        log.info("녹화 목록 조회: {}", meetingId);
        return ResponseEntity.ok(bbbClient.getRecordings(meetingId));
    }

    /**
     * 강의실 실행 상태 확인
     */
    @GetMapping("/rooms/{meetingId}/status")
    public ResponseEntity<Map<String, Object>> getRoomStatus(@PathVariable String meetingId) {
        boolean running = bbbClient.isMeetingRunning(meetingId);
        return ResponseEntity.ok(Map.of(
            "meetingId", meetingId,
            "running", running
        ));
    }

    private String generatePassword() {
        return UUID.randomUUID().toString().substring(0, 8);
    }
}
