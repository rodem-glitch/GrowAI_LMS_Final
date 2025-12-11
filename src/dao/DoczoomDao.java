package dao;

import com.fasterxml.jackson.databind.*;
import com.fasterxml.jackson.databind.node.*;

import java.io.*;
import java.net.URL;
import java.net.HttpURLConnection;
import java.net.URLEncoder;

import java.util.*;

import malgnsoft.db.*;
import malgnsoft.util.*;

public class DoczoomDao {

    //API주소 및 키값을 실제 값으로 변경하십시오.
    String apiUrlBase = "https://cms.malgnlms.com/DocZoomManagementServer/DocZoomManager";
    
	private Writer out = null;
	private boolean debug = false;
	public String errMsg = "";
    
	public DoczoomDao() {

	}

	public void setDebug(Writer out) {
		this.debug = true;
		this.out = out;
	}

	protected void setError(String msg) {
		this.errMsg = msg;
		try {
			if(debug == true) {
				if(null != out) out.write("<hr>" + msg + "<hr>\n");
				else Malgn.errorLog(msg);
			}
		}
		catch(IOException ioe) { Malgn.errorLog( "IOException : DoczoomDao.setError() : " + ioe.getMessage(), ioe); }
		catch(Exception ex) { Malgn.errorLog( "Exception : DoczoomDao.setError() : " + ex.getMessage(), ex); }
	}
	private String getApiKey(String mode){
        DataSet info = Config.getDataSet("//config/privateKey/doczoom");
        info.next();
        return info.s(mode);
    }

    //해당 조건에 부합하는 컨텐츠 개수를 가져옵니다. 각 파라미터에 null값을 지정하면 해당 조건은 사용되지 않습니다.
    public int getContentCount(String userID, String title, String tag, String categoryID){

        String apiUrl = apiUrlBase + "/API/DocZoomManagerAPI.asmx/GetDocZoomCountWithFilters";

        HashMap<String, Object> params = new HashMap<String, Object>();
        params.put("key", getApiKey("read"));
        params.put("userID", userID);
        params.put("dzTitle", title);
        params.put("dzTag", tag);
        params.put("dzCategoryID", categoryID);

        String result = callWebServiceToJson(apiUrl, params);
        if (result == null) return 0;
		setError(result);

        ObjectMapper mapper = new ObjectMapper();
        try{
            //다음과 같은 형태로 JSON이 반환됩니다.
            //{"d":{"__type":"DocZoomManager.Web.API.Entity.IntegerQueryResult","Value":25,"Result":true,"ResultMessage":"","ResultCode":0}}
            JsonNode node = mapper.readTree(result);
            JsonNode dataNode = node.get("d");

            if (dataNode == null) {
				this.errMsg = "Unsupported data format: " + result;
                return 0;
            }

            return dataNode.get("Value").asInt(-1);

        } catch (IOException ioe){
            this.errMsg = ioe.getMessage();
            return 0;
        }
    }


    //해당 조건에 부합하는 컨텐츠 정보를 페이징하여 가져옵니다. 각 파라미터에 null값을 지정하면 해당 조건은 사용되지 않습니다.
    public DataSet getPaginatedContentInfoListWithFilters(int pageSize, int pageNumber, int sortBy, int sortOrder,
                                                                String userID, String title, String tag, String categoryID){

        String apiUrl = apiUrlBase + "/API/DocZoomManagerAPI.asmx/GetPaginatedDocZoomInfoListWithFilters";

        HashMap<String, Object> params = new HashMap<String, Object>();
        params.put("key", getApiKey("read"));
        params.put("pageSize", pageSize);
        params.put("pageNumber", pageNumber);
        params.put("sortBy", sortBy);
        params.put("sortOrder", sortOrder);

        params.put("userID", userID);
        params.put("dzTitle", title   );
        params.put("dzTag", tag);
        params.put("dzCategoryID", categoryID);

		DataSet ret = new DataSet();

		String result = callWebServiceToJson(apiUrl, params);
		if (result == null) return ret;
		setError(result);

        //다음과 같은 형태로 JSON이 반환됩니다.
        //{"d":{"__type":"DocZoomManager.Web.API.Entity.ContentListQueryResult","ContentInfos":[{"ContentID":"test_rzrjvzgezufcqtvj","RegistrationDate":"\/Date(1510563786593)\/","LastModifiedDate":"\/Date(1510564007360)\/","ContentSize":46979285,"Title":"360 비디오 샘플","Tag":"VR, 360 Video","Description":" ","Expired":false,"IsDeleted":false,"SharingType":0,"UserID":"test","ViewCount":14,"CategoryID":null,"ContentType":1,"ContentSubType":10,"ContentViewerType":0,"Duration":0,"ContentData1":"mp4","ContentData2":null,"ThumbnailImageUrl":"http://localhost/DzMgrServerTest_WebContentStorage3/test/Thumbs/test_rzrjvzgezufcqtvj.jpg"}]}}
        Json j = new Json(result);
        ret = j.getDataSet("//d/DocZoomInfos");

        return ret;
    }



