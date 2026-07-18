package com.car.backend.modules.file.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/files")
@Slf4j
@CrossOrigin(origins = "http://localhost:5173", allowCredentials = "true")
public class FileUploadController {

    @Value("${cloudflare.r2.bucket-name}")
    private String bucketName;

    @Value("${cloudflare.r2.custom-domain}")
    private String customDomain;

    @Autowired
    private S3Client s3Client;

    @PostMapping("/upload-profile")
    public ResponseEntity<?> uploadProfileImage(@RequestParam("file") MultipartFile file) {
        return processUpload(file, "profile/");
    }

    @PostMapping("/upload-car")
    public ResponseEntity<?> uploadCarImage(@RequestParam("file") MultipartFile file) {
        return processUpload(file, "car/");
    }

    private ResponseEntity<?> processUpload(MultipartFile file, String folderPrefix) {
        log.info("Received upload request for R2: {}, folder: {}", file.getOriginalFilename(), folderPrefix);
        
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "File is empty"));
        }

        try {
            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            String fileName = UUID.randomUUID().toString() + extension;
            String key = folderPrefix + fileName;

            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .contentType(file.getContentType())
                    .build();

            s3Client.putObject(putObjectRequest, RequestBody.fromInputStream(file.getInputStream(), file.getSize()));

            log.info("File uploaded successfully to R2 bucket: {}, key: {}", bucketName, key);

            String baseUrl = customDomain;
            if (!baseUrl.endsWith("/")) {
                baseUrl += "/";
            }
            String fileUrl = baseUrl + key;

            return ResponseEntity.ok(Map.of(
                "url", fileUrl,
                "fileName", fileName
            ));
        } catch (IOException e) {
            log.error("Failed to upload file to Cloudflare R2", e);
            return ResponseEntity.internalServerError().body(Map.of("message", "Failed to upload file: " + e.getMessage()));
        }
    }
}

