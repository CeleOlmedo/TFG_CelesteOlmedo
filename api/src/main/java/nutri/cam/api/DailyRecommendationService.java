package nutri.cam.api;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.openai.client.OpenAIClient;
import com.openai.models.responses.ResponseCreateParams;
import com.openai.models.responses.StructuredResponseCreateParams;

@Service
public class DailyRecommendationService {

    private static final String DISCLAIMER =
        "Las recomendaciones brindadas por NutriCam son de carácter "
            + "general y no reemplazan la consulta con un profesional "
            + "de la nutrición.";

    private final NutritionPlanDayRepository
        nutritionPlanDayRepository;

    private final MealRepository mealRepository;

    private final OpenAIClient openAIClient;

    private final String model;

    private final boolean aiEnabled;

    public DailyRecommendationService(
        NutritionPlanDayRepository nutritionPlanDayRepository,
        MealRepository mealRepository,
        OpenAIClient openAIClient,
        @Value("${nutricam.ai.model}") String model,
        @Value("${nutricam.ai.enabled}") boolean aiEnabled
    ) {
        this.nutritionPlanDayRepository =
            nutritionPlanDayRepository;

        this.mealRepository = mealRepository;
        this.openAIClient = openAIClient;
        this.model = model;
        this.aiEnabled = aiEnabled;
    }

