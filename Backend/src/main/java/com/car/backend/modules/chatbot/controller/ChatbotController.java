package com.car.backend.modules.chatbot.controller;

import com.car.backend.modules.chatbot.dtos.ChatbotDtos.*;
import com.car.backend.modules.chatbot.service.ChatbotService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/chatbot")
@RequiredArgsConstructor
public class ChatbotController {

    private final ChatbotService chatbotService;

    @PostMapping("/chat")
    public ResponseEntity<ChatResponse> chat(@RequestBody ChatRequest request) {
        if (request.getHistory() == null) {
            return ResponseEntity.badRequest().build();
        }
        ChatResponse reply = chatbotService.chat(request.getHistory());
        return ResponseEntity.ok(reply);
    }
}
