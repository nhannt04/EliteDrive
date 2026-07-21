package com.car.backend.modules.chatbot.dtos;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

public class ChatbotDtos {

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChatMessage {
        private String role; // "user" or "model"
        private List<ChatPart> parts;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChatPart {
        private String text;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChatRequest {
        private List<ChatMessage> history;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChatResponse {
        private String reply;
    }
}
