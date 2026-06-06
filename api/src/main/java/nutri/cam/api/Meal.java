package nutri.cam.api;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

@Entity
@Data
public class Meal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private Integer userId;

    private String mealName;

    private String mealType;

    private String quantity;

    private LocalDate mealDate;
}