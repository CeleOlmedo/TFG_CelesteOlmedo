package nutri.cam.api;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/nutrition-plans")
@CrossOrigin(origins = "*")
public class NutritionPlanController {

    private final NutritionPlanService nutritionPlanService;

    private final DailyRecommendationService
        dailyRecommendationService;

    public NutritionPlanController(
        NutritionPlanService nutritionPlanService,
        DailyRecommendationService dailyRecommendationService
    ) {
        this.nutritionPlanService =
            nutritionPlanService;

        this.dailyRecommendationService =
            dailyRecommendationService;
    }

    @PostMapping("/generate/user/{userId}")
    @ResponseStatus(HttpStatus.CREATED)
    public NutritionPlanResponse generateWeeklyPlan(
        @PathVariable Integer userId
    ) {
        return nutritionPlanService
            .generateWeeklyPlan(userId);
    }

    @GetMapping("/active/user/{userId}")
    public NutritionPlanResponse getActivePlan(
        @PathVariable Integer userId
    ) {
        return nutritionPlanService
            .getActivePlan(userId);
    }

    @PutMapping(
        "/active/user/{userId}/meals/{mealId}/replace"
    )
    public NutritionPlanResponse replacePlanMeal(
        @PathVariable Integer userId,
        @PathVariable Integer mealId
    ) {
        return nutritionPlanService.replacePlanMeal(
            userId,
            mealId
        );
    }

    @PostMapping(
        "/daily-recommendation/user/{userId}"
    )
    public DailyRecommendationResponse
            generateOrGetDailyRecommendation(
                @PathVariable Integer userId
            ) {

        return dailyRecommendationService
            .generateOrGetTodayRecommendation(
                userId
            );
    }
}