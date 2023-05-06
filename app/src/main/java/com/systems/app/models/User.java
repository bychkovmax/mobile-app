package com.systems.app.models;

import androidx.room.Entity;

import java.time.LocalDate;

@Entity
public class User {
    Long id;
    String email,password, role;
    LocalDate create_at;
    boolean deleted;
}
