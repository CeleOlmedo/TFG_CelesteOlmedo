package nutri.cam.api;

import java.util.HashSet;
import java.util.Set;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MealRequest {

    private Integer userId;

    private String mealName;

    private String mealType;

    private String quantity;

    private MealRegistrationSource registrationSource;

    private Integer recommendedPlateId;

    private Set<FoodGroup> foodGroups = new HashSet<>();
}