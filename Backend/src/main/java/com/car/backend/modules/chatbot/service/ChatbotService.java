package com.car.backend.modules.chatbot.service;

import com.car.backend.modules.car.entity.Car;
import com.car.backend.modules.car.repository.CarRepository;
import com.car.backend.modules.chatbot.dtos.ChatbotDtos.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatbotService {

    private final CarRepository carRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${gemini.api-key}")
    private String apiKey;

    private static final String GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=";

    public ChatResponse chat(List<ChatMessage> history) {
        try {
            // 1. Fetch available cars from DB
            List<Car> cars = carRepository.findAll().stream()
                    .filter(car -> !car.isDeleted())
                    .toList();

            // 2. Format system prompt with database context
            StringBuilder systemPrompt = new StringBuilder();
            systemPrompt.append("Bạn là trợ lý ảo hỗ trợ khách hàng của EliteDrive (Dịch vụ thuê xe cao cấp).\n");
            systemPrompt.append("Nhiệm vụ của bạn là tư vấn, gợi ý xe và cung cấp thông tin xe dựa TRÊN DANH SÁCH XE THỰC TẾ dưới đây từ cơ sở dữ liệu của chúng tôi.\n");
            systemPrompt.append("YÊU CẦU QUAN TRỌNG: Không được tự bịa ra thông tin xe hoặc gợi ý xe không có trong danh sách dưới đây. Nếu khách hàng hỏi xe khác không có, hãy lịch sự từ chối và trả lời rằng EliteDrive hiện chưa hỗ trợ dòng xe đó.\n\n");
            systemPrompt.append("Danh sách xe đang có sẵn tại EliteDrive:\n");

            for (Car car : cars) {
                systemPrompt.append(String.format(
                        "- ID: %d | Tên xe: %s | Hãng: %s | Đời xe: %d | Số chỗ: %d | Nhiên liệu: %s | Hộp số: %s | Giá thuê: %,.0f đ/ngày | Mô tả: %s\n",
                        car.getCarId(),
                        car.getCarName(),
                        car.getBrand(),
                        car.getYear(),
                        car.getSeats(),
                        car.getFuelType() != null ? car.getFuelType().name() : "N/A",
                        car.getTransmission() != null ? car.getTransmission().name() : "N/A",
                        car.getPricePerDay() != null ? car.getPricePerDay().doubleValue() : 0.0,
                        car.getDescription() != null ? car.getDescription() : "Không có mô tả"
                ));
            }

            systemPrompt.append("\nHướng dẫn định dạng: Trả lời bằng tiếng Việt lịch sự, thân thiện, sử dụng markdown để trình bày đẹp mắt các thông số xe. Khi gợi ý xe, vui lòng đề cập rõ tên xe, hãng xe, số chỗ ngồi và giá thuê.");
            systemPrompt.append("\nQUAN TRỌNG: Khi gợi ý hoặc nhắc đến một hoặc nhiều dòng xe cụ thể có trong danh sách trên, bạn BẮT BUỘC phải đính kèm thẻ `[VIEW_CAR:ID_xe:Tên_xe]` trên một dòng riêng ngay sau đoạn mô tả của xe đó để ứng dụng hiển thị nút bấm 'Xem chi tiết'. Ví dụ: [VIEW_CAR:1:VinFast VF8]. Tuyệt đối không tự bịa ID hoặc tên xe ngoài danh sách.");

            // 3. Build request payload for Gemini
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("contents", history);

            // System Instruction configuration
            Map<String, Object> systemInstruction = new HashMap<>();
            systemInstruction.put("parts", List.of(Map.of("text", systemPrompt.toString())));
            requestBody.put("systemInstruction", systemInstruction);

            // 4. Send POST request
            RestTemplate restTemplate = new RestTemplate();
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<String> entity = new HttpEntity<>(objectMapper.writeValueAsString(requestBody), headers);
            String url = GEMINI_URL + apiKey;

            ResponseEntity<String> responseEntity = restTemplate.postForEntity(url, entity, String.class);

            if (responseEntity.getStatusCode().is2xxSuccessful() && responseEntity.getBody() != null) {
                JsonNode root = objectMapper.readTree(responseEntity.getBody());
                JsonNode textNode = root.path("candidates").path(0).path("content").path("parts").path(0).path("text");
                
                String reply = textNode.asText("Xin lỗi, tôi không thể xử lý yêu cầu lúc này.");
                return new ChatResponse(reply);
            }

        } catch (Exception e) {
            log.error("Error communicating with Gemini API", e);
        }
        return new ChatResponse("Xin lỗi, hệ thống AI của chúng tôi hiện đang bận. Vui lòng thử lại sau!");
    }
}
