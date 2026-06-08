package nutri.cam.api;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface MealImageAnalysisRepository
        extends JpaRepository<MealImageAnalysis, Integer> {

    Optional<MealImageAnalysis>
        findByIdAndUserId(
            Integer id,
            Integer userId
        );

    List<MealImageAnalysis>
        findByUserIdOrderByCreatedAtDesc(
            Integer userId
        );
}