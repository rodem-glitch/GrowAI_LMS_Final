package kr.polytech.lms.statistics.kosis.client;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.polytech.lms.statistics.kosis.client.dto.KosisPopulationRow;
import kr.polytech.lms.statistics.kosis.config.KosisProperties;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;
import java.net.URI;
import java.time.Clock;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

@Component
public class KosisClient {
    // 왜: KOSIS API 호출/토큰 관리를 한 곳에 모아(클라이언트) 컨트롤러/서비스를 단순화합니다.

    private final KosisProperties properties;
    private final RestClient restClient;
    private final ObjectMapper objectMapper;
    private final Clock clock;

    private final AtomicReference<KosisToken> cachedToken = new AtomicReference<>();

    public KosisClient(
            KosisProperties properties,
            ObjectMapper objectMapper
    ) {
        this.properties = properties;
        this.restClient = RestClient.create();
        this.objectMapper = objectMapper;
        this.clock = Clock.systemUTC();
    }

    public List<KosisPopulationRow> fetchPopulation(String year, String ageType, String gender) throws IOException {
        // 왜: 토큰 만료를 신경 쓰지 않도록, 호출 시점에 자동으로 토큰을 확보합니다.
        KosisToken token = getOrRefreshToken();

        URI uri = UriComponentsBuilder.fromHttpUrl(properties.getPopulationUrl())
                .queryParam("accessToken", token.accessToken())
                .queryParam("year", year)
                .queryParam("age_type", ageType)
                .queryParam("gender", gender)
                .build(true)
                .toUri();

        String responseBody = restClient.get().uri(uri).retrieve().body(String.class);

        return parsePopulationResponse(responseBody);
    }

    private KosisToken getOrRefreshToken() throws IOException {
        KosisToken existing = cachedToken.get();
        if (existing != null && existing.isValid(clock.millis())) {
            return existing;
        }

        KosisToken refreshed = requestNewToken();
        cachedToken.set(refreshed);
        return refreshed;
    }

    private KosisToken requestNewToken() throws IOException {
        validateKosisCredentials();

        URI uri = UriComponentsBuilder.fromHttpUrl(properties.getAuthUrl())
                .queryParam("consumer_key", properties.getConsumerKey())
                .queryParam("consumer_secret", properties.getConsumerSecret())
                .build(true)
                .toUri();

        String responseBody = restClient.get().uri(uri).retrieve().body(String.class);

        return parseTokenResponse(responseBody);
    }

    private void validateKosisCredentials() {
        // 왜: 키/시크릿이 없을 때는 KOSIS 호출 자체가 불가능하므로, 빠르게 명확한 에러를 냅니다.
        if (!StringUtils.hasText(properties.getConsumerKey()) || !StringUtils.hasText(properties.getConsumerSecret())) {
            throw new IllegalStateException("KOSIS 설정이 없습니다. 환경변수 KOSIS_CONSUMER_KEY / KOSIS_CONSUMER_SECRET 를 설정해 주세요.");
        }
        if (!StringUtils.hasText(properties.getAuthUrl()) || !StringUtils.hasText(properties.getPopulationUrl())) {
            throw new IllegalStateException("KOSIS URL 설정이 비어 있습니다. kosis.auth-url / kosis.population-url 을 확인해 주세요.");
        }
    }

    private KosisToken parseTokenResponse(String responseBody) throws IOException {
        JsonNode root = objectMapper.readTree(Objects.requireNonNullElse(responseBody, ""));
        JsonNode result = root.path("result");

        String accessToken = result.path("accessToken").asText(null);
        long accessTimeout = result.path("accessTimeout").asLong(0);

        if (!StringUtils.hasText(accessToken) || accessTimeout <= 0) {
            throw new IllegalStateException("KOSIS 토큰 응답 파싱에 실패했습니다. 응답 형식을 확인해 주세요.");
        }

        return new KosisToken(accessToken, accessTimeout);
    }

    private List<KosisPopulationRow> parsePopulationResponse(String responseBody) throws IOException {
        JsonNode root = objectMapper.readTree(Objects.requireNonNullElse(responseBody, ""));
        JsonNode resultNode = root.path("result");

        return objectMapper.readValue(
                resultNode.traverse(),
                new TypeReference<>() {
                }
        );
    }

    private record KosisToken(String accessToken, long accessTimeoutEpochMs) {
        boolean isValid(long nowEpochMs) {
            // 왜: 레거시와 동일하게 "현재 시각 < 만료 시각" 기준으로 유효성을 판단합니다.
            return StringUtils.hasText(accessToken) && nowEpochMs < accessTimeoutEpochMs;
        }
    }
}
