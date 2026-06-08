package nutri.cam.api;

import java.time.LocalDate;
import java.time.LocalDateTime;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class DailyRecommendationResponse {

    private Integer planDayId;

    private LocalDate planDate;

    private String recommendation;

    private DailyRecommendationStatus status;

    private DailyRecommendationMethod method;

    private LocalDateTime generatedAt;
}