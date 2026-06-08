package nutri.cam.api;

import java.util.HashSet;
import java.util.Set;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class NutritionPlanMealResponse {

    private Integer id;

    private PlateMealType mealType;

    private Integer recommendedPlateId;

    private String plateName;

    private String description;

    private String portion;

    private Integer estimatedCalories;

    private Double estimatedProtein;

    private Integer preparationTimeMinutes;

    private ProcessingLevel processingLevel;

    private Set<FoodGroup> foodGroups =
        new HashSet<>();

    private String reason;

    private Integer displayOrder;
}