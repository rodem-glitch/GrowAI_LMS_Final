package kr.polytech.lms.job.client;

import kr.polytech.lms.job.config.JobKoreaProperties;
import kr.polytech.lms.job.service.dto.JobRecruitItem;
import kr.polytech.lms.job.service.dto.JobRecruitListResponse;
import kr.polytech.lms.job.service.dto.JobRecruitSearchCriteria;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Component
public class JobKoreaClient {
    // 왜: 잡코리아 Open API(XML)를 호출해 공통 포맷으로 변환합니다.

    private final JobKoreaProperties properties;

    public JobKoreaClient(JobKoreaProperties properties) {
        this.properties = Objects.requireNonNull(properties);
    }

    public JobRecruitListResponse fetchRecruitList(JobRecruitSearchCriteria criteria) {
        if (!properties.isEnabled()) {
            throw new IllegalStateException("잡코리아 연동이 비활성화되어 있습니다.");
        }

        String apiUrl = properties.getApiUrl();
        if (apiUrl == null || apiUrl.isBlank()) {
            throw new IllegalStateException("잡코리아 API URL이 비어 있습니다.");
        }

        String apiKey = properties.getApiKey();
        String oemCode = properties.getOemCode();
        if (apiKey == null || apiKey.isBlank() || oemCode == null || oemCode.isBlank()) {
            throw new IllegalStateException("잡코리아 API 키 또는 OEM 코드가 비어 있습니다.");
        }

        String requestUrl = buildRequestUrl(apiUrl, apiKey, oemCode, criteria);
        Document response = requestXml(requestUrl);

        int total = parseInt(getFirstText(response, "TotalCnt"), 0);
        int startPage = criteria.startPage();
        int display = criteria.display();

        List<JobRecruitItem> items = parseGiList(response);
        return new JobRecruitListResponse(total, startPage, display, items);
    }

    private String buildRequestUrl(String apiUrl, String apiKey, String oemCode, JobRecruitSearchCriteria criteria) {
        UriComponentsBuilder builder = UriComponentsBuilder.fromHttpUrl(apiUrl)
            .queryParam(properties.getApiKeyParam(), apiKey)
            .queryParam(properties.getOemCodeParam(), oemCode);

        if (properties.getPageParam() != null && !properties.getPageParam().isBlank()) {
            builder.queryParam(properties.getPageParam(), criteria.startPage());
        }
        if (properties.getDisplayParam() != null && !properties.getDisplayParam().isBlank()) {
            builder.queryParam(properties.getDisplayParam(), criteria.display());
        }
        if (criteria.region() != null && properties.getRegionParam() != null && !properties.getRegionParam().isBlank()) {
            builder.queryParam(properties.getRegionParam(), criteria.region().trim());
        }
        if (criteria.occupation() != null && properties.getOccupationParam() != null && !properties.getOccupationParam().isBlank()) {
            builder.queryParam(properties.getOccupationParam(), criteria.occupation().trim());
        }

        for (Map.Entry<String, String> entry : properties.getParams().entrySet()) {
            if (entry.getKey() == null || entry.getKey().isBlank()) {
                continue;
            }
            String value = entry.getValue();
            if (value == null || value.isBlank()) {
                continue;
            }
            builder.queryParam(entry.getKey(), value);
        }

        return builder.build(true).toUriString();
    }

    private Document requestXml(String requestUrl) {
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document document = builder.parse(requestUrl);
            document.getDocumentElement().normalize();
            return document;
        } catch (Exception e) {
            throw new IllegalStateException("잡코리아 API 호출에 실패했습니다: " + e.getMessage(), e);
        }
    }

    private List<JobRecruitItem> parseGiList(Document document) {
        List<JobRecruitItem> items = new ArrayList<>();
        if (document == null) return items;

        NodeList giList = document.getElementsByTagName("GI_List");
        if (giList == null || giList.getLength() == 0) return items;

        for (int i = 0; i < giList.getLength(); i++) {
            NodeList childNodes = giList.item(i).getChildNodes();

            String giNo = null;
            String giSubject = null;
            String company = null;
            String areaCode = null;
            String jobCode = null;
            String giCareer = null;
            String giWDate = null;
            String giEndDate = null;
            String jkUrl = null;
            String empType = null;

            for (int j = 0; j < childNodes.getLength(); j++) {
                Node node = childNodes.item(j);
                String nodeName = node.getNodeName();
                String text = node.getTextContent();

                switch (nodeName) {
                    case "GI_No" -> giNo = text;
                    case "GI_Subject" -> giSubject = text;
                    case "C_Name" -> company = text;
                    case "AreaCode" -> areaCode = text;
                    case "Job_Ctgr_Code" -> jobCode = text;
                    case "GI_Career" -> giCareer = text;
                    case "GI_W_Date" -> giWDate = text;
                    case "GI_End_Date" -> giEndDate = text;
                    case "JK_URL" -> jkUrl = text;
                    case "Emp_Type" -> empType = text;
                    default -> {
                        // 사용하지 않는 필드는 무시합니다.
                    }
                }
            }

            items.add(new JobRecruitItem(
                giNo,
                company,
                null,
                null,
                giSubject,
                null,
                null,
                null,
                null,
                areaCode,
                null,
                null,
                giCareer,
                giWDate,
                giEndDate,
                "JOBKOREA",
                jkUrl,
                jkUrl,
                null,
                null,
                null,
                null,
                null,
                empType,
                jobCode
            ));
        }

        return items;
    }

    private String getFirstText(Document document, String tagName) {
        if (document == null || tagName == null) return null;
        NodeList list = document.getElementsByTagName(tagName);
        if (list == null || list.getLength() == 0) return null;
        return list.item(0).getTextContent();
    }

    private int parseInt(String raw, int fallback) {
        if (raw == null || raw.isBlank()) return fallback;
        try {
            return Integer.parseInt(raw.trim());
        } catch (NumberFormatException e) {
            return fallback;
        }
    }
}
