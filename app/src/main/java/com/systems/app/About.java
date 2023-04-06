package com.systems.app;

import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;


public class About extends AppCompatActivity {

    CardView inst,vk,mail;

    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_about);

        inst = findViewById(R.id.inst);
        vk = findViewById(R.id.vk);
        mail = findViewById(R.id.mail);

        inst.setOnClickListener(v -> {
            Intent myWebLink = new Intent(Intent.ACTION_VIEW);
            myWebLink.setData(Uri.parse("https://instagram.com/bychkov.max"));
            startActivity(myWebLink);
        });
        vk.setOnClickListener(v -> {
            Intent myWebLink = new Intent(Intent.ACTION_VIEW);
            myWebLink.setData(Uri.parse("https://vk.com/mega_destroy"));
            startActivity(myWebLink);
        });
        mail.setOnClickListener(v -> {
            Intent myWebLink = new Intent(Intent.ACTION_VIEW);
            myWebLink.setData(Uri.parse("mailto:microsoftcraft@mail.ru"));
            startActivity(myWebLink);
        });
    }

}