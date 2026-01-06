<%@ page contentType="application/json; charset=utf-8" %><%@ page import="java.net.*, java.io.*, java.util.*, java.util.regex.*" %><%@ page import="org.json.*" %><%

// ============================================================
// YouTube Shorts API - src_gov 알고리즘 포팅
// ============================================================
// src_gov의 YouTubeService.java + YoutubeShortsInspector.java 로직을 JSP로 변환
// 채널 ID로 Shorts 영상 목록을 조회하여 JSON으로 반환
// ============================================================

// YouTube API 설정 (src_gov globals.properties와 동일)
String API_KEY = "AIzaSyCgimgnzkcqt2n51ct2h6UYKb0-r1huEzo";
String DEFAULT_CHANNEL_ID = "UCDlUa248Pg7_e4V-vwT5V8A";

// 파라미터
String channelId = request.getParameter("channelId");
if (channelId == null || channelId.trim().isEmpty()) {
    channelId = DEFAULT_CHANNEL_ID;
}

int maxResults = 12; // 최대 조회 수
String maxResultsParam = request.getParameter("maxResults");
if (maxResultsParam != null && !maxResultsParam.isEmpty()) {
    try { maxResults = Integer.parseInt(maxResultsParam); } catch (Exception e) {}
}

// 디버그 모드
boolean debugMode = "true".equals(request.getParameter("debug"));

JSONObject result = new JSONObject();
JSONArray shortsArray = new JSONArray();
JSONObject debugInfo = new JSONObject();

try {
    // 1. 채널의 uploads 플레이리스트 ID 조회
    String uploadsPlaylistId = getUploadsPlaylistId(channelId, API_KEY);
    if (debugMode) {
        debugInfo.put("uploadsPlaylistId", uploadsPlaylistId);
    }
    
    if (uploadsPlaylistId != null) {
        // 2. 플레이리스트에서 영상 ID 목록 조회 (최대 250개까지 조회하여 Shorts 확률 높임)
        List<String> videoIds = getPlaylistVideoIds(uploadsPlaylistId, API_KEY, 250);
        if (debugMode) {
            debugInfo.put("videoIdsCount", videoIds.size());
            debugInfo.put("videoIdsSample", videoIds.size() > 3 ? videoIds.subList(0, 3) : videoIds);
        }
        
        // 3. 영상 메타데이터 조회 및 Shorts 판별
        if (!videoIds.isEmpty()) {
            List<JSONObject> videos = getVideosMetadata(videoIds, API_KEY);
            if (debugMode) {
                debugInfo.put("videosMetadataCount", videos.size());
                // 첫 영상의 길이 정보
                if (!videos.isEmpty()) {
                    JSONObject firstVideo = videos.get(0);
                    JSONObject sampleVideo = new JSONObject();
                    sampleVideo.put("title", firstVideo.optString("title", ""));
                    sampleVideo.put("durationSeconds", firstVideo.optInt("durationSeconds", 0));
                    debugInfo.put("firstVideoSample", sampleVideo);
                }
            }
            
            // Shorts 후보 목록 생성 (정렬을 위해 모두 수집)
            List<JSONObject> shortsList = new ArrayList<>();
            
            for (JSONObject video : videos) {
                int durationSeconds = video.optInt("durationSeconds", 0);
                String title = video.optString("title", "");
                String videoId = video.optString("id", "");
                String publishedAt = video.optString("publishedAt", "");
                
                // Shorts 판별 (src_gov YoutubeShortsInspector 로직)
                if (durationSeconds <= 60 && durationSeconds > 0) {
                    int score = 0;
                    
                    // 60초 이하면 +2점
                    score += 2;
                    
                    // 제목에 #shorts 포함시 +4점
                    String titleLower = title.toLowerCase();
                    if (titleLower.contains("#shorts") || titleLower.contains("shorts")) {
                        score += 4;
                    }
                    
                    // score >= 2 이면 Shorts로 판정 (60초 이하는 기본적으로 포함)
                    if (score >= 2) {
                        JSONObject shortVideo = new JSONObject();
                        shortVideo.put("id", videoId);
                        shortVideo.put("title", title);
                        shortVideo.put("thumbnailUrl", video.optString("thumbnailUrl", ""));
                        shortVideo.put("durationSeconds", durationSeconds);
                        shortVideo.put("viewCount", video.optString("viewCount", "0"));
                        shortVideo.put("shortsUrl", "https://youtube.com/shorts/" + videoId);
                        shortVideo.put("publishedAt", publishedAt);
                        shortsList.add(shortVideo);
                    }
                }
            }
            
            // 최신순 정렬 (publishedAt 기준 내림차순)
            Collections.sort(shortsList, new Comparator<JSONObject>() {
                @Override
                public int compare(JSONObject a, JSONObject b) {
                    String dateA = a.optString("publishedAt", "");
                    String dateB = b.optString("publishedAt", "");
                    return dateB.compareTo(dateA); // 내림차순 (최신순)
                }
            });
            
            // maxResults 만큼만 결과에 추가
            for (int idx = 0; idx < Math.min(shortsList.size(), maxResults); idx++) {
                shortsArray.put(shortsList.get(idx));
            }
        }
    }
    
    result.put("success", true);
    result.put("channelId", channelId);
    result.put("count", shortsArray.length());
    result.put("shorts", shortsArray);
    if (debugMode) {
        result.put("debug", debugInfo);
    }
    
} catch (Exception e) {
    result.put("success", false);
    result.put("error", e.getMessage());
    if (debugMode) {
        StringWriter sw = new StringWriter();
        e.printStackTrace(new PrintWriter(sw));
        result.put("stackTrace", sw.toString());
    }
}

