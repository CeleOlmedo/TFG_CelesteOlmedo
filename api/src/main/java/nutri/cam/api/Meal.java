package nutri.cam.api;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "meal")
@Getter
@Setter
public class Meal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(
        name = "user_id",
        nullable = false
    )
    private Integer userId;

    @Column(
        name = "meal_name",
        nullable = false,
        length = 200
    )
    private String mealName;

    @Column(
        name = "meal_type",
        nullable = false,
        length = 50
    )
    private String mealType;

    @Column(
        nullable = false,
        length = 100
    )
    private String quantity;

    @Column(
        name = "meal_date",
        nullable = false
    )
    private LocalDate mealDate;

    @Enumerated(EnumType.STRING)
    @Column(
        name = "registration_source",
        nullable = false,
        length = 20
    )
    private MealRegistrationSource registrationSource;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(
        name = "recommended_plate_id"
    )
    private RecommendedPlate recommendedPlate;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
        name = "meal_food_group",
        joinColumns = @JoinColumn(name = "meal_id")
    )
    @Enumerated(EnumType.STRING)
    @Column(
        name = "food_group",
        nullable = false,
        length = 50
    )
    private Set<FoodGroup> foodGroups = new HashSet<>();

    @PrePersist
    public void prePersist() {
        if (mealDate == null) {
            mealDate = LocalDate.now();
        }

        if (registrationSource == null) {
            registrationSource =
                MealRegistrationSource.MANUAL;
        }
    }
}