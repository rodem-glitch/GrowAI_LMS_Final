package kr.polytech.lms.recocontent.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "TB_RECO_CONTENT")
public class RecoContent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "category_nm", nullable = false, length = 100)
    private String categoryNm;

    @Column(name = "title", nullable = false, length = 200)
    private String title;

    @Column(name = "summary", nullable = false, columnDefinition = "TEXT")
    private String summary;

    @Column(name = "keywords", nullable = false, length = 500)
    private String keywords;

    protected RecoContent() {
        // 왜: JPA 프록시/리플렉션을 위한 기본 생성자가 필요합니다.
    }

    public RecoContent(String categoryNm, String title, String summary, String keywords) {
        // 왜: 원본 데이터는 최대한 "있는 그대로" 보관하고, 벡터화/검색은 별도 계층에서 처리합니다.
        this.categoryNm = categoryNm;
        this.title = title;
        this.summary = summary;
        this.keywords = keywords;
    }

    public Long getId() {
        return id;
    }

    public String getCategoryNm() {
        return categoryNm;
    }

    public String getTitle() {
        return title;
    }

    public String getSummary() {
        return summary;
    }

    public String getKeywords() {
        return keywords;
    }
}

