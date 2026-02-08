// board/repository/PostRepository.java — 게시글 레포지토리
package kr.polytech.epoly.board.repository;

import kr.polytech.epoly.board.entity.Post;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PostRepository extends JpaRepository<Post, Long> {

    Page<Post> findByBoardType(String boardType, Pageable pageable);

    Page<Post> findByCourseId(Long courseId, Pageable pageable);

    List<Post> findByBoardTypeAndIsPinnedTrueOrderByCreatedAtDesc(String boardType);

    Page<Post> findByTitleContainingOrContentContaining(String titleKeyword, String contentKeyword, Pageable pageable);
}
