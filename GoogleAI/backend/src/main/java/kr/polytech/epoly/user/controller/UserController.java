// user/controller/UserController.java — 사용자 API
package kr.polytech.epoly.user.controller;

import kr.polytech.epoly.common.ApiResponse;
import kr.polytech.epoly.user.entity.User;
import kr.polytech.epoly.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /** 내 정보 조회 */
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<User>> getMe(Authentication auth) {
        User user = userService.findByUserId(auth.getName());
        return ResponseEntity.ok(ApiResponse.ok(user));
    }

    /** 사용자 상세 */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<User>> getUser(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(userService.findById(id)));
    }

    /** 사용자 검색 */
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<User>>> search(@RequestParam String keyword) {
        List<User> users = userService.searchUsers(keyword);
        return ResponseEntity.ok(ApiResponse.ok(users, users.size()));
    }

    /** 사용자 정보 수정 */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<User>> update(@PathVariable Long id, @RequestBody User user) {
        return ResponseEntity.ok(ApiResponse.ok(userService.updateUser(id, user)));
    }
}
