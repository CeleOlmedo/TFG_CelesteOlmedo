package nutri.cam.api;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "nutrition_plan")
@Getter
@Setter
public class NutritionPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
        name = "user_id",
        nullable = false
    )
    private User user;

    @Column(
        name = "start_date",
        nullable = false
    )
    private LocalDate startDate;

    @Column(
        name = "end_date",
        nullable = false
    )
    private LocalDate endDate;

    @Column(
        name = "user_objective",
        nullable = false,
        length = 50
    )
    private String userObjective;

    @Enumerated(EnumType.STRING)
    @Column(
        nullable = false,
        length = 20
    )
    private NutritionPlanStatus status;

    @Enumerated(EnumType.STRING)
    @Column(
        name = "generation_method",
        nullable = false,
        length = 30
    )
    private NutritionPlanGenerationMethod generationMethod;

    @Column(
        name = "created_at",
        nullable = false,
        updatable = false
    )
    private LocalDateTime createdAt;

    @Column(
        name = "updated_at",
        nullable = false
    )
    private LocalDateTime updatedAt;

    @OneToMany(
        mappedBy = "nutritionPlan",
        cascade = CascadeType.ALL,
        orphanRemoval = true
    )
    @OrderBy("displayOrder ASC")
    private List<NutritionPlanDay> days = new ArrayList<>();

    public void addDay(NutritionPlanDay day) {
        days.add(day);
        day.setNutritionPlan(this);
    }

    public void removeDay(NutritionPlanDay day) {
        days.remove(day);
        day.setNutritionPlan(null);
    }

    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();

        createdAt = now;
        updatedAt = now;

        if (status == null) {
            status = NutritionPlanStatus.ACTIVE;
        }

        if (generationMethod == null) {
            generationMethod =
                NutritionPlanGenerationMethod.RULES;
        }
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}