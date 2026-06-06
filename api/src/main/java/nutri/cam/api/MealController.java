package nutri.cam.api;

import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

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
    public List<Meal> getMealsByUser(@PathVariable Integer userId) {
        return mealRepository.findByUserId(userId);
    }
}