out.print(result.toString());

%><%!
// 채널의 uploads 플레이리스트 ID 조회
private String getUploadsPlaylistId(String channelId, String apiKey) throws Exception {
    String url = "https://www.googleapis.com/youtube/v3/channels"
        + "?part=contentDetails"
        + "&id=" + URLEncoder.encode(channelId, "UTF-8")
        + "&key=" + apiKey;
    
    String response = httpGet(url);
    JSONObject json = new JSONObject(response);
    
    if (json.has("items") && json.getJSONArray("items").length() > 0) {
        return json.getJSONArray("items")
            .getJSONObject(0)
            .getJSONObject("contentDetails")
            .getJSONObject("relatedPlaylists")
            .getString("uploads");
    }
    return null;
}

// 플레이리스트에서 영상 ID 목록 조회
private List<String> getPlaylistVideoIds(String playlistId, String apiKey, int maxItems) throws Exception {
    List<String> ids = new ArrayList<>();
    String pageToken = null;
    
    while (ids.size() < maxItems) {
        String url = "https://www.googleapis.com/youtube/v3/playlistItems"
            + "?part=contentDetails"
            + "&playlistId=" + URLEncoder.encode(playlistId, "UTF-8")
            + "&maxResults=50"
            + "&key=" + apiKey;
        
        if (pageToken != null) {
            url += "&pageToken=" + pageToken;
        }
        
        String response = httpGet(url);
        JSONObject json = new JSONObject(response);
        
        if (json.has("items")) {
            JSONArray items = json.getJSONArray("items");
            for (int i = 0; i < items.length() && ids.size() < maxItems; i++) {
                JSONObject item = items.getJSONObject(i);
                if (item.has("contentDetails")) {
                    ids.add(item.getJSONObject("contentDetails").getString("videoId"));
                }
            }
        }
        
        if (json.has("nextPageToken")) {
            pageToken = json.getString("nextPageToken");
        } else {
            break;
        }
    }
    
    return ids;
}

