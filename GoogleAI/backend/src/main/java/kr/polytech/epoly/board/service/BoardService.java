// board/service/BoardService.java — 게시판 서비스
package kr.polytech.epoly.board.service;

import kr.polytech.epoly.board.entity.Comment;
import kr.polytech.epoly.board.entity.Post;
import kr.polytech.epoly.board.repository.CommentRepository;
import kr.polytech.epoly.board.repository.PostRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BoardService {

    private final PostRepository postRepository;
    private final CommentRepository commentRepository;

    public Post findById(Long id) {
        return postRepository.findById(id)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("게시글을 찾을 수 없습니다: " + id));
    }

    public Page<Post> findByBoardType(String boardType, Pageable pageable) {
        return postRepository.findByBoardType(boardType, pageable);
    }

    public Page<Post> findByCourse(Long courseId, Pageable pageable) {
        return postRepository.findByCourseId(courseId, pageable);
    }

    public Page<Post> search(String keyword, Pageable pageable) {
        return postRepository.findByTitleContainingOrContentContaining(keyword, keyword, pageable);
    }

    @Transactional
    public Post createPost(Post post) {
        return postRepository.save(post);
    }

    @Transactional
    public Post updatePost(Long id, Post updated) {
        Post post = findById(id);
        post.setTitle(updated.getTitle());
        post.setContent(updated.getContent());
        return postRepository.save(post);
    }

    @Transactional
    public void deletePost(Long id) {
        postRepository.deleteById(id);
    }

    /** 조회수 증가 */
    @Transactional
    public Post increaseViewCount(Long id) {
        Post post = findById(id);
        post.setViewCount(post.getViewCount() + 1);
        return postRepository.save(post);
    }

    // ── 댓글 ──
    public List<Comment> getComments(Long postId) {
        return commentRepository.findByPostIdOrderByCreatedAtAsc(postId);
    }

    @Transactional
    public Comment addComment(Comment comment) {
        return commentRepository.save(comment);
    }

    @Transactional
    public void deleteComment(Long commentId) {
        commentRepository.deleteById(commentId);
    }
}
