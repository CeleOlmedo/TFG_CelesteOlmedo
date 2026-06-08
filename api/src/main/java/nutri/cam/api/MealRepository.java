package nutri.cam.api;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface MealRepository
        extends JpaRepository<Meal, Integer> {

    List<Meal>
        findByUserIdOrderByMealDateDescIdDesc(
            Integer userId
        );

    List<Meal>
        findByUserIdAndMealDateOrderByIdAsc(
            Integer userId,
            LocalDate mealDate
        );
}