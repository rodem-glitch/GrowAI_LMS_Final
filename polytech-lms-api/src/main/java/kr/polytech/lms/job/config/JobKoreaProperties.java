package kr.polytech.lms.job.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.LinkedHashMap;
import java.util.Map;

@ConfigurationProperties(prefix = "jobkorea")
public class JobKoreaProperties {
    // 왜: 잡코리아 API는 파라미터/엔드포인트가 프로젝트마다 달라져서 설정으로 제어합니다.

    private boolean enabled = true;
    private String apiUrl;
    private String apiKey;
    private String oemCode;
    private String apiKeyParam = "api";
    private String oemCodeParam = "Oem_Code";
    private String pageParam = "Page";
    private String displayParam = "PageSize";
    private String regionParam = "AreaCode";
    private String occupationParam = "Job_Ctgr_Code";
    private Map<String, String> params = new LinkedHashMap<>();
    private Cache cache = new Cache();

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public String getApiUrl() {
        return apiUrl;
    }

    public void setApiUrl(String apiUrl) {
        this.apiUrl = apiUrl;
    }

    public String getApiKey() {
        return apiKey;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }

    public String getOemCode() {
        return oemCode;
    }

    public void setOemCode(String oemCode) {
        this.oemCode = oemCode;
    }

    public String getApiKeyParam() {
        return apiKeyParam;
    }

    public void setApiKeyParam(String apiKeyParam) {
        this.apiKeyParam = apiKeyParam;
    }

    public String getOemCodeParam() {
        return oemCodeParam;
    }

    public void setOemCodeParam(String oemCodeParam) {
        this.oemCodeParam = oemCodeParam;
    }

    public String getPageParam() {
        return pageParam;
    }

    public void setPageParam(String pageParam) {
        this.pageParam = pageParam;
    }

    public String getDisplayParam() {
        return displayParam;
    }

    public void setDisplayParam(String displayParam) {
        this.displayParam = displayParam;
    }

    public String getRegionParam() {
        return regionParam;
    }

    public void setRegionParam(String regionParam) {
        this.regionParam = regionParam;
    }

    public String getOccupationParam() {
        return occupationParam;
    }

    public void setOccupationParam(String occupationParam) {
        this.occupationParam = occupationParam;
    }

    public Map<String, String> getParams() {
        return params;
    }

    public void setParams(Map<String, String> params) {
        this.params = params;
    }

    public Cache getCache() {
        return cache;
    }

    public void setCache(Cache cache) {
        this.cache = cache;
    }

    public static class Cache {
        // 왜: 잡코리아 캐시도 호출량을 줄이기 위해 별도 설정으로 관리합니다.
        private boolean enabled = true;
        private long ttlMinutes = 1440;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public long getTtlMinutes() {
            return ttlMinutes;
        }

        public void setTtlMinutes(long ttlMinutes) {
            this.ttlMinutes = ttlMinutes;
        }
    }
}
