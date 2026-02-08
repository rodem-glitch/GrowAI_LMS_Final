// board/repository/CommentRepository.java — 댓글 레포지토리
package kr.polytech.epoly.board.repository;

import kr.polytech.epoly.board.entity.Comment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CommentRepository extends JpaRepository<Comment, Long> {

    List<Comment> findByPostIdOrderByCreatedAtAsc(Long postId);

    long countByPostId(Long postId);
}
