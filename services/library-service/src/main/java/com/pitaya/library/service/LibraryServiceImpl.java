package com.pitaya.library.service;

import com.pitaya.library.dto.request.CreateMaterialRequest;
import com.pitaya.library.dto.request.MaterialFilterRequest;
import com.pitaya.library.dto.request.UpdateMaterialRequest;
import com.pitaya.library.dto.response.MaterialResponse;
import com.pitaya.library.dto.response.MaterialSummaryResponse;
import com.pitaya.library.entity.Material;
import com.pitaya.library.mapper.MaterialFilterMapper;
import com.pitaya.library.mapper.MaterialMapper;
import com.pitaya.library.repository.MaterialRepository;
import com.pitaya.shared.dto.PagedResponse;
import com.pitaya.shared.exception.ForbiddenException;
import com.pitaya.shared.exception.ResourceNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional
public class LibraryServiceImpl implements LibraryService {

    private static final Logger log = LoggerFactory.getLogger(LibraryServiceImpl.class);

    private final MaterialRepository materialRepository;
    private final MaterialMapper materialMapper;
    private final MaterialFilterMapper materialFilterMapper;

    public LibraryServiceImpl(MaterialRepository materialRepository,
                              MaterialMapper materialMapper,
                              MaterialFilterMapper materialFilterMapper) {
        this.materialRepository = materialRepository;
        this.materialMapper = materialMapper;
        this.materialFilterMapper = materialFilterMapper;
    }

    @Override
    public MaterialResponse create(UUID userId, CreateMaterialRequest request) {
        Material material = materialMapper.toEntity(request);
        material.setUploaderId(userId);

        if (request.getIsPublic() == null) {
            material.setPublic(true);
        } else {
            material.setPublic(request.getIsPublic());
        }

        material = materialRepository.save(material);

        log.info("Material created: {} by user: {}", material.getId(), userId);
        return enrichResponse(material);
    }

    @Override
    @Transactional(readOnly = true)
    public MaterialResponse findById(UUID id) {
        Material material = materialRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Material", "id", id));
        return enrichResponse(material);
    }

    @Override
    public MaterialResponse update(UUID id, UUID userId, UpdateMaterialRequest request) {
        Material material = materialRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Material", "id", id));

        if (!material.getUploaderId().equals(userId)) {
            throw new ForbiddenException("Only the uploader can update this material");
        }

        if (request.getTitle() != null) {
            material.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            material.setDescription(request.getDescription());
        }
        if (request.getType() != null) {
            material.setType(request.getType());
        }
        if (request.getUrl() != null) {
            material.setUrl(request.getUrl());
        }
        if (request.getFileSize() != null) {
            material.setFileSize(request.getFileSize());
        }
        if (request.getFileType() != null) {
            material.setFileType(request.getFileType());
        }
        if (request.getTags() != null) {
            material.setTags(request.getTags());
        }
        if (request.getIsPublic() != null) {
            material.setPublic(request.getIsPublic());
        }

        material = materialRepository.save(material);

        log.info("Material updated: {} by user: {}", id, userId);
        return enrichResponse(material);
    }

    @Override
    public void delete(UUID id, UUID userId) {
        Material material = materialRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Material", "id", id));

        if (!material.getUploaderId().equals(userId)) {
            throw new ForbiddenException("Only the uploader can delete this material");
        }

        materialRepository.delete(material);

        log.info("Material deleted: {} by user: {}", id, userId);
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<MaterialSummaryResponse> list(MaterialFilterRequest filter, Pageable pageable) {
        Specification<Material> spec = materialFilterMapper.toSpecification(filter);
        Page<Material> materials = materialRepository.findAll(spec, pageable);

        List<MaterialSummaryResponse> content = materials.getContent().stream()
            .map(materialMapper::toSummaryResponse)
            .collect(Collectors.toList());

        return buildPagedResponse(content, materials, pageable);
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<MaterialSummaryResponse> getByUploader(UUID userId, Pageable pageable) {
        Page<Material> materials = materialRepository.findByUploaderId(userId, pageable);

        List<MaterialSummaryResponse> content = materials.getContent().stream()
            .map(materialMapper::toSummaryResponse)
            .collect(Collectors.toList());

        return buildPagedResponse(content, materials, pageable);
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<MaterialSummaryResponse> getByGroup(UUID groupId, Pageable pageable) {
        Page<Material> materials = materialRepository.findByGroupId(groupId, pageable);

        List<MaterialSummaryResponse> content = materials.getContent().stream()
            .map(materialMapper::toSummaryResponse)
            .collect(Collectors.toList());

        return buildPagedResponse(content, materials, pageable);
    }

    @Override
    public MaterialResponse incrementDownload(UUID id) {
        Material material = materialRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Material", "id", id));

        material.setDownloadCount(material.getDownloadCount() + 1);
        material = materialRepository.save(material);

        log.info("Download count incremented for material: {} (total: {})", id, material.getDownloadCount());
        return enrichResponse(material);
    }

    @Override
    @Transactional(readOnly = true)
    public List<MaterialSummaryResponse> getPopular(int limit) {
        Pageable pageable = PageRequest.of(0, limit);
        List<Material> materials = materialRepository.findPopular(pageable);

        return materials.stream()
            .map(materialMapper::toSummaryResponse)
            .collect(Collectors.toList());
    }

    private MaterialResponse enrichResponse(Material material) {
        MaterialResponse response = materialMapper.toResponse(material);
        if (response == null) {
            response = new MaterialResponse();
        }
        response.setId(material.getId());
        response.setTitle(material.getTitle());
        response.setDescription(material.getDescription());
        response.setType(material.getType());
        response.setUrl(material.getUrl());
        response.setFileSize(material.getFileSize());
        response.setFileType(material.getFileType());
        response.setUploaderId(material.getUploaderId());
        response.setGroupId(material.getGroupId());
        response.setTags(material.getTags());
        response.setDownloadCount(material.getDownloadCount());
        response.setPublic(material.isPublic());
        response.setCreatedAt(material.getCreatedAt());
        response.setUpdatedAt(material.getUpdatedAt());
        return response;
    }

    private <T> PagedResponse<T> buildPagedResponse(List<T> content, Page<?> page, Pageable pageable) {
        return PagedResponse.<T>builder()
            .content(content)
            .page(pageable.getPageNumber())
            .size(pageable.getPageSize())
            .totalElements(page.getTotalElements())
            .totalPages(page.getTotalPages())
            .last(page.isLast())
            .build();
    }
}
