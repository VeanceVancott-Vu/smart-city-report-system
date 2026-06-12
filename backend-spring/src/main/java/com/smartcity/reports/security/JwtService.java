package com.smartcity.reports.security;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartcity.reports.user.User;
import com.smartcity.reports.user.UserRole;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class JwtService {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final Base64.Encoder BASE64_URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder BASE64_URL_DECODER = Base64.getUrlDecoder();

    private final ObjectMapper objectMapper;
    private final byte[] secret;
    private final Duration expiration;

    public JwtService(
            ObjectMapper objectMapper,
            JwtProperties properties
    ) {
        String secret = properties.secret();
        long expirationMinutes = properties.expirationMinutes();
        if (secret == null || secret.length() < 32) {
            throw new IllegalStateException("JWT_SECRET must be at least 32 characters long");
        }
        if (expirationMinutes <= 0) {
            throw new IllegalStateException("JWT_EXPIRATION_MINUTES must be greater than zero");
        }
        this.objectMapper = objectMapper;
        this.secret = secret.getBytes(StandardCharsets.UTF_8);
        this.expiration = Duration.ofMinutes(expirationMinutes);
    }

    public String generateToken(User user) {
        Instant issuedAt = Instant.now();
        Instant expiresAt = issuedAt.plus(expiration);

        Map<String, Object> header = new LinkedHashMap<>();
        header.put("alg", "HS256");
        header.put("typ", "JWT");

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("sub", user.getId().toString());
        payload.put("email", user.getEmail());
        payload.put("role", user.getRole().name());
        payload.put("iat", issuedAt.getEpochSecond());
        payload.put("exp", expiresAt.getEpochSecond());

        String unsignedToken = encodeJson(header) + "." + encodeJson(payload);
        return unsignedToken + "." + sign(unsignedToken);
    }

    public JwtClaims parseAndValidate(String token) {
        String[] parts = token.split("\\.");
        if (parts.length != 3) {
            throw new InvalidJwtException("Invalid token format");
        }

        String unsignedToken = parts[0] + "." + parts[1];
        String expectedSignature = sign(unsignedToken);
        if (!MessageDigest.isEqual(
                expectedSignature.getBytes(StandardCharsets.UTF_8),
                parts[2].getBytes(StandardCharsets.UTF_8)
        )) {
            throw new InvalidJwtException("Invalid token signature");
        }

        Map<String, Object> payload = decodePayload(parts[1]);
        Instant expiresAt = readEpochSecond(payload, "exp");
        if (!expiresAt.isAfter(Instant.now())) {
            throw new InvalidJwtException("Token has expired");
        }

        try {
            UUID userId = UUID.fromString(readString(payload, "sub"));
            String email = readString(payload, "email");
            UserRole role = UserRole.valueOf(readString(payload, "role"));
            Instant issuedAt = readEpochSecond(payload, "iat");
            return new JwtClaims(userId, email, role, issuedAt, expiresAt);
        } catch (IllegalArgumentException exception) {
            throw new InvalidJwtException("Invalid token claims");
        }
    }

    private String encodeJson(Map<String, Object> value) {
        try {
            return BASE64_URL_ENCODER.encodeToString(objectMapper.writeValueAsBytes(value));
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Failed to encode JWT JSON", exception);
        }
    }

    private Map<String, Object> decodePayload(String encodedPayload) {
        try {
            byte[] payloadBytes = BASE64_URL_DECODER.decode(encodedPayload);
            return objectMapper.readValue(payloadBytes, new TypeReference<>() {
            });
        } catch (IllegalArgumentException | IOException exception) {
            throw new InvalidJwtException("Invalid token payload");
        }
    }

    private String sign(String unsignedToken) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(secret, HMAC_ALGORITHM));
            return BASE64_URL_ENCODER.encodeToString(mac.doFinal(unsignedToken.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("Failed to sign JWT", exception);
        }
    }

    private String readString(Map<String, Object> payload, String key) {
        Object value = payload.get(key);
        if (value instanceof String stringValue && !stringValue.isBlank()) {
            return stringValue;
        }
        throw new InvalidJwtException("Token is missing " + key);
    }

    private Instant readEpochSecond(Map<String, Object> payload, String key) {
        Object value = payload.get(key);
        if (value instanceof Number numberValue) {
            return Instant.ofEpochSecond(numberValue.longValue());
        }
        throw new InvalidJwtException("Token is missing " + key);
    }
}
