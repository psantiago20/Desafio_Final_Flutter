package com.pitaya.user.service;

import com.pitaya.shared.exception.BadRequestException;
import com.pitaya.user.dto.response.InterestResponse;
import com.pitaya.user.entity.Interest;
import com.pitaya.user.entity.UserInterest;
import com.pitaya.user.entity.UserInterestId;
import com.pitaya.user.mapper.InterestMapper;
import com.pitaya.user.repository.InterestRepository;
import com.pitaya.user.repository.UserInterestRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional
public class InterestServiceImpl implements InterestService {

    private static final Logger log = LoggerFactory.getLogger(InterestServiceImpl.class);

    private final InterestRepository interestRepository;
    private final UserInterestRepository userInterestRepository;
    private final InterestMapper interestMapper;

    public InterestServiceImpl(InterestRepository interestRepository,
                                UserInterestRepository userInterestRepository,
                                InterestMapper interestMapper) {
        this.interestRepository = interestRepository;
        this.userInterestRepository = userInterestRepository;
        this.interestMapper = interestMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public List<InterestResponse> getAllInterests() {
        List<Interest> interests = interestRepository.findAll();
        return interestMapper.toResponseList(interests);
    }

    @Override
    public List<InterestResponse> updateUserInterests(UUID userId, List<String> interestNames) {
        userInterestRepository.deleteByUserId(userId);

        List<Interest> interests = interestNames.stream()
            .map(name -> interestRepository.findByName(name)
                .orElseThrow(() -> new BadRequestException("Interest not found: " + name)))
            .collect(Collectors.toList());

        List<UserInterest> userInterests = interests.stream()
            .map(interest -> {
                UserInterestId id = UserInterestId.builder()
                    .userId(userId)
                    .interestId(interest.getId())
                    .build();
                return UserInterest.builder().id(id).build();
            })
            .collect(Collectors.toList());

        userInterestRepository.saveAll(userInterests);
        log.info("Interests updated for user: {}", userId);

        return interestMapper.toResponseList(interests);
    }
}
