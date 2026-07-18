package com.car.backend.modules.payment.controller;

import com.car.backend.modules.rental.entity.Rental;
import com.car.backend.modules.rental.entity.RentalDetail;
import com.car.backend.modules.rental.repository.RentalRepository;
import com.car.backend.modules.rental.enums.RentalStatus;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import vn.payos.PayOS;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkRequest;
import vn.payos.model.v2.paymentRequests.CreatePaymentLinkResponse;
import vn.payos.model.v2.paymentRequests.PaymentLinkItem;
import vn.payos.model.v2.paymentRequests.PaymentLink;
import vn.payos.model.v2.paymentRequests.PaymentLinkStatus;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/payments")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Payment Management", description = "APIs for integrating payOS payment gateway")
public class PaymentController {

    private final PayOS payOS;
    private final RentalRepository rentalRepository;

    @PostMapping("/create-link/{rentalId}")
    @PreAuthorize("hasRole('CUSTOMER')")
    @Operation(summary = "Create PayOS Payment Link", description = "Create payOS checkout URL for a specific rental booking")
    public ResponseEntity<?> createPaymentLink(@PathVariable Long rentalId) {
        try {
            Rental rental = rentalRepository.findById(rentalId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy đơn đặt xe có ID: " + rentalId));

            if (rental.getStatus() != RentalStatus.PENDING) {
                return ResponseEntity.badRequest().body(Map.of("message", "Đơn đặt xe đã được xử lý hoặc thanh toán trước đó."));
            }

            // Tạo danh sách vật phẩm thanh toán
            List<PaymentLinkItem> items = new ArrayList<>();
            for (RentalDetail detail : rental.getRentalDetails()) {
                PaymentLinkItem item = PaymentLinkItem.builder()
                        .name(detail.getCar().getCarName())
                        .price(detail.getPricePerDay().longValue())
                        .quantity(detail.getDays())
                        .build();
                items.add(item);
            }

            String returnUrl = "http://localhost:5173/payment/success?rentalId=" + rentalId;
            String cancelUrl = "http://localhost:5173/payment/cancel?rentalId=" + rentalId;

            // Tìm một orderCode chưa từng tồn tại trên PayOS cho đơn này (bắt đầu từ rentalId * 1000 + 1)
            long orderCode = rentalId * 1000 + 1;
            for (int attempt = 1; attempt <= 100; attempt++) {
                long checkCode = rentalId * 1000 + attempt;
                try {
                    PaymentLink info = payOS.paymentRequests().get(checkCode);
                    // Nếu tồn tại và đang ở trạng thái PENDING, gọi lệnh hủy để đóng giao dịch cũ lại
                    if (info.getStatus() == PaymentLinkStatus.PENDING) {
                        try {
                            payOS.paymentRequests().cancel(checkCode, "Tao lai link thanh toan moi");
                        } catch (Exception ignored) {}
                    }
                } catch (Exception ex) {
                    // Nếu ném ra ngoại lệ (nghĩa là mã đơn này chưa từng tồn tại trên PayOS), chúng ta có thể sử dụng!
                    orderCode = checkCode;
                    break;
                }
            }

            log.info("Generating PayOS payment link for rentalId={} with orderCode={}", rentalId, orderCode);

            CreatePaymentLinkRequest paymentData = CreatePaymentLinkRequest.builder()
                    .orderCode(orderCode)
                    .amount(rental.getTotalPrice().longValue())
                    .description("Thanh toan don thue " + rentalId)
                    .items(items)
                    .returnUrl(returnUrl)
                    .cancelUrl(cancelUrl)
                    .build();

            CreatePaymentLinkResponse checkoutData = payOS.paymentRequests().create(paymentData);
            return ResponseEntity.ok(Map.of("checkoutUrl", checkoutData.getCheckoutUrl()));

        } catch (Exception e) {
            log.error("Lỗi khi tạo link thanh toán PayOS cho đơn {}: {}", rentalId, e.getMessage(), e);
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi tạo link thanh toán: " + e.getMessage()));
        }
    }

    @PostMapping("/confirm/{rentalId}")
    @Operation(summary = "Confirm payment status from PayOS", description = "Query PayOS API to verify payment success and update booking status")
    public ResponseEntity<?> confirmPayment(@PathVariable Long rentalId) {
        try {
            Rental rental = rentalRepository.findById(rentalId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy đơn đặt xe"));

            // Duyệt qua các orderCode của các lần thử từ 1 đến 100
            PaymentLink paymentInfo = null;
            boolean isPaid = false;

            for (int attempt = 1; attempt <= 100; attempt++) {
                long checkCode = rentalId * 1000 + attempt;
                try {
                    PaymentLink info = payOS.paymentRequests().get(checkCode);
                    paymentInfo = info;
                    if (info.getStatus() == PaymentLinkStatus.PAID) {
                        isPaid = true;
                        break;
                    }
                } catch (Exception ex) {
                    // Dừng quét khi mã checkCode này chưa từng được sinh ra trên PayOS
                    break;
                }
            }

            if (paymentInfo == null) {
                return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Không tìm thấy thông tin thanh toán nào trên PayOS."));
            }
            
            if (isPaid) {
                if (rental.getStatus() == RentalStatus.PENDING) {
                    rental.setStatus(RentalStatus.CONFIRMED);
                    rentalRepository.save(rental);
                }
                return ResponseEntity.ok(Map.of(
                        "success", true,
                        "message", "Thanh toán thành công. Trạng thái đơn đặt xe đã được cập nhật.",
                        "status", rental.getStatus()
                ));
            } else {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Đơn hàng chưa được thanh toán thành công trên PayOS. Trạng thái hiện tại: " + paymentInfo.getStatus()
                ));
            }

        } catch (Exception e) {
            log.error("Lỗi xác nhận thanh toán PayOS cho đơn {}: {}", rentalId, e.getMessage());
            return ResponseEntity.internalServerError().body(Map.of("message", "Lỗi xác nhận thanh toán: " + e.getMessage()));
        }
    }
}
