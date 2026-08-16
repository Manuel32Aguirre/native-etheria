package com.example.demo.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "stt")
public class SttProperties {

    /**
     * local = faster-whisper microservice on the same host/network
     * openai = OpenAI /audio/transcriptions (costs money per attempt)
     */
    private String provider = "local";

    private String localBaseUrl = "http://localhost:9000";

    private String language = "en";

    public String getProvider() {
        return provider;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }

    public String getLocalBaseUrl() {
        return localBaseUrl;
    }

    public void setLocalBaseUrl(String localBaseUrl) {
        this.localBaseUrl = localBaseUrl;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public boolean isLocal() {
        return "local".equalsIgnoreCase(provider);
    }
}
