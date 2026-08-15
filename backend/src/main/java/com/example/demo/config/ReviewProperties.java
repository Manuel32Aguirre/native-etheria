package com.example.demo.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

@ConfigurationProperties(prefix = "app.review")
public class ReviewProperties {

    /** Ebbinghaus-style progression, in minutes, applied strictly in order. */
    private List<Integer> intervalMinutes;
    private int blockSize = 5;
    private int requiredCorrectRepetitions = 20;

    public List<Integer> getIntervalMinutes() {
        return intervalMinutes;
    }

    public void setIntervalMinutes(List<Integer> intervalMinutes) {
        this.intervalMinutes = intervalMinutes;
    }

    public int getBlockSize() {
        return blockSize;
    }

    public void setBlockSize(int blockSize) {
        this.blockSize = blockSize;
    }

    public int getRequiredCorrectRepetitions() {
        return requiredCorrectRepetitions;
    }

    public void setRequiredCorrectRepetitions(int requiredCorrectRepetitions) {
        this.requiredCorrectRepetitions = requiredCorrectRepetitions;
    }
}
