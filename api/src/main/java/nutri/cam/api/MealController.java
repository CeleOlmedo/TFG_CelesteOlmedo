package nutri.cam.api;

import java.time.LocalDate;
import java.util.List;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/meals")
@CrossOrigin(origins = "*")
public class MealController {

    private final MealRepository mealRepository;

    public MealController(MealRepository mealRepository) {
        this.mealRepository = mealRepository;
    }

    @PostMapping
    public Meal createMeal(@RequestBody Meal meal) {
        meal.setMealDate(LocalDate.now());
        return mealRepository.save(meal);
    }

    @GetMapping("/user/{userId}")
    public List<Meal> getMealsByUser(
            @PathVariable Integer userId) {

        return mealRepository
                .findByUserIdOrderByMealDateDescIdDesc(userId);
    }
}