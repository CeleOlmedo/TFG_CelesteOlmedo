package nutri.cam.api;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface MealRepository extends JpaRepository<Meal, Integer> {

    List<Meal> findByUserIdOrderByMealDateDescIdDesc(Integer userId);
}