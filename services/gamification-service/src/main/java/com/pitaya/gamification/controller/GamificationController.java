package com.pitaya.gamification.controller;

import com.pitaya.gamification.dto.response.BadgeResponse;
import com.pitaya.gamification.dto.response.GamificationResponse;
import com.pitaya.gamification.dto.response.LeaderboardEntryResponse;
import com.pitaya.gamification.dto.response.XpTransactionResponse;
import com.pitaya.gamification.entity.Badge;
import com.pitaya.gamification.mapper.BadgeMapper;
import com.pitaya.gamification.repository.BadgeRepository;
import com.pitaya.gamification.service.GamificationService;
import com.pitaya.shared.dto.ApiResponse;
import com.pitaya.shared.dto.PagedResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/gamification")
public class GamificationController {

    private final GamificationService gamificationService;
    private final BadgeRepository badgeRepository;
    private final BadgeMapper badgeMapper;

    public GamificationController(GamificationService gamificationService,
                                   BadgeRepository badgeRepository,
                                   BadgeMapper badgeMapper) {
        this.gamificationService = gamificationService;
        this.badgeRepository = badgeRepository;
        this.badgeMapper = badgeMapper;
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<GamificationResponse>> getMyGamification(Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        GamificationResponse response = gamificationService.getUserGamification(userId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/users/{userId}")
    public ResponseEntity<ApiResponse<GamificationResponse>> getUserGamification(@PathVariable UUID userId) {
        GamificationResponse response = gamificationService.getUserGamification(userId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/leaderboard")
    public ResponseEntity<ApiResponse<List<LeaderboardEntryResponse>>> getLeaderboard(
            @RequestParam(defaultValue = "20") int limit) {
        List<LeaderboardEntryResponse> leaderboard = gamificationService.getLeaderboard(limit);
        return ResponseEntity.ok(ApiResponse.success(leaderboard));
    }

    @GetMapping("/leaderboard/rank")
    public ResponseEntity<ApiResponse<Integer>> getMyRank(Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        int rank = gamificationService.getRank(userId);
        return ResponseEntity.ok(ApiResponse.success(rank));
    }

    @GetMapping("/badges")
    public ResponseEntity<ApiResponse<List<BadgeResponse>>> getAllBadges() {
        List<Badge> badges = badgeRepository.findAllByOrderByXpRequired();
        List<BadgeResponse> response = badges.stream()
            .map(badgeMapper::toResponse)
            .collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/history")
    public ResponseEntity<ApiResponse<PagedResponse<XpTransactionResponse>>> getXpHistory(
            Principal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID userId = UUID.fromString(principal.getName());
        PageRequest pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<XpTransactionResponse> history = gamificationService.getXpHistory(userId, pageable);

        PagedResponse<XpTransactionResponse> paged = PagedResponse.<XpTransactionResponse>builder()
            .content(history.getContent())
            .page(page)
            .size(size)
            .totalElements(history.getTotalElements())
            .totalPages(history.getTotalPages())
            .last(history.isLast())
            .build();

        return ResponseEntity.ok(ApiResponse.success(paged));
    }
}
