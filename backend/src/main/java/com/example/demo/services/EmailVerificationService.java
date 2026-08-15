package com.example.demo.services;

import com.example.demo.domain.EmailVerificationToken;
import com.example.demo.domain.User;
import com.example.demo.exception.BadRequestException;
import com.example.demo.repositories.EmailVerificationTokenRepository;
import com.example.demo.repositories.UserRepository;
import com.example.demo.config.MailProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class EmailVerificationService {
    private final EmailVerificationTokenRepository tokenRepository;
    private final UserRepository userRepository;
    private final JavaMailSender mailSender;
    private final MailProperties mailProperties;

    @Transactional
    public void sendVerification(User user) {
        String token = UUID.randomUUID().toString();
        tokenRepository.save(EmailVerificationToken.builder()
                .token(token)
                .user(user)
                .expiresAt(Instant.now().plus(24, ChronoUnit.HOURS))
                .build());

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(mailProperties.getFrom());
        message.setTo(user.getEmail());
        message.setSubject("Verifica tu cuenta Native");
        message.setText("Verifica tu cuenta abriendo este enlace: "
                + mailProperties.getVerificationBaseUrl() + "?token=" + token);
        mailSender.send(message);
    }

    @Transactional
    public void verify(String rawToken) {
        EmailVerificationToken verification = tokenRepository.findByToken(rawToken)
                .orElseThrow(() -> new BadRequestException("Invalid verification token"));
        if (verification.getExpiresAt().isBefore(Instant.now())) {
            throw new BadRequestException("Verification token expired");
        }
        User user = verification.getUser();
        user.setEmailVerified(true);
        userRepository.save(user);
        tokenRepository.delete(verification);
    }
}