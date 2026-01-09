package kr.polytech.lms.recocontent.repository;

import java.util.List;
import kr.polytech.lms.recocontent.entity.RecoContent;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RecoContentRepository extends JpaRepository<RecoContent, Long> {
    @Query(
        """
        select r
          from RecoContent r
         where r.title like concat('%', :q, '%')
            or r.keywords like concat('%', :q, '%')
            or r.summary like concat('%', :q, '%')
        """
    )
    List<RecoContent> searchByKeyword(@Param("q") String query, Pageable pageable);
}
