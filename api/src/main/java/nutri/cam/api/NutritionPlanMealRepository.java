package nutri.cam.api;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface NutritionPlanMealRepository
        extends JpaRepository<NutritionPlanMeal, Integer> {

    List<NutritionPlanMeal>
            findByNutritionPlanDayIdOrderByDisplayOrderAsc(
                Integer nutritionPlanDayId
            );

    Optional<NutritionPlanMeal>
            findByNutritionPlanDayIdAndMealType(
                Integer nutritionPlanDayId,
                PlateMealType mealType
            );

    long countByNutritionPlanDayId(
        Integer nutritionPlanDayId
    );
}