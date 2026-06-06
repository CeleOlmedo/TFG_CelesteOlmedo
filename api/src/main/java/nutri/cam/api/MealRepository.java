package nutri.cam.api;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface MealRepository extends JpaRepository<Meal, Integer> {

    List<Meal> findByUserId(Integer userId);

}