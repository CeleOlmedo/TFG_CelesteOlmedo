package nutri.cam.api;

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
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "recommended_plate")
@Data
public class RecommendedPlate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, unique = true, length = 150)
    private String name;

    @Column(nullable = false, length = 500)
    private String description;

    @Column(nullable = false, length = 200)
    private String portion;

    @Column(name = "estimated_calories")
    private Integer estimatedCalories;

    @Column(name = "estimated_protein")
    private Double estimatedProtein;

    @Column(name = "preparation_time_minutes")
    private Integer preparationTimeMinutes;

    @Enumerated(EnumType.STRING)
    @Column(name = "processing_level", nullable = false, length = 50)
    private ProcessingLevel processingLevel;

    @Column(nullable = false)
    private Boolean active = true;

    @Column(nullable = false, length = 100)
    private String source;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
        name = "recommended_plate_meal_type",
        joinColumns = @JoinColumn(name = "recommended_plate_id")
    )
    @Enumerated(EnumType.STRING)
    @Column(name = "meal_type", nullable = false, length = 50)
    private Set<PlateMealType> allowedMealTypes = new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(
        name = "recommended_plate_food_group",
        joinColumns = @JoinColumn(name = "recommended_plate_id")
    )
    @Enumerated(EnumType.STRING)
    @Column(name = "food_group", nullable = false, length = 50)
    private Set<FoodGroup> foodGroups = new HashSet<>();
}