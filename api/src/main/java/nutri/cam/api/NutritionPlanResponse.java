package nutri.cam.api;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class NutritionPlanResponse {

    private Integer id;

    private Integer userId;

    private LocalDate startDate;

    private LocalDate endDate;

    private String userObjective;

    private NutritionPlanStatus status;

    private NutritionPlanGenerationMethod generationMethod;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    private List<NutritionPlanDayResponse> days =
        new ArrayList<>();
}