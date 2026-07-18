package com.car.backend.common.utils;

import com.car.backend.modules.auth.entities.User;
import com.car.backend.modules.auth.entities.UserInformation;
import com.car.backend.modules.auth.entities.CustomerInformation;
import com.car.backend.modules.auth.enums.Role;
import com.car.backend.modules.auth.repository.UserRepository;
import com.car.backend.modules.auth.services.interfaces.UserInformationService;
import com.car.backend.modules.car.entity.Car;
import com.car.backend.modules.car.enums.CarStatus;
import com.car.backend.modules.car.enums.FuelType;
import com.car.backend.modules.car.enums.Transmission;
import com.car.backend.modules.car.repository.CarRepository;
import com.car.backend.modules.rental.entity.Rental;
import com.car.backend.modules.rental.entity.RentalDetail;
import com.car.backend.modules.rental.enums.RentalStatus;
import com.car.backend.modules.rental.repository.RentalRepository;
import com.google.common.base.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.NoSuchKeyException;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.Set;

/**
 * Class khởi tạo dữ liệu mẫu khi ứng dụng khởi động
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserInformationService userInformationService;
    private final CarRepository carRepository;
    private final RentalRepository rentalRepository;
    private final S3Client s3Client;

    @Value("${cloudflare.r2.custom-domain}")
    private String customDomain;

    @Value("${cloudflare.r2.bucket-name}")
    private String bucketName;

    
    @Override
    @Transactional
    public void run(String... args) {
        log.info("Starting data initialization...");
        
        // 1. Khởi tạo User và UserInformation nếu chưa có
        if (userRepository.count() <= 2) { 
            createAdminUser();
            createManagerUser();
            createRegularUsers(20); 
        } else {
            log.info("Users already initialized.");
            // Auto-update profiles for existing test users to fill in missing fields
            updateExistingTestUsersProfiles();
        }

        // Auto-upload seeder images to R2 bucket if missing
        uploadSampleImagesToR2();

        // 2. Khởi tạo Car nếu chưa có
        if (carRepository.count() == 0) {
            createSampleCars();
        } else {
            log.info("Cars already initialized.");
            // Auto-update old local/localhost URLs to R2
            updateExistingCarsThumbnailUrls();
        }

        // 3. Khởi tạo Rental và RentalDetail
        if (rentalRepository.count() == 0) {
            createSampleRentals(25);
        } else {
            log.info("Rentals already initialized.");
        }
        
        log.info("Data initialization completed successfully!");
    }

    private void uploadSampleImagesToR2() {
        log.info("Checking sample images in R2 bucket: {}", bucketName);
        java.io.File carFolder = new java.io.File("../frontend/public/car");
        if (!carFolder.exists() || !carFolder.isDirectory()) {
            carFolder = new java.io.File("frontend/public/car");
            if (!carFolder.exists()) {
                log.warn("Sample images directory not found at '../frontend/public/car' or 'frontend/public/car'");
                return;
            }
        }

        java.io.File[] files = carFolder.listFiles();
        if (files == null) return;

        for (java.io.File file : files) {
            if (file.isFile()) {
                String key = "car/" + file.getName();
                try {
                    s3Client.headObject(HeadObjectRequest.builder()
                            .bucket(bucketName)
                            .key(key)
                            .build());
                    log.info("Image already exists in R2: {}", key);
                } catch (NoSuchKeyException e) {
                    log.info("Uploading sample image to R2: {}", key);
                    try {
                        String contentType = "image/jpeg";
                        if (file.getName().endsWith(".png")) contentType = "image/png";
                        else if (file.getName().endsWith(".webp")) contentType = "image/webp";

                        PutObjectRequest putRequest = PutObjectRequest.builder()
                                .bucket(bucketName)
                                .key(key)
                                .contentType(contentType)
                                .build();

                        s3Client.putObject(putRequest, RequestBody.fromFile(file));
                        log.info("Uploaded sample image successfully: {}", key);
                    } catch (Exception ex) {
                        log.error("Failed to upload sample image: " + key, ex);
                    }
                } catch (Exception e) {
                    log.error("Error checking image existence in R2: " + key, e);
                }
            }
        }
    }

    private void updateExistingCarsThumbnailUrls() {
        log.info("Updating existing cars' thumbnail URLs to use R2 domain...");
        String baseUrl = customDomain;
        if (!baseUrl.endsWith("/")) {
            baseUrl += "/";
        }
        
        List<Car> cars = carRepository.findAll();
        for (Car car : cars) {
            String thumb = car.getThumbnailUrl();
            if (thumb != null) {
                if (thumb.contains("localhost:8080") || !thumb.startsWith(baseUrl)) {
                    String filename = thumb;
                    if (filename.contains("/")) {
                        filename = filename.substring(filename.lastIndexOf("/") + 1);
                    }
                    String newUrl = baseUrl + "car/" + filename;
                    car.setThumbnailUrl(newUrl);
                    carRepository.save(car);
                    log.info("Updated car {} thumbnail URL to: {}", car.getCarName(), newUrl);
                }
            }
        }
    }

    private void createSampleRentals(int count) {
        List<User> customers = userRepository.findAll().stream()
                .filter(u -> u.getRoles().contains(Role.CUSTOMER))
                .toList();
        List<User> staffList = userRepository.findAll().stream()
                .filter(u -> u.getRoles().contains(Role.STAFF))
                .toList();
        List<Car> cars = carRepository.findAll();

        if (customers.isEmpty() || cars.isEmpty()) {
            log.warn("Cannot create rentals: Customers or Cars list is empty.");
            return;
        }

        Random random = new Random();
        List<Rental> rentals = new ArrayList<>();

        for (int i = 1; i <= count; i++) {
            User customer = customers.get(random.nextInt(customers.size()));
            Car car = cars.get(random.nextInt(cars.size()));
            
            int days = random.nextInt(5) + 1;
            LocalDate startDate = LocalDate.now().minusDays(random.nextInt(30));
            LocalDate endDate = startDate.plusDays(days);
            
            BigDecimal totalPrice = car.getPricePerDay().multiply(BigDecimal.valueOf(days));

            Rental rental = Rental.builder()
                    .customer(customer)
                    .startDate(startDate)
                    .endDate(endDate)
                    .totalPrice(totalPrice)
                    .status(RentalStatus.values()[random.nextInt(RentalStatus.values().length)])
                    .notes("Ghi chú đơn thuê mẫu số " + i)
                    .build();

            if (rental.getStatus() != RentalStatus.PENDING && !staffList.isEmpty()) {
                rental.setStaff(staffList.get(random.nextInt(staffList.size())));
            }

            RentalDetail detail = RentalDetail.builder()
                    .rental(rental)
                    .car(car)
                    .pricePerDay(car.getPricePerDay())
                    .days(days)
                    .subtotal(totalPrice)
                    .build();

            rental.setRentalDetails(new ArrayList<>(List.of(detail)));
            rentals.add(rental);
        }

        rentalRepository.saveAll(rentals);
        log.info("Created {} sample rentals with details.", count);
    }

    private void createRegularUsers(int count) {
        for (int i = 1; i <= count; i++) {
            String username = "user" + i;
            User user = User.builder()
                    .username(username)
                    .password(passwordEncoder.encode("User@123"))
                    .email(username + "@example.com")
                    .phoneNumber("09010000" + String.format("%02d", i))
                    .roles(Set.of(Role.CUSTOMER))
                    .isEnabled(true)
                    .userNonExpired(true)
                    .userNonLocked(true)
                    .credentialsNonExpired(true)
                    .failedLoginAttempts(0)
                    .build();

            user.setCreatedDate(LocalDateTime.now());
            User savedUser = userRepository.save(user);
            
            UserInformation info = userInformationService.createInitialInformation(savedUser);
            info.setFullName("Khách Hàng Số " + i);
            info.setAddress("Địa chỉ mẫu, Quận " + (i % 10 + 1) + ", Hà Nội");
            info.setDateOfBirth(LocalDate.of(1995, 5, i % 28 + 1));
            
            if (info instanceof CustomerInformation customer) {
                customer.setIdentifyId("00120000" + String.format("%04d", i));
                customer.setDriverLicenceId("G1" + String.format("%08d", i));
            }
            
            userInformationService.save(info);
        }
        log.info("Created {} regular users with complete information.", count);
    }

    private void updateExistingTestUsersProfiles() {
        log.info("Updating existing test users' profiles to complete missing fields (CCCD, Bằng lái, Ngày sinh)...");
        List<User> users = userRepository.findAll();
        for (User user : users) {
            if (user.getUsername().startsWith("user") && user.getRoles().contains(Role.CUSTOMER)) {
                Optional<UserInformation> infoOpt = userInformationService.findByUserId(user.getUserId());
                if (infoOpt.isPresent()) {
                    UserInformation info = infoOpt.get();
                    boolean modified = false;
                    
                    if (info.getDateOfBirth() == null) {
                        info.setDateOfBirth(LocalDate.of(1995, 5, 15));
                        modified = true;
                    }
                    
                    if (info instanceof CustomerInformation customer) {
                        if (customer.getIdentifyId() == null || customer.getIdentifyId().isBlank()) {
                            customer.setIdentifyId("00120000" + String.format("%04d", user.getUserId()));
                            modified = true;
                        }
                        if (customer.getDriverLicenceId() == null || customer.getDriverLicenceId().isBlank()) {
                            customer.setDriverLicenceId("G1" + String.format("%08d", user.getUserId()));
                            modified = true;
                        }
                    }
                    
                    if (modified) {
                        userInformationService.save(info);
                        log.info("Completed profile details for user: {}", user.getUsername());
                    }
                }
            }
        }
    }

    private void createSampleCars() {
        String baseUrl = customDomain;
        if (!baseUrl.endsWith("/")) {
            baseUrl += "/";
        }
        List<Car> cars = List.of(
            createCar("Toyota Camry 2.5Q", "Toyota", "Camry", 2024, "30A-11111", "Đen", 5, FuelType.GASOLINE, Transmission.AUTOMATIC, 1200000, baseUrl + "car/ToyotaCamry2024.jpeg"),
            createCar("Honda City RS", "Honda", "City", 2023, "30A-22222", "Đỏ", 5, FuelType.GASOLINE, Transmission.AUTOMATIC, 800000, baseUrl + "car/Honda-City.jpg"),
            createCar("Ford Everest Titanium", "Ford", "Everest", 2023, "30A-33333", "Trắng", 7, FuelType.DIESEL, Transmission.AUTOMATIC, 1800000, baseUrl + "car/FordEverestTitanium.jpeg"),
            createCar("Mazda 3 Sedan", "Mazda", "Mazda 3", 2023, "30A-44444", "Xám", 5, FuelType.GASOLINE, Transmission.AUTOMATIC, 1000000, baseUrl + "car/Mazda3Sedan2023.jpg"),
            createCar("Mazda CX-5 Premium", "Mazda", "CX-5", 2023, "30A-55555", "Xanh", 5, FuelType.GASOLINE, Transmission.AUTOMATIC, 1300000, baseUrl + "car/MazdaCX-5Premium.jpeg"),
            createCar("Mitsubishi Xpander Premium", "Mitsubishi", "Xpander", 2023, "30A-66666", "Bạc", 7, FuelType.GASOLINE, Transmission.AUTOMATIC, 900000, baseUrl + "car/MitsubishiXpanderPremium.jpeg"),
            createCar("Kia Morning GT-Line", "Kia", "Morning", 2024, "30A-77777", "Vàng", 4, FuelType.GASOLINE, Transmission.AUTOMATIC, 500000, baseUrl + "car/KiaMorningGTLine.jpeg"),
            createCar("Kia Seltos Turbo", "Kia", "Seltos", 2024, "30A-88888", "Cam", 5, FuelType.GASOLINE, Transmission.AUTOMATIC, 950000, baseUrl + "car/KiaSeltosTurbo.webp"),
            createCar("Suzuki Swift GLX", "Suzuki", "Swift", 2024, "30A-99999", "Xanh", 5, FuelType.GASOLINE, Transmission.AUTOMATIC, 750000, baseUrl + "car/SuzukiSwiftGLX.jpeg"),
            createCar("Hyundai Accent Special", "Hyundai", "Accent", 2024, "30B-11111", "Trắng", 5, FuelType.GASOLINE, Transmission.AUTOMATIC, 850000, baseUrl + "car/car-register.png")
        );
        carRepository.saveAll(cars);
        log.info("Created 10 sample cars with R2 URLs.");
    }

    private Car createCar(String name, String brand, String model, int year, String plate, String color, int seats, FuelType fuel, Transmission trans, long price, String thumb) {
        return Car.builder()
                .carName(name).brand(brand).model(model).year(year)
                .licensePlate(plate).color(color).seats(seats)
                .fuelType(fuel).transmission(trans).carStatus(CarStatus.AVAILABLE)
                .pricePerDay(BigDecimal.valueOf(price))
                .description("Xe " + name + " chất lượng cao, đời " + year)
                .thumbnailUrl(thumb)
                .build();
    }

    private void createAdminUser() {
        User admin = User.builder()
                .username("admin")
                .password(passwordEncoder.encode("Admin@123"))
                .email("admin@codebase.com")
                .phoneNumber("0901234567")
                .roles(Set.of(Role.ADMIN, Role.STAFF))
                .isEnabled(true)
                .userNonExpired(true)
                .userNonLocked(true)
                .credentialsNonExpired(true)
                .failedLoginAttempts(0)
                .build();
        admin.setCreatedDate(LocalDateTime.now());
        User savedUser = userRepository.save(admin);
        UserInformation info = userInformationService.createInitialInformation(savedUser);
        info.setFullName("Quản Trị Viên");
        userInformationService.save(info);
        log.info("Created ADMIN user.");
    }

    private void createManagerUser() {
        User manager = User.builder()
                .username("manager")
                .password(passwordEncoder.encode("Manager@123"))
                .email("manager@codebase.com")
                .phoneNumber("0901234568")
                .roles(Set.of(Role.STAFF))
                .isEnabled(true)
                .userNonExpired(true)
                .userNonLocked(true)
                .credentialsNonExpired(true)
                .failedLoginAttempts(0)
                .build();
        manager.setCreatedDate(LocalDateTime.now());
        User savedUser = userRepository.save(manager);
        UserInformation info = userInformationService.createInitialInformation(savedUser);
        info.setFullName("Nhân Viên Quản Lý");
        userInformationService.save(info);
        log.info("Created STAFF user.");
    }
}
