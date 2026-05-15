package com.pitaya.library.controller;

import com.pitaya.library.dto.request.CreateMaterialRequest;
import com.pitaya.library.dto.request.MaterialFilterRequest;
import com.pitaya.library.dto.request.UpdateMaterialRequest;
import com.pitaya.library.dto.response.MaterialResponse;
import com.pitaya.library.dto.response.MaterialSummaryResponse;
import com.pitaya.library.service.LibraryService;
import com.pitaya.shared.dto.ApiResponse;
import com.pitaya.shared.dto.PagedResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/library")
public class LibraryController {

    private final LibraryService libraryService;

    public LibraryController(LibraryService libraryService) {
        this.libraryService = libraryService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<MaterialResponse>> createMaterial(
            @RequestHeader("X-User-Id") UUID userId,
            @Valid @RequestBody CreateMaterialRequest request) {
        MaterialResponse response = libraryService.create(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success("Material created successfully", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MaterialResponse>> getMaterial(@PathVariable UUID id) {
        MaterialResponse response = libraryService.findById(id);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<MaterialResponse>> updateMaterial(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") UUID userId,
            @Valid @RequestBody UpdateMaterialRequest request) {
        MaterialResponse response = libraryService.update(id, userId, request);
        return ResponseEntity.ok(ApiResponse.success("Material updated successfully", response));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteMaterial(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") UUID userId) {
        libraryService.delete(id, userId);
        return ResponseEntity.ok(ApiResponse.<Void>success("Material deleted successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<MaterialSummaryResponse>>> listMaterials(
            @RequestParam(required = false) String type,
            @RequestParam(required = false) UUID groupId,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) List<String> tags,
            @RequestParam(required = false) Boolean isPublic,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        Sort sort = sortDir.equalsIgnoreCase("asc") ? Sort.by(sortBy).ascending() : Sort.by(sortBy).descending();
        Pageable pageable = PageRequest.of(page, size, sort);

        MaterialFilterRequest filter = MaterialFilterRequest.builder()
            .type(type != null ? com.pitaya.library.enums.MaterialType.valueOf(type.toUpperCase()) : null)
            .groupId(groupId)
            .search(search)
            .tags(tags)
            .isPublic(isPublic)
            .build();

        PagedResponse<MaterialSummaryResponse> response = libraryService.list(filter, pageable);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/uploader/{userId}")
    public ResponseEntity<ApiResponse<PagedResponse<MaterialSummaryResponse>>> getByUploader(
            @PathVariable UUID userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        Sort sort = sortDir.equalsIgnoreCase("asc") ? Sort.by(sortBy).ascending() : Sort.by(sortBy).descending();
        Pageable pageable = PageRequest.of(page, size, sort);
        PagedResponse<MaterialSummaryResponse> response = libraryService.getByUploader(userId, pageable);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/group/{groupId}")
    public ResponseEntity<ApiResponse<PagedResponse<MaterialSummaryResponse>>> getByGroup(
            @PathVariable UUID groupId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        Sort sort = sortDir.equalsIgnoreCase("asc") ? Sort.by(sortBy).ascending() : Sort.by(sortBy).descending();
        Pageable pageable = PageRequest.of(page, size, sort);
        PagedResponse<MaterialSummaryResponse> response = libraryService.getByGroup(groupId, pageable);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/{id}/download")
    public ResponseEntity<ApiResponse<MaterialResponse>> incrementDownload(@PathVariable UUID id) {
        MaterialResponse response = libraryService.incrementDownload(id);
        return ResponseEntity.ok(ApiResponse.success("Download count incremented", response));
    }

    @GetMapping("/popular")
    public ResponseEntity<ApiResponse<List<MaterialSummaryResponse>>> getPopular(
            @RequestParam(defaultValue = "10") int limit) {
        List<MaterialSummaryResponse> response = libraryService.getPopular(limit);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
