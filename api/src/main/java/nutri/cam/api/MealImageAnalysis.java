package nutri.cam.api;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "meal_image_analysis")
@Getter
@Setter
public class MealImageAnalysis {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(
        name = "user_id",
        nullable = false
    )
    private Integer userId;

    @Column(
        name = "original_file_name",
        nullable = false,
        length = 255
    )
    private String originalFileName;

    @Column(
        name = "content_type",
        nullable = false,
        length = 100
    )
    private String contentType;

    @Column(
        name = "file_size",
        nullable = false
    )
    private Long fileSize;

    @Column(
        name = "suggested_meal_name",
        length = 200
    )
    private String suggestedMealName;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
        name = "meal_image_detected_food",
        joinColumns = @JoinColumn(
            name = "analysis_id"
        )
    )
    @Column(
        name = "detected_food",
        nullable = false,
        length = 150
    )
    private Set<String> detectedFoods =
        new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
        name = "meal_image_food_group",
        joinColumns = @JoinColumn(
            name = "analysis_id"
        )
    )
    @Enumerated(EnumType.STRING)
    @Column(
        name = "food_group",
        nullable = false,
        length = 50
    )
    private Set<FoodGroup> foodGroups =
        new HashSet<>();

    @Enumerated(EnumType.STRING)
    @Column(
        nullable = false,
        length = 20
    )
    private MealImageAnalysisStatus status;

    @Column(
        length = 500
    )
    private String warning;

    @Column(
        name = "created_at",
        nullable = false
    )
    private LocalDateTime createdAt;

    @Column(
        name = "confirmed_at"
    )
    private LocalDateTime confirmedAt;

    @OneToOne(fetch = FetchType.EAGER)
    @JoinColumn(
        name = "meal_id",
        unique = true
    )
    private Meal meal;

    @PrePersist
    public void prePersist() {
        if (status == null) {
            status = MealImageAnalysisStatus.PENDING;
        }

        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}