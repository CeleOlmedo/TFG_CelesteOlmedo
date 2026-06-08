package nutri.cam.api;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface NutritionPlanDayRepository
        extends JpaRepository<NutritionPlanDay, Integer> {

    List<NutritionPlanDay>
            findByNutritionPlanIdOrderByDisplayOrderAsc(
                Integer nutritionPlanId
            );

    Optional<NutritionPlanDay>
            findByNutritionPlanIdAndPlanDate(
                Integer nutritionPlanId,
                LocalDate planDate
            );

    Optional<NutritionPlanDay>
            findFirstByNutritionPlanUserIdAndPlanDateAndNutritionPlanStatus(
                Integer userId,
                LocalDate planDate,
                NutritionPlanStatus status
            );
}