// 영상 메타데이터 조회
private List<JSONObject> getVideosMetadata(List<String> videoIds, String apiKey) throws Exception {
    List<JSONObject> videos = new ArrayList<>();
    
    // 50개씩 청크 처리
    for (int i = 0; i < videoIds.size(); i += 50) {
        List<String> chunk = videoIds.subList(i, Math.min(i + 50, videoIds.size()));
        String idParam = String.join(",", chunk);
        
        String url = "https://www.googleapis.com/youtube/v3/videos"
            + "?part=snippet,contentDetails,statistics"
            + "&id=" + URLEncoder.encode(idParam, "UTF-8")
            + "&maxResults=50"
            + "&key=" + apiKey;
        
        String response = httpGet(url);
        JSONObject json = new JSONObject(response);
        
        if (json.has("items")) {
            JSONArray items = json.getJSONArray("items");
            for (int j = 0; j < items.length(); j++) {
                JSONObject item = items.getJSONObject(j);
                JSONObject video = new JSONObject();
                
                video.put("id", item.getString("id"));
                
                // snippet
                JSONObject snippet = item.optJSONObject("snippet");
                if (snippet != null) {
                    video.put("title", snippet.optString("title", ""));
                    video.put("publishedAt", snippet.optString("publishedAt", "")); // 업로드 날짜
                    
                    // 썸네일
                    JSONObject thumbnails = snippet.optJSONObject("thumbnails");
                    if (thumbnails != null) {
                        if (thumbnails.has("high")) {
                            video.put("thumbnailUrl", thumbnails.getJSONObject("high").optString("url", ""));
                        } else if (thumbnails.has("medium")) {
                            video.put("thumbnailUrl", thumbnails.getJSONObject("medium").optString("url", ""));
                        } else if (thumbnails.has("default")) {
                            video.put("thumbnailUrl", thumbnails.getJSONObject("default").optString("url", ""));
                        }
                    }
                }
                
                // contentDetails - duration
                JSONObject contentDetails = item.optJSONObject("contentDetails");
                if (contentDetails != null) {
                    String durationIso = contentDetails.optString("duration", "");
                    video.put("durationSeconds", iso8601ToSeconds(durationIso));
                }
                
                // statistics
                JSONObject statistics = item.optJSONObject("statistics");
                if (statistics != null) {
                    video.put("viewCount", statistics.optString("viewCount", "0"));
                }
                
                videos.add(video);
            }
        }
    }
    
    return videos;
}

// ISO8601 duration을 초로 변환 (PT#H#M#S)
private int iso8601ToSeconds(String duration) {
    if (duration == null || duration.isEmpty()) return 0;
    
    Pattern pattern = Pattern.compile("PT(?:(\\d+)H)?(?:(\\d+)M)?(?:(\\d+)S)?");
    Matcher matcher = pattern.matcher(duration);
    
    if (matcher.matches()) {
        int hours = matcher.group(1) != null ? Integer.parseInt(matcher.group(1)) : 0;
        int minutes = matcher.group(2) != null ? Integer.parseInt(matcher.group(2)) : 0;
        int seconds = matcher.group(3) != null ? Integer.parseInt(matcher.group(3)) : 0;
        return hours * 3600 + minutes * 60 + seconds;
    }
    return 0;
}

// HTTP GET 요청
private String httpGet(String urlString) throws Exception {
    URL url = new URL(urlString);
    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
    conn.setRequestMethod("GET");
    conn.setConnectTimeout(10000);
    conn.setReadTimeout(15000);
    conn.setRequestProperty("Accept", "application/json");
    
    int responseCode = conn.getResponseCode();
    
    BufferedReader reader;
    if (responseCode >= 200 && responseCode < 300) {
        reader = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));
    } else {
        reader = new BufferedReader(new InputStreamReader(conn.getErrorStream(), "UTF-8"));
    }
    
    StringBuilder sb = new StringBuilder();
    String line;
    while ((line = reader.readLine()) != null) {
        sb.append(line);
    }
    reader.close();
    
    if (responseCode >= 400) {
        throw new Exception("HTTP " + responseCode + ": " + sb.toString());
    }
    
    return sb.toString();
}
%>
