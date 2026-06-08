package nutri.cam.api;

import java.time.LocalDateTime;
import java.util.Set;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MealImageAnalysisResponse {

    private Integer id;

    private Integer userId;

    private String suggestedMealName;

    private Set<String> detectedFoods;

    private Set<FoodGroup> foodGroups;

    private MealImageAnalysisStatus status;

    private String warning;

    private LocalDateTime createdAt;

    private LocalDateTime confirmedAt;

    private Integer mealId;
}