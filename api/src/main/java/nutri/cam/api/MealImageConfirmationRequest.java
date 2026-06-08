package nutri.cam.api;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MealImageConfirmationRequest {

    private Integer userId;

    private String mealName;

    private String mealType;

    private String quantity;

    private LocalDate mealDate;

    private Set<FoodGroup> foodGroups =
        new HashSet<>();
}