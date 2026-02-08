// board/entity/Post.java — 게시글 엔티티
package kr.polytech.epoly.board.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "boards")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class Post {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** NOTICE, QNA, FREE, FAQ */
    @Column(nullable = false, length = 20)
    private String boardType;

    private Long courseId;

    @Column(nullable = false, length = 300)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(nullable = false)
    private Long authorId;

    @Column(length = 50)
    private String authorName;

    @Builder.Default
    private Integer viewCount = 0;

    @Builder.Default
    private Boolean isPinned = false;

    @Column(length = 500)
    private String attachmentUrl;

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