    @Transactional
    public DailyRecommendationResponse
            generateOrGetTodayRecommendation(
                Integer userId
            ) {

        if (userId == null) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El identificador del usuario es obligatorio."
            );
        }

        LocalDate today = LocalDate.now();

        NutritionPlanDay planDay =
            nutritionPlanDayRepository
                .findFirstByNutritionPlanUserIdAndPlanDateAndNutritionPlanStatus(
                    userId,
                    today,
                    NutritionPlanStatus.ACTIVE
                )
                .orElseThrow(
                    () -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "No existe un día del plan activo "
                            + "para la fecha actual."
                    )
                );

        if (hasGeneratedRecommendation(planDay)) {
            return toResponse(planDay);
        }

        LocalDate yesterday = today.minusDays(1);

        List<Meal> yesterdayMeals =
            mealRepository
                .findByUserIdAndMealDateOrderByIdAsc(
                    userId,
                    yesterday
                );

        DailyRecommendationMethod method;
        String recommendation;

        if (aiEnabled) {
            AiDailyRecommendationOutput aiOutput =
                generateWithRetry(
                    planDay,
                    yesterdayMeals
                );

            if (isValidAiOutput(aiOutput)) {
                recommendation =
                    normalizeRecommendation(
                        aiOutput.recommendation
                    );

                method = DailyRecommendationMethod.AI;
            } else {
                recommendation =
                    generateRulesFallback(
                        planDay,
                        yesterdayMeals
                    );

                method =
                    DailyRecommendationMethod.RULES_FALLBACK;
            }
        } else {
            recommendation =
                generateRulesFallback(
                    planDay,
                    yesterdayMeals
                );

            method =
                DailyRecommendationMethod.RULES_FALLBACK;
        }

        planDay.setDailyRecommendation(recommendation);

        planDay.setRecommendationStatus(
            DailyRecommendationStatus.GENERATED
        );

        planDay.setRecommendationMethod(method);

        planDay.setRecommendationGeneratedAt(
            LocalDateTime.now()
        );

        NutritionPlanDay savedDay =
            nutritionPlanDayRepository.save(planDay);

        return toResponse(savedDay);
    }

    private boolean hasGeneratedRecommendation(
        NutritionPlanDay planDay
    ) {
        return planDay.getRecommendationStatus()
                == DailyRecommendationStatus.GENERATED
            && planDay.getDailyRecommendation() != null
            && !planDay
                .getDailyRecommendation()
                .isBlank();
    }

    private AiDailyRecommendationOutput generateWithRetry(
        NutritionPlanDay planDay,
        List<Meal> yesterdayMeals
    ) {
        try {
            AiDailyRecommendationOutput firstAttempt =
                callOpenAi(
                    planDay,
                    yesterdayMeals
                );

            if (isValidAiOutput(firstAttempt)) {
                return firstAttempt;
            }
        } catch (Exception exception) {
            // Se realiza un único reintento.
        }

        try {
            AiDailyRecommendationOutput secondAttempt =
                callOpenAi(
                    planDay,
                    yesterdayMeals
                );

            if (isValidAiOutput(secondAttempt)) {
                return secondAttempt;
            }
        } catch (Exception exception) {
            // El fallback por reglas se aplica en el método principal.
        }

        return null;
    }

    private AiDailyRecommendationOutput callOpenAi(
        NutritionPlanDay planDay,
        List<Meal> yesterdayMeals
    ) {
        String prompt =
            buildPrompt(
                planDay,
                yesterdayMeals
            );

        StructuredResponseCreateParams
            <AiDailyRecommendationOutput> params =
                ResponseCreateParams
                    .builder()
                    .model(model)
                    .input(prompt)
                    .text(
                        AiDailyRecommendationOutput.class
                    )
                    .build();

        return openAIClient
            .responses()
            .create(params)
            .output()
            .stream()
            .flatMap(
                outputItem ->
                    outputItem.message().stream()
            )
            .flatMap(
                message ->
                    message.content().stream()
            )
            .flatMap(
                content ->
                    content.outputText().stream()
            )
            .findFirst()
            .orElseThrow(
                () -> new IllegalStateException(
                    "OpenAI no devolvió una "
                        + "recomendación estructurada."
                )
            );
    }

    private String buildPrompt(
        NutritionPlanDay planDay,
        List<Meal> yesterdayMeals
    ) {
        String objective =
            planDay
                .getNutritionPlan()
                .getUserObjective();

        String yesterdayHistory =
            buildYesterdayHistory(yesterdayMeals);

        String todayPlan =
            buildTodayPlan(planDay);

        return """
            Sos el componente de recomendaciones generales de NutriCam.

            NutriCam es una aplicación de acompañamiento para hábitos
            alimentarios saludables. La recomendación debe basarse en
            las Guías Alimentarias para la Población Argentina.

            DATOS DEL USUARIO

            Objetivo:
            %s

            REGISTROS DEL DÍA ANTERIOR

            %s

            PLATOS PREVISTOS PARA HOY

            %s

            INSTRUCCIONES OBLIGATORIAS

            - Escribí en español rioplatense.
            - Generá una recomendación breve, clara y práctica.
            - La recomendación debe tener entre 40 y 100 palabras.
            - Considerá los tipos de comida registrados o faltantes.
            - Considerá los grupos alimentarios registrados.
            - Considerá los platos previstos para hoy.
            - No cuentes calorías.
            - No indiques una cantidad exacta de calorías.
            - No realices diagnósticos.
            - No indiques tratamientos.
            - No recomiendes suplementos.
            - No indiques dietas terapéuticas.
            - No realices recomendaciones para patologías,
              embarazo o menores.
            - No propongas restricciones extremas.
            - No afirmes que el usuario consumió algo que no figura
              en los registros.
            - Si no existen registros de ayer, indicá una orientación
              general basada en el objetivo y en el plan de hoy.
            - El campo safe debe ser true únicamente si la respuesta
              cumple todas estas reglas.
            - observations debe contener códigos breves en mayúsculas,
              por ejemplo: FALTA_FRUTA, BUENA_VARIEDAD,
              FALTA_REGISTRO o PRIORIZAR_HIDRATACION.
            - No incluyas el aviso legal dentro de recommendation.
            """.formatted(
                objective,
                yesterdayHistory,
                todayPlan
            );
    }

    private String buildYesterdayHistory(
        List<Meal> yesterdayMeals
    ) {
        if (yesterdayMeals == null
                || yesterdayMeals.isEmpty()) {

            return "No existen comidas registradas.";
        }

        return yesterdayMeals
            .stream()
            .map(this::describeMeal)
            .collect(
                Collectors.joining(
                    System.lineSeparator()
                )
            );
    }

    private String describeMeal(Meal meal) {
        String groups =
            meal.getFoodGroups() == null
                || meal.getFoodGroups().isEmpty()
                    ? "sin grupos informados"
                    : meal
                        .getFoodGroups()
                        .stream()
                        .map(Enum::name)
                        .sorted()
                        .collect(
                            Collectors.joining(", ")
                        );

        return "- Tipo: "
            + safeText(meal.getMealType())
            + "; comida: "
            + safeText(meal.getMealName())
            + "; cantidad informada: "
            + safeText(meal.getQuantity())
            + "; grupos: "
            + groups
            + ".";
    }

    private String buildTodayPlan(
        NutritionPlanDay planDay
    ) {
        if (planDay.getMeals() == null
                || planDay.getMeals().isEmpty()) {

            return "No existen platos previstos para hoy.";
        }

        return planDay
            .getMeals()
            .stream()
            .map(this::describePlanMeal)
            .collect(
                Collectors.joining(
                    System.lineSeparator()
                )
            );
    }

    private String describePlanMeal(
        NutritionPlanMeal planMeal
    ) {
        RecommendedPlate plate =
            planMeal.getRecommendedPlate();

        String groups =
            plate.getFoodGroups() == null
                || plate.getFoodGroups().isEmpty()
                    ? "sin grupos informados"
                    : plate
                        .getFoodGroups()
                        .stream()
                        .map(Enum::name)
                        .sorted()
                        .collect(
                            Collectors.joining(", ")
                        );

        return "- "
            + planMeal.getMealType().name()
            + ": "
            + safeText(plate.getName())
            + "; grupos: "
            + groups
            + ".";
    }

    private boolean isValidAiOutput(
        AiDailyRecommendationOutput output
    ) {
        if (output == null) {
            return false;
        }

        if (!output.safe) {
            return false;
        }

        if (output.recommendation == null
                || output.recommendation.isBlank()) {

            return false;
        }

        int wordCount =
            output
                .recommendation
                .trim()
                .split("\\s+")
                .length;

        if (wordCount < 25 || wordCount > 130) {
            return false;
        }

        return !containsUnsafeExpression(
            output.recommendation
        );
    }

    private boolean containsUnsafeExpression(
        String recommendation
    ) {
        String normalized =
            recommendation.toLowerCase();

        List<String> forbiddenExpressions =
            List.of(
                "diagnóstico",
                "diagnostico",
                "tratamiento",
                "medicación",
                "medicacion",
                "suplemento",
                "suplementación",
                "suplementacion",
                "dieta terapéutica",
                "dieta terapeutica",
                "deberías consumir exactamente",
                "debes consumir exactamente",
                "calorías por día",
                "calorias por dia"
            );

        return forbiddenExpressions
            .stream()
            .anyMatch(normalized::contains);
    }

    private String normalizeRecommendation(
        String recommendation
    ) {
        String normalized =
            recommendation
                .trim()
                .replaceAll("\\s+", " ");

        if (normalized.endsWith(".")) {
            return normalized;
        }

        return normalized + ".";
    }

    private String generateRulesFallback(
        NutritionPlanDay planDay,
        List<Meal> yesterdayMeals
    ) {
        if (yesterdayMeals == null
                || yesterdayMeals.isEmpty()) {

            return "Ayer no se registraron comidas. "
                + "Para hoy, intentá completar los cuatro momentos "
                + "principales del plan y registrar lo que consumas. "
                + "Priorizá agua, frutas, verduras y preparaciones "
                + "caseras, respetando tus señales de hambre y "
                + "saciedad.";
        }

        Set<FoodGroup> registeredGroups =
            yesterdayMeals
                .stream()
                .filter(
                    meal ->
                        meal.getFoodGroups() != null
                )
                .flatMap(
                    meal ->
                        meal.getFoodGroups().stream()
                )
                .collect(Collectors.toSet());

        Set<String> registeredMealTypes =
            yesterdayMeals
                .stream()
                .map(Meal::getMealType)
                .filter(type -> type != null)
                .map(String::toUpperCase)
                .collect(Collectors.toSet());

        boolean hasFruit =
            registeredGroups.contains(
                FoodGroup.FRUTAS
            );

        boolean hasVegetables =
            registeredGroups.contains(
                FoodGroup.VERDURAS
            );

        boolean hasMainMeals =
            registeredMealTypes.contains("ALMUERZO")
                && registeredMealTypes.contains("CENA");

        if (!hasFruit && !hasVegetables) {
            return "En los registros de ayer no aparecen frutas "
                + "ni verduras. Hoy podés aprovechar los platos "
                + "previstos en tu plan e incorporar alguna fruta "
                + "y una preparación con verduras. Mantené una "
                + "hidratación adecuada y elegí preparaciones "
                + "simples.";
        }

        if (!hasMainMeals) {
            return "Ayer quedaron momentos principales sin registrar. "
                + "Hoy intentá organizar las comidas previstas en el "
                + "plan y registrar almuerzo y cena. Completá el día "
                + "con agua y alimentos variados, sin buscar una "
                + "alimentación perfecta.";
        }

        return "Los registros de ayer muestran distintos momentos de "
            + "comida y grupos alimentarios. Para hoy, continuá con "
            + "los platos previstos en el plan, procurá mantener "
            + "variedad entre frutas, verduras, cereales y fuentes "
            + "de proteína, y sostené una hidratación adecuada.";
    }

    private String safeText(String value) {
        if (value == null || value.isBlank()) {
            return "sin información";
        }

        return value.trim();
    }

    private DailyRecommendationResponse toResponse(
        NutritionPlanDay planDay
    ) {
        DailyRecommendationResponse response =
            new DailyRecommendationResponse();

        response.setPlanDayId(planDay.getId());
        response.setPlanDate(planDay.getPlanDate());

        response.setRecommendation(
            planDay.getDailyRecommendation()
        );

        response.setStatus(
            planDay.getRecommendationStatus()
        );

        response.setMethod(
            planDay.getRecommendationMethod()
        );

        response.setGeneratedAt(
            planDay.getRecommendationGeneratedAt()
        );

        return response;
    }
}