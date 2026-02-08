// board/controller/BoardController.java — 게시판 API
package kr.polytech.epoly.board.controller;

import kr.polytech.epoly.board.entity.Comment;
import kr.polytech.epoly.board.entity.Post;
import kr.polytech.epoly.board.service.BoardService;
import kr.polytech.epoly.common.ApiResponse;
import kr.polytech.epoly.user.entity.User;
import kr.polytech.epoly.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/boards")
@RequiredArgsConstructor
public class BoardController {

    private final BoardService boardService;
    private final UserService userService;

    /** 게시글 목록 */
    @GetMapping
    public ResponseEntity<ApiResponse<Page<Post>>> list(
            @RequestParam(defaultValue = "NOTICE") String boardType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<Post> posts = boardService.findByBoardType(boardType,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")));
        return ResponseEntity.ok(ApiResponse.ok(posts));
    }

    /** 게시글 검색 */
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<Page<Post>>> search(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<Post> posts = boardService.search(keyword, PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.ok(posts));
    }

    /** 게시글 상세 */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Post>> detail(@PathVariable Long id) {
        Post post = boardService.increaseViewCount(id);
        return ResponseEntity.ok(ApiResponse.ok(post));
    }

    /** 게시글 작성 */
    @PostMapping
    public ResponseEntity<ApiResponse<Post>> create(
            @RequestBody Post post, Authentication auth) {
        User user = userService.findByUserId(auth.getName());
        post.setAuthorId(user.getId());
        post.setAuthorName(user.getName());
        return ResponseEntity.ok(ApiResponse.ok(boardService.createPost(post)));
    }

    /** 게시글 수정 */
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Post>> update(
            @PathVariable Long id, @RequestBody Post post) {
        return ResponseEntity.ok(ApiResponse.ok(boardService.updatePost(id, post)));
    }

    /** 게시글 삭제 */
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
        boardService.deletePost(id);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    // ── 댓글 ──

    /** 댓글 목록 */
    @GetMapping("/{postId}/comments")
    public ResponseEntity<ApiResponse<List<Comment>>> comments(@PathVariable Long postId) {
        return ResponseEntity.ok(ApiResponse.ok(boardService.getComments(postId)));
    }

    /** 댓글 작성 */
    @PostMapping("/{postId}/comments")
    public ResponseEntity<ApiResponse<Comment>> addComment(
            @PathVariable Long postId, @RequestBody Comment comment, Authentication auth) {
        User user = userService.findByUserId(auth.getName());
        comment.setPostId(postId);
        comment.setAuthorId(user.getId());
        comment.setAuthorName(user.getName());
        return ResponseEntity.ok(ApiResponse.ok(boardService.addComment(comment)));
    }
}
