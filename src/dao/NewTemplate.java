package dao;

import malgnsoft.db.*;
import malgnsoft.util.*;
import java.util.*;

public class NewTemplate {

	protected Hashtable<String, String> var = new Hashtable<String, String>();
	protected Hashtable<String, DataSet> loop = new Hashtable<String, DataSet>();

	public NewTemplate() {

	}

	public String parseTemplate(String template) {
		if(null == template || "".equals(template)) return "";

		StringBuffer sb = new StringBuffer();
		int start = 0, end = 0, pos = 0;

		while((end = template.indexOf("}}", pos)) != -1) {
			start = template.lastIndexOf("{{", end);

			if(0 > start || pos > start) {
				sb.append(template.substring(pos, end + 2));
				pos = end + 2;
				continue;
			} else {
				sb.append(template.substring(pos, start));
				pos = start;
			}
			
			String str = start > -1 ? template.substring(start + 2, end).trim() : "";

			if('?' == str.charAt(0)) {
				//조건
				String ifName = template.substring(start + 3, end);
				int ifStart = start + ifName.length() + 5;
				int ifEnd = template.indexOf("{{/" + ifName + "}}", pos);

				if(-1 < ifEnd) {
					if(var.containsKey(ifName)) {
						if(-1 < ifName.indexOf(":")) {

						} else {
							String condition = var.get(ifName);
							if(condition.equals("true")) sb.append(this.parseTemplate(template.substring(ifStart, ifEnd)));
						}
					}

					pos = ifEnd + ifName.length() + 5;
				} else {
					sb.append("{{" + str + "}}");
					pos = end + 2;
				}

			} else if('@' == str.charAt(0)) {
				//반복
				String loopName = template.substring(start + 3, end);
				int loopStart = start + loopName.length() + 5;
				int loopEnd = template.indexOf("{{/" + loopName + "}}", pos);

				if(-1 < loopEnd && loop.containsKey(loopName)) {
					String loopStr = template.substring(loopStart, loopEnd);

					DataSet list = loop.get(loopName);
					list.first();
					while(list.next()) {
						this.setVar(loopName, list.getRow());
						sb.append(this.parseTemplate(loopStr));
					}
					if(null == loopName) throw new NullPointerException();
					pos = loopEnd + loopName.length() + 5;
				} else {
					sb.append("{{" + str + "}}");
					pos = end + 2;
				}

			} else {
				//치환
				if(var.containsKey(str)) sb.append(var.get(str));
				else sb.append("{{" + str + "}}");
				pos = end + 2;
			}

		}

		sb.append(template.substring(pos, template.length()));

		return sb.toString();
	}


	public void setVar(String name, String value) {
		if(name == null) return;
		var.put(name, value == null ? "" : value);
	}

	public void setVar(String name, int value) {
		setVar(name, "" + value);
	}

	public void setVar(String name, long value) {
		setVar(name, "" + value);
	}
	
	public void setVar(String name, boolean value) {
		setVar(name, value == true ? "true" : "false");
	}

	public void setVar(Hashtable values) {
		if(values == null) return;
		Enumeration e = values.keys();
		while(e.hasMoreElements()) {
			String key = e.nextElement().toString();
			if(values.get(key) != null) {
				setVar(key, values.get(key).toString());
			}
		}
	}

	public void setVar(DataSet values) {
		if(values != null && values.size() > 0) {
			if(values.getIndex() == -1) values.next();
			this.setVar(values.getRow());
		}
	}

	public void setVar(String name, DataSet values) {
		if(values.getIndex() == -1) values.next();
		this.setVar(name, values.getRow());
	}
	
	public void setVar(String name, Hashtable values) {
		if(name == null || values == null) return;

		int sub = 0;
		Enumeration e = values.keys();
		while(e.hasMoreElements()) {
			String key = null;
			key = e.nextElement().toString();
			if(values.get(key) == null || key.length() == 0) continue;
			if(key.charAt(0) != '.') {
				setVar(name + "." + key, values.get(key).toString());
			} else {
				setLoop(key.substring(1), (DataSet)values.get(key));
			}
			/*
			if(values.get(key) instanceof DataSet) {
				setLoop(key.substring(1), (DataSet)values.get(key));
			} else {
				setVar(name + "." + key, values.get(key).toString());
			}
			*/
		}
	}

	public void setLoop(String name, DataSet rs) {
		if(rs != null && rs.size() > 0) {
			rs.first();
			loop.put(name, rs);
			setVar(name, true);
		} else {
			loop.put(name, new DataSet());
			setVar(name, false);
		}
	}

}