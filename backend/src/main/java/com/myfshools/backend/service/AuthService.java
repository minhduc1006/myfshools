package com.myfshools.backend.service;

import com.myfshools.backend.config.JwtProperties;
import com.myfshools.backend.domain.AppUser;
import com.myfshools.backend.dto.AuthLoginRequest;
import com.myfshools.backend.dto.AuthLoginResponse;
import com.myfshools.backend.dto.UserSummary;
import com.myfshools.backend.repository.AppUserRepository;
import com.myfshools.backend.security.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthService {
    private final CurrentUserService currentUserService;
    private final AppUserRepository appUserRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final JwtProperties jwtProperties;

    public AuthService(CurrentUserService currentUserService,
                       AppUserRepository appUserRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       JwtProperties jwtProperties) {
        this.currentUserService = currentUserService;
        this.appUserRepository = appUserRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.jwtProperties = jwtProperties;
    }

    public AuthLoginResponse login(AuthLoginRequest request) {
        AppUser user = appUserRepository.findByPhone(request.phone())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Sai so dien thoai hoac mat khau"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Sai so dien thoai hoac mat khau");
        }

        String token = jwtService.generateToken(user.getPhone());
        return new AuthLoginResponse(token, "Bearer", jwtProperties.getExpirationMs(), toUserSummary(user));
    }

    public UserSummary me() {
        return toUserSummary(currentUserService.getRequiredUser());
    }

    private UserSummary toUserSummary(AppUser user) {
        return new UserSummary(
                user.getId(),
                user.getPhone(),
                user.getFullName(),
                user.getClassName(),
                user.getTerm(),
                user.getGpa(),
                user.getAvatarInitial()
        );
    }
}
