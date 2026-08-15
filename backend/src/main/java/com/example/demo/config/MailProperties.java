package com.example.demo.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.mail")
public class MailProperties {
    private String from;
    private String verificationBaseUrl;

    public String getFrom() { return from; }
    public void setFrom(String from) { this.from = from; }
    public String getVerificationBaseUrl() { return verificationBaseUrl; }
    public void setVerificationBaseUrl(String verificationBaseUrl) { this.verificationBaseUrl = verificationBaseUrl; }
}