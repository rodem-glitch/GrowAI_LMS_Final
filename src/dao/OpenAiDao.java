package dao;

import com.fasterxml.jackson.core.io.JsonStringEncoder;
import malgnsoft.db.*;
import malgnsoft.json.*;
import malgnsoft.util.*;

import java.io.Writer;

/**
 * OpenAiDao 클래스
 * openai의 모델을 사용해서 api 호출을 하는 클래스
 * 현재 버전에서는 gpt-3.5-turbo#chat에 맞춰져있다.
 *
 * @author 김인겸
 * @version 1.0
 */
public class OpenAiDao extends DataObject {

    /** gpt 3.5 모델 사용 */
    private final String REQUEST_MODEL = "gpt-3.5-turbo";
    /**
     * 사용하는 tp수치 0.3
     * 대답의 랜덤성 설정 정확한 대답을 원할때 (0-0.3)
     * 창의적인 대답을 원할때 (0.5-1)
     */
    private final double REQUEST_TEMPERATURE = 0.3;
    /** 답변 최대 토큰 수 1000 */
    private final int RESPONSE_MAX_TOKEN = 1000;
    /**
     * 요청 최대 토큰 수 4096
     * 현재 버전에서 요청 최대 토큰 수는 사용하지 않음
     * */
    private final int REQUEST_MAX_TOKEN = 4096;

    /** api 요청 baseURL */
    private final String baseUrl = "https://api.openai.com/v1/";

    /**
     * 사용 모델에 대한 토큰당 달러 가격
     * $0.002 per 1K tokens <a href="https://openai.com/pricing#chat">참고</a>
     * */
    public final String[] costList = { "gpt-3.5-turbo=>0.000002" };

    /** 사이트별 질의 데이터 저장을 위한 내부 변수 */
    private int siteId = 0;
    private String secretKey = "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";
    private Writer out = null;
    private Json data = null;

    private String endUserId = null;

    private Http http;

    /**
     * @see Http
     * @see Http#disableSSLVerification()
     * @see #setAuth()
     * @see #setData()
     * @param siteId dao를 호출하는 사이트를 지정하고 내부 변수 siteId에 저장한다
     */
    public OpenAiDao(int siteId) {
        this.table = "TB_OPENAI";
        this.PK = "id";
        this.useSeq = "N";
        this.siteId = siteId;
        this.http = new Http();
        this.http.disableSSLVerification();
        this.setAuth();
        this.setData();
    }

    /**
     * @see #OpenAiDao(int)
     * @param secretKey 요청 secretKey가 siteId 별로 다를 경우 사용하는 override 형태
     */
    public OpenAiDao(int siteId, String secretKey) {
        this(siteId);
        this.setAuth(secretKey);
    }

    /**
     * @param out http rs를 저장할 작성 객체 정보
     */
    public void setDebug(Writer out) {
        this.out = out;
        this.http.setDebug(out);
    }

    /**
     * @see #setAuth(String)
     */
    public void setAuth() { setAuth(""); }

    /**
     * chat completion에 전달할 user 값을 설정
     * @param userId 회원번호
     * @param lessonId 강의번호
     */
    public void setEndUserId(int userId, int lessonId) {
        this.endUserId = userId + "-" + lessonId;
    }

    /**
     * http header에 secretKey를 지정한다
     * @param secretKey header에 지정할 값
     */
    public void setAuth(String secretKey) {
        if(!"".equals(secretKey)) this.secretKey = secretKey;
        this.http.setHeader("Authorization", "Bearer " + this.secretKey);
    }

    /**
     * 내부 변수 data(Json형)을 초기화 하고 내부 고정 정보를 저장한다
     */
    public void setData() {
        this.data = new Json();
        this.data.put("model", this.REQUEST_MODEL);
        this.data.put("temperature", this.REQUEST_TEMPERATURE);
        this.data.put("max_tokens", this.RESPONSE_MAX_TOKEN);
    }

    /**
     * openai를 통해서 사용 가능한 모델 정보를 가져온다
     * @return 응답받은 모델 정보
     */
    public Json getModels() {
        Json retJson;
        try{
            http.setUrl(baseUrl + "models");
            http.setHeader("OpenAI-Organization", "org-pF7WPcQs2r05aeErlfUNepDu");

            retJson = new Json(http.send("GET"));

            int retCode = http.responseCode;
            if(retCode != 200) throw new Exception("http responseCode : " + retCode);

        } catch (Exception e) {
            Malgn.errorLog("OpenAiDao.getModels() : " + e.getMessage());
            Json j = new Json();
            j.put("code", -1);
            j.put("message", "사용가능 모델을 불러오는 중 오류가 발생했습니다.");
            retJson = j;
        }

        return retJson;
    }

