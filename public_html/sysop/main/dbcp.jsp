<%@ page contentType="text/html; charset=utf-8" import="org.apache.commons.dbcp.BasicDataSource" %><%@ include file="init.jsp" %><%

DB db = new DB();
BasicDataSource ds = (BasicDataSource)db.getDataSource(jndi);

m.p(ds.getNumIdle());
m.p(ds.getNumActive());
m.p(ds.getMaxActive());
m.p(ds.getMinIdle());
m.p(ds.getMaxWait());
m.p(ds.getMinEvictableIdleTimeMillis());
m.p(ds.getTimeBetweenEvictionRunsMillis());

%>