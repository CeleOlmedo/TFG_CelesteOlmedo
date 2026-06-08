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
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(
    name = "nutrition_plan_day",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_plan_day_date",
            columnNames = {
                "nutrition_plan_id",
                "plan_date"
            }
        ),
        @UniqueConstraint(
            name = "uk_plan_day_order",
            columnNames = {
                "nutrition_plan_id",
                "display_order"
            }
        )
    }
)
@Getter
@Setter
public class NutritionPlanDay {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
        name = "nutrition_plan_id",
        nullable = false
    )
    private NutritionPlan nutritionPlan;

    @Column(
        name = "plan_date",
        nullable = false
    )
    private LocalDate planDate;

    @Column(
        name = "display_order",
        nullable = false
    )
    private Integer displayOrder;

    @Column(
        name = "daily_recommendation",
        length = 1000
    )
    private String dailyRecommendation;

    @Enumerated(EnumType.STRING)
    @Column(
        name = "recommendation_status",
        nullable = false,
        length = 20
    )
    private DailyRecommendationStatus recommendationStatus =
        DailyRecommendationStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(
        name = "recommendation_method",
        length = 30
    )
    private DailyRecommendationMethod recommendationMethod;

    @Column(
        name = "recommendation_generated_at"
    )
    private LocalDateTime recommendationGeneratedAt;

    @OneToMany(
        mappedBy = "nutritionPlanDay",
        cascade = CascadeType.ALL,
        orphanRemoval = true
    )
    @OrderBy("displayOrder ASC")
    private List<NutritionPlanMeal> meals = new ArrayList<>();

    public void addMeal(NutritionPlanMeal meal) {
        meals.add(meal);
        meal.setNutritionPlanDay(this);
    }

    public void removeMeal(NutritionPlanMeal meal) {
        meals.remove(meal);
        meal.setNutritionPlanDay(null);
    }
}