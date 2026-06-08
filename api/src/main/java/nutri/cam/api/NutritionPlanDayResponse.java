package nutri.cam.api;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class NutritionPlanDayResponse {

    private Integer id;

    private LocalDate planDate;

    private Integer displayOrder;

    private String dailyRecommendation;

    private DailyRecommendationStatus recommendationStatus;

    private DailyRecommendationMethod recommendationMethod;

    private LocalDateTime recommendationGeneratedAt;

    private List<NutritionPlanMealResponse> meals =
        new ArrayList<>();
}