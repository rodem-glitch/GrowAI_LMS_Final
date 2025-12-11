<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.*,java.io.*,dao.*,malgnsoft.db.*,malgnsoft.util.*,malgnsoft.json.*" %><%!

class MySort implements Comparator<File> {
    public int compare(File f1, File f2) {
        if (f1.getName().compareTo(f2.getName()) > 0) { return 1; }
        else if (f1.getName().compareTo(f2.getName()) < 0) { return -1; }
        return 0;
    }
}

%><%

Malgn m = new Malgn(request, response, out);
String ip = m.getRemoteAddr();
if(!ip.startsWith("10.")) return;

Form f = new Form("form1");
try { f.setRequest(request); }
catch(Exception ex) { out.print("Overflow file size. - " + ex.getMessage()); return; }

//if(!m.isPost()) return;

String uid = f.get("uid").replace("..", "");
String mode = f.get("mode");
String folder = f.get("folder").replace("..", "");
String file = f.get("file").replace("..", "");

String dir = "/home/" + uid + "/public_html/html/" + folder;
String pnm = f.get("pnm");

if("files".equals(mode)) {
    //폴더내 파일목록 조회
    DataSet list = new DataSet();
    try {
        if(new File(dir).exists()) {
            File[] files = new File(dir).listFiles();
            Arrays.sort(files, new MySort());
            int max = files.length;
            for(int i = 0; i < max; i++) {
                if(files[i].isFile()) {
                    if(!"".equals(pnm) && files[i].getName().indexOf(pnm) < 0) continue;
                    list.addRow();
                    list.put("id", "" + (i + 1));
                    list.put("name", files[i].getName());
                    list.put("path", files[i].toString());
                    list.put("length", new Long(files[i].length()));
                    list.put("time", new Long(files[i].lastModified()));
                    list.put("pname", files[i].getName().replace(".html", "").replace(".css", ""));
                }
            }
        }
    } catch(NullPointerException npe) {
        m.errorLog(npe.getMessage());
    }
    list.first();
    JSONObject jsonObject = new JSONObject();
    jsonObject.put("files", new JSONArray(list));
    out.print(jsonObject);
/*
out.print(list.serialize());
*/
    return;
}
else if("read".equals(mode)) {

    String filepath = dir + "/" + file;
    File f1 = new File(filepath);

    if(f1.exists() && f1.isFile()) {
        out.print(m.readFile(filepath));
    } else {
        JSONObject json = new JSONObject();
        json.put("error", 1);
        json.put("message", "파일이 존재하지 않습니다.");
        out.print(json.toString());
        out.print("");
    }
    return;
}
else if("readwrite".equals(mode)) {

    String filepath = dir + "/" + file;
    File f1 = new File(filepath);

    if(f1.exists() && f1.isFile()) {
        out.print(m.readFile(filepath));
    } else {
        m.writeFile(filepath, "");
        try { Runtime.getRuntime().exec("chown -R " + uid + ":" + uid + " " + filepath); }
        catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
        catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }
    }
    return;
}
else if("edit".equals(mode)) {
    f.addElement("body", null, "allowscript:'Y', allowhtml:'Y', allowiframe:'Y', allowlink:'Y', allowobject:'Y'");
    String body = f.get("body");
    String filepath = dir + "/" + file;
    File f1 = new File(filepath);

    JSONObject json = new JSONObject();
    if(f1.exists() && f1.isFile()) {

        File backup = new File(f1.getParent() + "/_backup");
        if(!backup.exists()) backup.mkdir();
        f1.renameTo(new File(f1.getParent() + "/_backup/" + f1.getName() + "." + m.time()));

        m.writeFile(filepath, body);
        try { Runtime.getRuntime().exec("chown -R " + uid + ":" + uid + " " + filepath); }
        catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
        catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }
        json.put("error", 0);
        json.put("message", "Success");
    } else {
        json.put("error", 2);
        json.put("message", "파일이 존재하지 않습니다.");
    }
    out.print(json.toString());
    return;
}
else if("write".equals(mode)) {
    f.addElement("body", null, "allowscript:'Y', allowhtml:'Y', allowiframe:'Y', allowlink:'Y', allowobject:'Y'");
    String body = f.get("body");
    String filepath = dir + "/" + file;
    File f1 = new File(filepath);

    JSONObject json = new JSONObject();
    if(!f1.exists()) {
        m.writeFile(filepath, body);
        try { Runtime.getRuntime().exec("chown -R " + uid + ":" + uid + " " + filepath); }
        catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
        catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }
        json.put("error", 0);
        json.put("message", "Success");
    } else {
        json.put("error", 3);
        json.put("message", "이미 파일이 존재합니다.");
    }
    out.print(json.toString());
    return;
}
else if("mkdir".equals(mode)) {
    String body = f.get("body");
    String filepath = dir + "/" + file;
    File f1 = new File(filepath);

    JSONObject json = new JSONObject();
    if(!f1.exists()) {
        f1.mkdirs();
        json.put("error", 0);
        json.put("message", "Success");
    } else {
        json.put("error", 3);
        json.put("message", "이미 폴더가 존재합니다.");
    }
    out.print(json.toString());
    return;
}

%>