    /**
     * DB에 요청 메시지, 응답 메시지, 요청/응답에 사용된 토큰 수를 저장한다.
     * @param result openAI를 통해 전달 하고 전달 받은 정보가 저장된 객체 (@NotNull)
     * @return 등록 후 auto_increment를 통해서 생성된 아이디를 전달, 실패 시 -1
     */
    public int add(DataSet result) {
        result.first();
        if(this.siteId == 0
                || !result.next()
                || result.i("user_id") == 0
                || result.i("module_id") == 0
                || "".equals(result.s("data"))
        ) {
            return -1;
        }

        Json data = new Json(result.s("data"));

        this.item("parent_id", result.i("parent_id"));
        this.item("site_id", this.siteId);
        this.item("user_id", result.i("user_id"));
        this.item("module", !"".equals(result.s("module")) ? result.s("module") : "lesson");
        this.item("module_id", result.i("module_id"));
        this.item("request_msg", result.s("content"));
        this.item("response_msg", data.getString("//choices/0/message/content"));
        this.item("prompt_tokens", data.getInt("//usage/prompt_tokens"));
        this.item("completion_tokens", data.getInt("//usage/completion_tokens"));
        this.item("total_tokens", data.getInt("//usage/total_tokens"));
        this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
        this.item("status", 1);
        this.item("model", this.REQUEST_MODEL);
        this.item("temperature", this.REQUEST_TEMPERATURE);
        this.item("response_max_tokens", this.RESPONSE_MAX_TOKEN);
        this.item("reg_year", Malgn.time("yyyy"));
        this.item("reg_month", Malgn.time("MM"));
        this.item("reg_day", Malgn.time("dd"));

        return this.insert(true);
    }

    /**
     * <a href="https://platform.openai.com/docs/api-reference/chat">chat api</a>를 통해 메시지를 전달 하고 답변을 받는다
     * @param message 이용자의 질문 메시지
     * @param prevInfo 이용자의 이전 질문 정보
     * @return 응답 메시지, 요청/응답에 사용된 토큰 수 정보 혹은 오류 메시지
     */
    public Json chat(String message, DataSet prevInfo) {
        Json retJson;
        try {
            if ("".equals(message)) throw new Exception("Empty input");

            JSONArray ja = new JSONArray();

            //추후 추가
            //관리자가 설정한 모듈의 gpt 기본 설정 값
            //이전 요청 메시지 데이터 추출 // 통합 X
            prevInfo.first();
            if (prevInfo.next()) {
                if (!"".equals(prevInfo.s("system_msg"))) {
                    ja.put(new JSONObject("{\"role\": \"system\", \"content\":\"" + this.messageEscaping(prevInfo.s("system_msg")) + "\"}"));
                }
                ja.put(new JSONObject("{\"role\": \"user\", \"content\":\"" + this.messageEscaping(prevInfo.s("request_msg")) + "\"}"));
                ja.put(new JSONObject("{\"role\": \"assistant\", \"content\":\"" + this.messageEscaping(prevInfo.s("response_msg")) + "\"}"));
            }

            ja.put(new JSONObject("{\"role\": \"user\", \"content\":\"" + this.messageEscaping(message) + "\"}"));
            data.put("messages", ja);
            if (this.endUserId != null) data.put("user", this.endUserId);

            http.setUrl(baseUrl + "chat/completions");
            http.setData(data.toString());

            retJson = new Json(http.send("POST"));

            int retCode = http.responseCode;
            if (retCode != 200) throw new Exception("http responseCode : " + retCode + ", retJson : " + retJson);

            //결과 확인 후 다음 질의 시 최대 토큰 수 초과 예상(+-250)되면 가장 오래된 질의 문항 삭제

        } catch (JSONException je) {
            Malgn.errorLog("OpenAiDao.chat(message) : " + je.getMessage(), je);
            Json j = new Json();
            j.put("code", -1);
            j.put("message", "메시지를 전달하는 중 오류가 발생했습니다.");
            retJson = j;
        } catch (Exception e) {
            Malgn.errorLog("OpenAiDao.chat(message) : " + e.getMessage(), e);
            Json j = new Json();
            j.put("code", -1);
            j.put("message", "메시지를 전달하는 중 오류가 발생했습니다.");
            retJson = j;
        }

        return retJson;
    }

    /**
     * 전달받은 메시지를 JSONObject내의 콘텐츠로 사용 시 발생할 수 있는 parsing 에러를 해소하기 위해 사용
     * @param message 에러를 escape할 메시지 문자열
     * @return 전달받은 message를 JSONObject로 변환 시 오류가 발생하지 않도록 처리한 문자열
     */
    private String messageEscaping(String message) {
        JsonStringEncoder encoder = JsonStringEncoder.getInstance();
        return Malgn.htt(new String(encoder.quoteAsString(message)));
    }
}
