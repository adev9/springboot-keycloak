package com.dimaidt.springbootkeycloak.apidemo.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;

/**
 * @author : Alex Hu
 * date : 2020/3/17 下午21:19
 * description :
 */
@RestController
public class APIController {
    private final HttpServletRequest request;

    @Autowired
    public APIController(HttpServletRequest request) {
        this.request = request;
    }

    @GetMapping("/user")
    public String user() {
        return "user&admin access /user";
    }

    @GetMapping("/admin")
    public String admin() {
        return "admin access /admin";
    }
}
