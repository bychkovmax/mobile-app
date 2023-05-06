package com.systems.app.config;

import junit.framework.TestCase;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseTest extends TestCase {

    public void testGetExtraConnection() throws SQLException, ClassNotFoundException {
        Connection c = null;
        String user = "smev";
        String pass = "1";
        String url = "jdbc:postgresql://localhost:6666/smev";
        Class.forName("org.postgresql.Driver");
        c=DriverManager.getConnection(url, user, pass);
        assertFalse(c.isClosed());
    }
}