package com.example.demo.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "stt")
public class SttProperties {

    /**
     * local  = faster-whisper on the same host ($0, slow on 1 GB)
     * groq   = Groq Whisper Large V3 (fast + cheap)
     * openai = OpenAI Whisper (fast + expensive)
     */
    private String provider = "groq";

    private String localBaseUrl = "http://localhost:9000";

    private String language = "en";

    private String groqApiKey = "";

    private String groqBaseUrl = "https://api.groq.com/openai/v1";

    /** whisper-large-v3-turbo (fast) or whisper-large-v3 (max accuracy). */
    private String groqModel = "whisper-large-v3-turbo";

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

    public String getGroqApiKey() {
        return groqApiKey;
    }

    public void setGroqApiKey(String groqApiKey) {
        this.groqApiKey = groqApiKey;
    }

    public String getGroqBaseUrl() {
        return groqBaseUrl;
    }

    public void setGroqBaseUrl(String groqBaseUrl) {
        this.groqBaseUrl = groqBaseUrl;
    }

    public String getGroqModel() {
        return groqModel;
    }

    public void setGroqModel(String groqModel) {
        this.groqModel = groqModel;
    }

    public boolean isLocal() {
        return "local".equalsIgnoreCase(provider);
    }

    public boolean isGroq() {
        return "groq".equalsIgnoreCase(provider);
    }

    public boolean isOpenAi() {
        return "openai".equalsIgnoreCase(provider);
    }
}
