package com.dimaidt.springbootkeycloak.webdemo.model;

import lombok.Data;

/**
 * @author Alex Hu
 */
@Data
public class Book {
    private String id;
    private String title;
    private String author;

    public Book(String id, String title, String author) {
        this.id = id;
        this.title = title;
        this.author = author;
    }
}
