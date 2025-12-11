package dao;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import malgnsoft.db.*;
import malgnsoft.util.*;
import malgnsoft.json.JSONException;
import org.json.*;
import java.io.*;

public class ApiLogDao extends DataObject {

	private int logId = 0;
	private String format = "json";

	private HttpServletRequest request;
	private HttpServletResponse response;

	public ApiLogDao() {
		this.table = "TB_API_LOG";
	}

	public ApiLogDao(String format, HttpServletRequest request, HttpServletResponse response) {
		this.table = "TB_API_LOG";
		this.format = format;
		this.request = request;
		this.response = response;
	}

	public void printList(Writer out, JSONObject json) throws Exception {
		printList(out, json, "utf-8", null, "ret_data");
	}
	public void printList(Writer out, JSONObject json, DataSet ds) throws Exception {
		printList(out, json, "utf-8", ds, "ret_data");
	}
	public void printList(Writer out, JSONObject json, String charset) throws Exception {
		printList(out, json, charset, null, "ret_data");
	}
	public void printList(Writer out, JSONObject json, String charset, DataSet ds) throws Exception {
		printList(out, json, charset, ds, "ret_data");
	}

	public void printList(Writer out, JSONObject json, String charset, DataSet ds, String retDataNm) throws Exception {
		try {
			if("xml".equals(format)) {
				response.setContentType("text/xml;charset=" + charset.toLowerCase());
				out.write("<?xml version='1.0' encoding='" + charset.toUpperCase() + "'?>");
				out.write("<result>");
				out.write(XML.toString(json));
				if(null != ds) {
					out.write("<" + retDataNm + ">");
					out.write(XML.toString(new JSONObject("{\"row\":" + ds.serialize() + "}")));
					out.write("</" + retDataNm + ">");
				}
				out.write("</result>");
			} else {
				response.setContentType("application/json;charset=" + charset.toLowerCase());
				if(null != ds) json.put("" + retDataNm + "", ds);
				out.write(json.toString());
			}
		} catch(JSONException je) {
			Malgn.errorLog( "ApiLogDao.printList() : " + je.getMessage(), je);
		} catch(IOException ioe) {
			Malgn.errorLog( "ApiLogDao.printList() : " + ioe.getMessage(), ioe);
		}
	}

	public boolean insertLog(int siteId, String qs) {
		if(null == request || 0 == siteId) return false;
		
		logId = this.getSequence();
		this.item("id", logId);
		this.item("site_id", siteId);
		this.item("method", request.getMethod());
		this.item("request_url", request.getRequestURL().toString());
		this.item("request_uri", request.getRequestURI());
		this.item("request_query", qs);
		this.item("remote_ip", request.getRemoteAddr());
		this.item("remote_host", request.getRemoteHost());
		this.item("remote_port", request.getRemotePort());
		this.item("reg_date", Malgn.time("yyyyMMddHHmmss"));
		
		return this.insert();
	}

	public boolean updateLog(String returnCode) {
		this.item("return_code", returnCode);

		return this.update("id = " + logId);
	}
}