    //지정한 contentID에 대한 컨텐트 정보를 가져옵니다.
    public DataSet getContentInfo(String contentID){

        String apiUrl = apiUrlBase + "/API/DocZoomManagerAPI.asmx/GetDocZoomInfo";

        HashMap<String, Object> params = new HashMap<String, Object>();
        params.put("key", getApiKey("read"));
        params.put("doczoomID", contentID);

		DataSet ret = new DataSet();

		String result = callWebServiceToJson(apiUrl, params);
        if (result == null) return ret;
		setError(result);

        //다음과 같은 형태로 JSON이 반환됩니다.
        //{"d":{"__type":"DocZoomManager.Web.API.Entity.ContentQueryResult","Result":true,"ResultMessage":"","ResultCode":0,"ContentInfo": {"ContentID":"test_rzrjvzgezufcqtvj","RegistrationDate":"/Date(1510563786593)/","LastModifiedDate":"/Date(1523601667067)/","ContentSize":46979285,"Title":"360 비디오 샘플","Tag":"VR, 360 Video","Description":" ","Expired":false,"IsDeleted":false,"SharingType":1,"UserID":"test","ViewCount":14,"CategoryID":null,"ContentType":1,"ContentSubType":10,"ContentViewerType":0,"Duration":0,"ContentData1":"mp4","ContentData2":null,"ThumbnailImageUrl":"http://localhost/DzMgrServerTest_WebContentStorage3/test/Thumbs/test_rzrjvzgezufcqtvj.jpg"}}}
        Json j = new Json(result);
        if(this.debug) j.setDebug(this.out);
        ret = j.getDataSet("//d/DocZoomInfo");

		return ret;
    }



    //지정한 컨텐트의 정보를 업데이트합니다. null로 지정한 값들은 변경되지 않습니다.
    public boolean updateContentInfo(String contentID, String newTitle, String newDescription, String newTag, Boolean expired, Integer newSharingType){

        String apiUrl = apiUrlBase + "/API/DocZoomManagerAPI.asmx/UpdateDocZoomInfo";

        HashMap<String, Object> params = new HashMap<String, Object>();
        params.put("key", getApiKey("update"));
        params.put("contentID", contentID);
        params.put("newTitle", newTitle);
        params.put("newDescription", newDescription);
        params.put("newTag", newTag);
        params.put("expired", expired);
        params.put("newSharingType", newSharingType);

        String result = callWebServiceToJson(apiUrl, params);
        if (result == null) return false;
		setError(result);

        ObjectMapper mapper = new ObjectMapper();
        try {
            //다음과 같은 형태로 JSON이 반환됩니다.
            //{"d":{"__type":"DocZoomManager.Web.API.Entity.BooleanResult","Result":true,"ResultMessage":"","ResultCode":0}}
            JsonNode node = mapper.readTree(result);
            JsonNode dataNode = node.get("d");
            if (dataNode == null) {
				this.errMsg = "Unsupported data format: " + result;
				return false;
			}
            return true;
        } catch (IOException ioe){
			setError(ioe.getMessage());
            return false;
        }

    }




    //공개가 아닌 컨텐트 열람을 위한 SharedSession 데이터를 추가합니다. 컨텐트 뷰어 URL에 추가할 SessionID가 반환됩니다.
    //timeout의 단위는 초 입니다.
    //annotationMode는 컨텐트 타입이 DocZoom일 때만 의미를 가지며 나머지 경우에는 null 또는 빈 문자열을 지정하십시오.
    //extrData는 API 확장을 위한 슬롯으로 특별한 경우가 아닌 이상 null을 지정하십시오.
    //referrerDomain을 지정하면 컨텐츠 뷰어를 새로 고침할 경우에 referrerDomain 값이 비어있다고 메시지가 뜨기 때문에 필요한 경우에만 지정하십시오.
    public String addContentViewerLoginSharedSessionData(String userID, String contentID, int timeout){

        String apiUrl = apiUrlBase + "/API/DocZoomManagerAPI.asmx/AddDzViewerLoginSharedSessionData";

        HashMap<String, Object> params = new HashMap<String, Object>();
        params.put("key", getApiKey("manage"));
        params.put("appID", "malgnlms");
        params.put("userID", userID);
        params.put("doczoomID", contentID);
        params.put("timeout", String.valueOf(timeout));
        params.put("referrerDomain", null);
        params.put("dzAnnotationMode", 0);
        params.put("extraData", null);

        String result = callWebServiceToJson(apiUrl, params);
        if (result == null) return null;
		setError(result);

        //다음과 같은 형태로 JSON이 반환됩니다.
        //{"d":{"__type":"DocZoomManager.Web.API.Entity.StringQueryResult", "Value":"12345","Result":true,"ResultMessage":"","ResultCode":0}}
        Json j = new Json(result);
        if(this.debug) j.setDebug(this.out);
        String value = j.getString("//d/Value");

        if (value == null || "".equals(value)) {
            this.errMsg = "Unsupported data format: " + result;
            return null;
        }

        return value;
    }


