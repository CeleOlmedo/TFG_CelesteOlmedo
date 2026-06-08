package nutri.cam.api;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface NutritionPlanRepository
        extends JpaRepository<NutritionPlan, Integer> {

    Optional<NutritionPlan>
            findFirstByUserIdAndStatusOrderByCreatedAtDesc(
                Integer userId,
                NutritionPlanStatus status
            );

    List<NutritionPlan>
            findByUserIdAndStatusOrderByCreatedAtDesc(
                Integer userId,
                NutritionPlanStatus status
            );

    List<NutritionPlan>
            findByUserIdOrderByCreatedAtDesc(
                Integer userId
            );

    Optional<NutritionPlan>
            findFirstByUserIdAndStartDateLessThanEqualAndEndDateGreaterThanEqualAndStatusOrderByCreatedAtDesc(
                Integer userId,
                LocalDate dateFrom,
                LocalDate dateTo,
                NutritionPlanStatus status
            );

    boolean existsByUserIdAndStatus(
        Integer userId,
        NutritionPlanStatus status
    );
}