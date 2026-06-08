package nutri.cam.api;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class RecommendedPlateDataInitializer implements CommandLineRunner {

    private static final String SOURCE = "CATALOGO_NUTRICAM";

    private final RecommendedPlateRepository recommendedPlateRepository;

    public RecommendedPlateDataInitializer(
            RecommendedPlateRepository recommendedPlateRepository) {
        this.recommendedPlateRepository = recommendedPlateRepository;
    }

    @Override
    public void run(String... args) {

        if (recommendedPlateRepository.count() > 0) {
            return;
        }

        List<RecommendedPlate> plates = new ArrayList<>();

        plates.add(createPlate(
                "Yogur con avena y banana",
                "Yogur natural acompañado con avena y banana fresca.",
                "1 yogur, 3 cucharadas de avena y 1 banana pequeña",
                320,
                12.0,
                5,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.DESAYUNO,
                        PlateMealType.MERIENDA
                ),
                Set.of(
                        FoodGroup.LECHE_YOGUR_Y_QUESO,
                        FoodGroup.CEREALES_Y_DERIVADOS,
                        FoodGroup.FRUTAS
                )
        ));

        plates.add(createPlate(
                "Tostadas integrales con queso y fruta",
                "Tostadas de pan integral con queso fresco y una fruta de estación.",
                "2 tostadas integrales, 1 porción de queso y 1 fruta",
                350,
                14.0,
                10,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.DESAYUNO,
                        PlateMealType.MERIENDA
                ),
                Set.of(
                        FoodGroup.CEREALES_Y_DERIVADOS,
                        FoodGroup.LECHE_YOGUR_Y_QUESO,
                        FoodGroup.FRUTAS
                )
        ));

        plates.add(createPlate(
                "Avena cocida con manzana",
                "Avena cocida con leche y acompañada con manzana fresca.",
                "1 taza de avena cocida y 1 manzana pequeña",
                310,
                11.0,
                12,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.DESAYUNO,
                        PlateMealType.MERIENDA
                ),
                Set.of(
                        FoodGroup.CEREALES_Y_DERIVADOS,
                        FoodGroup.LECHE_YOGUR_Y_QUESO,
                        FoodGroup.FRUTAS
                )
        ));

        plates.add(createPlate(
                "Licuado de leche, banana y avena",
                "Licuado preparado con leche, banana fresca y avena.",
                "1 vaso grande",
                330,
                13.0,
                5,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.DESAYUNO,
                        PlateMealType.MERIENDA
                ),
                Set.of(
                        FoodGroup.LECHE_YOGUR_Y_QUESO,
                        FoodGroup.FRUTAS,
                        FoodGroup.CEREALES_Y_DERIVADOS
                )
        ));

        plates.add(createPlate(
                "Pan integral con huevo revuelto",
                "Pan integral acompañado con huevo revuelto.",
                "2 rebanadas de pan integral y 1 huevo",
                300,
                15.0,
                10,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.DESAYUNO,
                        PlateMealType.MERIENDA
                ),
                Set.of(
                        FoodGroup.CEREALES_Y_DERIVADOS,
                        FoodGroup.HUEVOS
                )
        ));

        plates.add(createPlate(
                "Yogur con frutas y semillas",
                "Yogur natural con frutas frescas y una pequeña porción de semillas.",
                "1 yogur, 1 porción de fruta y 1 cucharada de semillas",
                290,
                11.0,
                5,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.DESAYUNO,
                        PlateMealType.MERIENDA
                ),
                Set.of(
                        FoodGroup.LECHE_YOGUR_Y_QUESO,
                        FoodGroup.FRUTAS,
                        FoodGroup.FRUTOS_SECOS_Y_SEMILLAS
                )
        ));

        plates.add(createPlate(
                "Pollo al horno con batata y ensalada",
                "Pollo al horno acompañado con batata asada y ensalada de vegetales frescos.",
                "1 porción de pollo, 1 batata pequeña y 1 plato de ensalada",
                520,
                38.0,
                45,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.ALMUERZO,
                        PlateMealType.CENA
                ),
                Set.of(
                        FoodGroup.CARNES,
                        FoodGroup.PAPA_BATATA_MANDIOCA,
                        FoodGroup.VERDURAS
                )
        ));

        plates.add(createPlate(
                "Pescado al horno con arroz integral y vegetales",
                "Filete de pescado al horno acompañado con arroz integral y vegetales.",
                "1 filete, media taza de arroz integral y 1 porción de vegetales",
                500,
                35.0,
                40,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.ALMUERZO,
                        PlateMealType.CENA
                ),
                Set.of(
                        FoodGroup.PESCADOS,
                        FoodGroup.CEREALES_Y_DERIVADOS,
                        FoodGroup.VERDURAS
                )
        ));

        plates.add(createPlate(
                "Ensalada de lentejas y vegetales",
                "Ensalada preparada con lentejas cocidas y vegetales frescos variados.",
                "1 plato mediano",
                420,
                20.0,
                25,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.ALMUERZO,
                        PlateMealType.CENA
                ),
                Set.of(
                        FoodGroup.LEGUMBRES,
                        FoodGroup.VERDURAS
                )
        ));

        plates.add(createPlate(
                "Tarta casera de verduras",
                "Tarta casera rellena con verduras y huevo.",
                "1 porción de tarta acompañada con ensalada",
                460,
                18.0,
                50,
                ProcessingLevel.PROCESADO,
                Set.of(
                        PlateMealType.ALMUERZO,
                        PlateMealType.CENA
                ),
                Set.of(
                        FoodGroup.CEREALES_Y_DERIVADOS,
                        FoodGroup.VERDURAS,
                        FoodGroup.HUEVOS
                )
        ));

        plates.add(createPlate(
                "Carne magra con puré de calabaza",
                "Carne magra cocida acompañada con puré casero de calabaza.",
                "1 porción de carne y 1 taza de puré de calabaza",
                510,
                37.0,
                40,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.ALMUERZO,
                        PlateMealType.CENA
                ),
                Set.of(
                        FoodGroup.CARNES,
                        FoodGroup.VERDURAS
                )
        ));

        plates.add(createPlate(
                "Arroz integral con vegetales y huevo",
                "Arroz integral salteado con vegetales variados y huevo.",
                "1 plato mediano",
                470,
                19.0,
                30,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.ALMUERZO,
                        PlateMealType.CENA
                ),
                Set.of(
                        FoodGroup.CEREALES_Y_DERIVADOS,
                        FoodGroup.VERDURAS,
                        FoodGroup.HUEVOS
                )
        ));

        plates.add(createPlate(
                "Guiso de lentejas con verduras",
                "Guiso casero de lentejas preparado con verduras variadas.",
                "1 plato mediano",
                480,
                23.0,
                50,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.ALMUERZO,
                        PlateMealType.CENA
                ),
                Set.of(
                        FoodGroup.LEGUMBRES,
                        FoodGroup.VERDURAS
                )
        ));

        plates.add(createPlate(
                "Omelette de verduras con ensalada",
                "Omelette preparado con huevo y verduras, acompañado con ensalada fresca.",
                "1 omelette de 2 huevos y 1 porción de ensalada",
                390,
                22.0,
                20,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.ALMUERZO,
                        PlateMealType.CENA
                ),
                Set.of(
                        FoodGroup.HUEVOS,
                        FoodGroup.VERDURAS
                )
        ));

        plates.add(createPlate(
                "Pasta integral con salsa de tomate casera",
                "Pasta integral acompañada con salsa casera de tomate y vegetales.",
                "1 plato mediano",
                490,
                17.0,
                30,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.ALMUERZO,
                        PlateMealType.CENA
                ),
                Set.of(
                        FoodGroup.CEREALES_Y_DERIVADOS,
                        FoodGroup.VERDURAS
                )
        ));

        plates.add(createPlate(
                "Hamburguesa casera de lentejas con ensalada",
                "Hamburguesa elaborada con lentejas, acompañada con ensalada fresca.",
                "1 hamburguesa mediana y 1 plato de ensalada",
                430,
                21.0,
                40,
                ProcessingLevel.MINIMAMENTE_PROCESADO,
                Set.of(
                        PlateMealType.ALMUERZO,
                        PlateMealType.CENA
                ),
                Set.of(
                        FoodGroup.LEGUMBRES,
                        FoodGroup.CEREALES_Y_DERIVADOS,
                        FoodGroup.VERDURAS
                )
        ));

        recommendedPlateRepository.saveAll(plates);

        System.out.println(
                "Catálogo inicial de platos cargado: "
                        + plates.size()
                        + " platos."
        );
    }

    private RecommendedPlate createPlate(
            String name,
            String description,
            String portion,
            Integer estimatedCalories,
            Double estimatedProtein,
            Integer preparationTimeMinutes,
            ProcessingLevel processingLevel,
            Set<PlateMealType> allowedMealTypes,
            Set<FoodGroup> foodGroups) {

        RecommendedPlate plate = new RecommendedPlate();

        plate.setName(name);
        plate.setDescription(description);
        plate.setPortion(portion);
        plate.setEstimatedCalories(estimatedCalories);
        plate.setEstimatedProtein(estimatedProtein);
        plate.setPreparationTimeMinutes(preparationTimeMinutes);
        plate.setProcessingLevel(processingLevel);
        plate.setActive(true);
        plate.setSource(SOURCE);

        plate.setAllowedMealTypes(new HashSet<>(allowedMealTypes));
        plate.setFoodGroups(new HashSet<>(foodGroups));

        return plate;
    }
}