    //이전에 추가되었던 SharedSession 데이터를 삭제합니다. appID와 userID는 addContentViewerLoginSharedSessionData 호출시 지정한 값을 사용하십시오.
    public boolean deleteSharedSessionDataByUserID(String appID, String userID){

        String apiUrl = apiUrlBase + "/API/DocZoomManagerAPI.asmx/DeleteSharedSessionDataByUserID";

        HashMap<String, Object> params = new HashMap<String, Object>();
        params.put("key", getApiKey("manage"));
        params.put("appID", appID);
        params.put("userID", userID);

        String result = callWebServiceToJson(apiUrl, params);
        if (result == null) return false;
		setError(result);

        ObjectMapper mapper = new ObjectMapper();
        try{
            //다음과 같은 형태로 JSON이 반환됩니다.
            //{"d":{"__type":"DocZoomManager.Web.API.Entity.BooleanResult","Result":true,"ResultMessage":"","ResultCode":0}}
            JsonNode node = mapper.readTree(result);
            JsonNode dataNode = node.get("d");
            if (dataNode == null) {
				setError("Unsupported data format: " + result);
				return false;
			}
            return true;
        } catch (IOException ioe) {
			setError(ioe.getMessage());
            return false;
        }

    }

    //웹 서비스 호출 결과를 JSON 형식으로 가져옵니다. 요청 파라미터와 컨텐트 형식 모두를 JSON 타입으로 지정해야 웹 서비스의 Response가 JSON으로 반환됩니다.
    public String callWebServiceToJson(String api_uri, HashMap<String, Object> params) {

        String jsonData = "{";

        for (Object k : params.keySet())
        {
            jsonData += String.format("'%1$s' : '%2$s', ", k, (params.get(k) != null)? params.get(k).toString() : "");
        }

        jsonData = jsonData.substring(0, jsonData.length() - 2) + "}";

        String result = executeHttpPostRequest(api_uri, jsonData, "application/json; charset=utf-8","application/json");

        if (result.startsWith("{") && result.endsWith(("}"))){
            return result;
        } else {
			setError(result);
            return null;
        }

    }



    public String executeHttpPostRequest(String api_uri, String data, String contentType, String accept) {

        String result = "";

        try {
            //SSL을 사용하는 경우에는 HttpsURLConnection 클래스를 사용하십시오.
            //유효하지 않은 인증서 경고를 무시하려면 https://gist.github.com/aembleton/889392 과 같이 하시기 바랍니다.

            URL url = new URL(api_uri);
            HttpURLConnection uc = (HttpURLConnection)url.openConnection();
            uc.setDoOutput(true);
            uc.setDoInput(true);
            uc.setUseCaches(false);
            uc.setRequestMethod("POST");
            uc.setRequestProperty("Content-type", contentType);
            if(accept != null && !accept.isEmpty()) uc.setRequestProperty("Accept", accept);


            PrintWriter out = new PrintWriter(uc.getOutputStream());
            out.print(data);
            out.close();

            String line = "";
            StringBuffer inStrBuffer = new StringBuffer();

            BufferedReader reader = null;
            if(uc.getResponseCode() == 200) {
                reader = new BufferedReader(new InputStreamReader(uc.getInputStream(), "UTF-8"), 30960);    //버퍼가 부족하면 늘리시기 바랍니다.
            } else {
                reader = new BufferedReader(new InputStreamReader(uc.getErrorStream(), "UTF-8"), 30960);
            }

            while((line = reader.readLine()) != null) {
                inStrBuffer.append(line);
            }
            reader.close();

            result = inStrBuffer.toString();

            return result;

        } catch(IOException ioe) {
            Malgn.errorLog("IOException : DoczoomDao.executeHttpPostRequest() : " + ioe.getMessage(), ioe);

            return ioe.getMessage();
        } catch(Exception e) {
            Malgn.errorLog("Exception : DoczoomDao.executeHttpPostRequest() : " + e.getMessage(), e);

            return e.getMessage();
        }

    }


}