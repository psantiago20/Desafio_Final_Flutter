package com.pitaya.library.service;

import com.pitaya.library.dto.request.CreateMaterialRequest;
import com.pitaya.library.dto.request.MaterialFilterRequest;
import com.pitaya.library.dto.request.UpdateMaterialRequest;
import com.pitaya.library.dto.response.MaterialResponse;
import com.pitaya.library.dto.response.MaterialSummaryResponse;
import com.pitaya.shared.dto.PagedResponse;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.UUID;

public interface LibraryService {

    MaterialResponse create(UUID userId, CreateMaterialRequest request);

    MaterialResponse findById(UUID id);

    MaterialResponse update(UUID id, UUID userId, UpdateMaterialRequest request);

    void delete(UUID id, UUID userId);

    PagedResponse<MaterialSummaryResponse> list(MaterialFilterRequest filter, Pageable pageable);

    PagedResponse<MaterialSummaryResponse> getByUploader(UUID userId, Pageable pageable);

    PagedResponse<MaterialSummaryResponse> getByGroup(UUID groupId, Pageable pageable);

    MaterialResponse incrementDownload(UUID id);

    List<MaterialSummaryResponse> getPopular(int limit);
}
