package com.systems.app.models;

import androidx.room.Entity;

@Entity
public class News {
    String name,type,description,userid;

    public News() {

    }

    public News(String name, String type, String description, String userid) {
        this.name = name;
        this.type = type;
        this.description = description;
        this.userid = userid;
    }

    public String getUserid() {
        return userid;
    }

    public void setUserid(String userid) {
        this.userid = userid;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}
