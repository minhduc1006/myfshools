package com.myfshools.backend.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.myfshools.backend.config.PayOsProperties;
import com.myfshools.backend.domain.TuitionInvoice;
import com.myfshools.backend.dto.PayOsCheckoutDto;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class PayOsService {
    private final PayOsProperties payOsProperties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    public PayOsService(PayOsProperties payOsProperties, ObjectMapper objectMapper) {
        this.payOsProperties = payOsProperties;
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();
    }

    public PayOsCheckoutDto createPaymentLink(TuitionInvoice invoice) {
        validateConfig();

        long orderCode = buildOrderCode(invoice);
        String description = trimDescription(invoice.getTitle());

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("orderCode", orderCode);
        payload.put("amount", invoice.getAmount());
        payload.put("description", description);
        payload.put("returnUrl", payOsProperties.getReturnUrl());
        payload.put("cancelUrl", payOsProperties.getCancelUrl());
        payload.put("items", List.of(Map.of(
                "name", description,
                "quantity", 1,
                "price", invoice.getAmount()
        )));
        payload.put("signature", signCreatePayload(orderCode, invoice.getAmount(), description));

        Map<String, Object> data = callPayOs("/v2/payment-requests", "POST", payload);

        return new PayOsCheckoutDto(
                invoice.getId(),
                ((Number) data.getOrDefault("orderCode", orderCode)).longValue(),
                valueOf(data.get("checkoutUrl")),
                valueOf(data.get("qrCode")),
                valueOf(data.getOrDefault("status", "PENDING"))
        );
    }

    public PayOsCheckoutDto getPaymentLinkInfo(TuitionInvoice invoice) {
        validateConfig();
        if (invoice.getPayOsOrderCode() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Hoa don chua co ma don PayOS");
        }

        Map<String, Object> data = callPayOs("/v2/payment-requests/" + invoice.getPayOsOrderCode(), "GET", null);
        return new PayOsCheckoutDto(
                invoice.getId(),
                ((Number) data.getOrDefault("orderCode", invoice.getPayOsOrderCode())).longValue(),
                valueOf(data.get("checkoutUrl")),
                valueOf(data.get("qrCode")),
                valueOf(data.getOrDefault("status", "PENDING"))
        );
    }

    private void validateConfig() {
        if (isBlank(payOsProperties.getClientId()) ||
                isBlank(payOsProperties.getApiKey()) ||
                isBlank(payOsProperties.getChecksumKey()) ||
                isBlank(payOsProperties.getReturnUrl()) ||
                isBlank(payOsProperties.getCancelUrl())) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "PayOS chua duoc cau hinh day du. Can clientId, apiKey, checksumKey, returnUrl, cancelUrl."
            );
        }
    }

    private Map<String, Object> callPayOs(String path, String method, Map<String, Object> payload) {
        try {
            HttpRequest.Builder builder = HttpRequest.newBuilder()
                    .uri(URI.create(payOsProperties.getBaseUrl() + path))
                    .timeout(Duration.ofSeconds(20))
                    .header("x-client-id", payOsProperties.getClientId())
                    .header("x-api-key", payOsProperties.getApiKey())
                    .header("Content-Type", "application/json");

            if ("POST".equalsIgnoreCase(method)) {
                builder.POST(HttpRequest.BodyPublishers.ofString(objectMapper.writeValueAsString(payload)));
            } else {
                builder.GET();
            }

            HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
            Map<String, Object> root = objectMapper.readValue(response.body(), new TypeReference<>() {});

            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "PayOS tra ve loi: " + valueOf(root.get("desc")));
            }

            Object data = root.get("data");
            if (!(data instanceof Map<?, ?> dataMap)) {
                throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "PayOS khong tra ve du lieu hop le");
            }

            return (Map<String, Object>) dataMap;
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Khong ket noi duoc den PayOS: " + ex.getMessage(), ex);
        }
    }

    private String signCreatePayload(long orderCode, int amount, String description) {
        String data = "amount=" + amount +
                "&cancelUrl=" + payOsProperties.getCancelUrl() +
                "&description=" + description +
                "&orderCode=" + orderCode +
                "&returnUrl=" + payOsProperties.getReturnUrl();
        return hmacSha256(data, payOsProperties.getChecksumKey());
    }

    private String hmacSha256(String data, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] bytes = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(bytes.length * 2);
            for (byte b : bytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Khong the tao chu ky PayOS", ex);
        }
    }

    private long buildOrderCode(TuitionInvoice invoice) {
        long base = System.currentTimeMillis() % 900_000_000L;
        return base + (invoice.getId() == null ? 0 : invoice.getId());
    }

    private String trimDescription(String title) {
        String value = title == null ? "Thanh toan hoc phi" : title.trim();
        if (value.isEmpty()) value = "Thanh toan hoc phi";
        return value.length() <= 25 ? value : value.substring(0, 25);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String valueOf(Object value) {
        return value == null ? "" : value.toString();
    }
}
