package nutri.cam.api;

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
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(
    name = "nutrition_plan_meal",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_plan_day_meal_type",
            columnNames = {
                "nutrition_plan_day_id",
                "meal_type"
            }
        ),
        @UniqueConstraint(
            name = "uk_plan_day_meal_order",
            columnNames = {
                "nutrition_plan_day_id",
                "display_order"
            }
        )
    }
)
@Getter
@Setter
public class NutritionPlanMeal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
        name = "nutrition_plan_day_id",
        nullable = false
    )
    private NutritionPlanDay nutritionPlanDay;

    @Enumerated(EnumType.STRING)
    @Column(
        name = "meal_type",
        nullable = false,
        length = 50
    )
    private PlateMealType mealType;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
        name = "recommended_plate_id",
        nullable = false
    )
    private RecommendedPlate recommendedPlate;

    @Column(
        nullable = false,
        length = 500
    )
    private String reason;

    @Column(
        name = "display_order",
        nullable = false
    )
    private Integer displayOrder;
}