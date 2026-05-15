package com.pitaya.library.repository;

import com.pitaya.library.entity.Material;
import com.pitaya.library.enums.MaterialType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MaterialRepository extends JpaRepository<Material, UUID>, JpaSpecificationExecutor<Material> {

    Page<Material> findByType(MaterialType type, Pageable pageable);

    Page<Material> findByGroupId(UUID groupId, Pageable pageable);

    Page<Material> findByUploaderId(UUID uploaderId, Pageable pageable);

    Page<Material> findByGroupIdAndIsPublicTrue(UUID groupId, Pageable pageable);

    Page<Material> findByUploaderIdAndIsPublicTrue(UUID uploaderId, Pageable pageable);

    @Query("SELECT m FROM Material m WHERE " +
           "LOWER(m.title) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(m.description) LIKE LOWER(CONCAT('%', :search, '%'))")
    Page<Material> searchByTitleOrDescription(@Param("search") String search, Pageable pageable);

    @Query(value = "SELECT * FROM materials WHERE :tag = ANY(tags)", nativeQuery = true)
    List<Material> findByTag(@Param("tag") String tag);

    @Query(value = "SELECT * FROM materials WHERE tags @> CAST(:tags AS TEXT[])", nativeQuery = true)
    List<Material> findByTagsAll(@Param("tags") String[] tags);

    long countByUploaderId(UUID uploaderId);

    @Query("SELECT m FROM Material m WHERE m.isPublic = true ORDER BY m.downloadCount DESC")
    List<Material> findPopular(Pageable pageable);

    @Query("SELECT m FROM Material m WHERE m.groupId = :groupId AND m.isPublic = true " +
           "AND (LOWER(m.title) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           "LOWER(m.description) LIKE LOWER(CONCAT('%', :search, '%')))")
    Page<Material> searchByGroup(@Param("groupId") UUID groupId, @Param("search") String search, Pageable pageable);
}
