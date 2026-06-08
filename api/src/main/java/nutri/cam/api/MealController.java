package nutri.cam.api;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/meals")
@CrossOrigin(origins = "*")
public class MealController {

    private final MealRepository mealRepository;
    private final RecommendedPlateRepository
        recommendedPlateRepository;

    public MealController(
        MealRepository mealRepository,
        RecommendedPlateRepository recommendedPlateRepository
    ) {
        this.mealRepository = mealRepository;
        this.recommendedPlateRepository =
            recommendedPlateRepository;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Meal createMeal(
        @RequestBody MealRequest request
    ) {
        validateRequest(request);

        Meal meal = new Meal();

        meal.setUserId(request.getUserId());
        meal.setMealName(request.getMealName().trim());
        meal.setMealType(request.getMealType().trim());
        meal.setQuantity(request.getQuantity().trim());
        meal.setMealDate(LocalDate.now());

        MealRegistrationSource registrationSource =
            request.getRegistrationSource() == null
                ? MealRegistrationSource.MANUAL
                : request.getRegistrationSource();

        meal.setRegistrationSource(registrationSource);

        Set<FoodGroup> foodGroups = request.getFoodGroups() == null
            ? new HashSet<>()
            : new HashSet<>(request.getFoodGroups());

        if (request.getRecommendedPlateId() != null) {
            RecommendedPlate recommendedPlate =
                recommendedPlateRepository
                    .findById(request.getRecommendedPlateId())
                    .orElseThrow(
                        () -> new ResponseStatusException(
                            HttpStatus.BAD_REQUEST,
                            "El plato recomendado no existe."
                        )
                    );

            if (!Boolean.TRUE.equals(
                recommendedPlate.getActive()
            )) {
                throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El plato recomendado no está activo."
                );
            }

            meal.setRecommendedPlate(recommendedPlate);

            if (foodGroups.isEmpty()) {
                foodGroups.addAll(
                    recommendedPlate.getFoodGroups()
                );
            }
        }

        meal.setFoodGroups(foodGroups);

        return mealRepository.save(meal);
    }

    @GetMapping("/user/{userId}")
    public List<Meal> getMealsByUser(
        @PathVariable Integer userId
    ) {
        return mealRepository
            .findByUserIdOrderByMealDateDescIdDesc(userId);
    }

    private void validateRequest(MealRequest request) {
        if (request == null) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "La solicitud es obligatoria."
            );
        }

        if (request.getUserId() == null) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El usuario es obligatorio."
            );
        }

        if (isBlank(request.getMealName())) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El nombre de la comida es obligatorio."
            );
        }

        if (isBlank(request.getMealType())) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El tipo de comida es obligatorio."
            );
        }

        if (isBlank(request.getQuantity())) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "La cantidad es obligatoria."
            );
        }

        if (
            request.getRegistrationSource()
                == MealRegistrationSource.PLAN
            && request.getRecommendedPlateId() == null
        ) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "Un registro proveniente del plan debe indicar "
                    + "el plato recomendado."
            );
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}