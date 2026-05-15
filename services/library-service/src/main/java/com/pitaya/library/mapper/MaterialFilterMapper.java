package com.pitaya.library.mapper;

import com.pitaya.library.dto.request.MaterialFilterRequest;
import jakarta.persistence.criteria.CriteriaBuilder;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import com.pitaya.library.entity.Material;

import java.util.ArrayList;
import java.util.List;

@Component
public class MaterialFilterMapper {

    public Specification<Material> toSpecification(MaterialFilterRequest filter) {
        return (Root<Material> root, CriteriaQuery<?> query, CriteriaBuilder cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (filter.getType() != null) {
                predicates.add(cb.equal(root.get("type"), filter.getType()));
            }

            if (filter.getGroupId() != null) {
                predicates.add(cb.equal(root.get("groupId"), filter.getGroupId()));
            }

            if (filter.getSearch() != null && !filter.getSearch().isBlank()) {
                String pattern = "%" + filter.getSearch().toLowerCase() + "%";
                predicates.add(cb.or(
                    cb.like(cb.lower(root.get("title")), pattern),
                    cb.like(cb.lower(root.get("description")), pattern)
                ));
            }

            if (filter.getTags() != null && !filter.getTags().isEmpty()) {
                predicates.add(cb.and(
                    filter.getTags().stream()
                        .map(tag -> cb.isTrue(
                            cb.function("array_position", Boolean.class,
                                root.get("tags"), cb.literal(tag))
                        ))
                        .toArray(Predicate[]::new)
                ));
            }

            if (filter.getIsPublic() != null) {
                predicates.add(cb.equal(root.get("isPublic"), filter.getIsPublic()));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
