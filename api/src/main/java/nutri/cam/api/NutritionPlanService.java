package nutri.cam.api;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class NutritionPlanService {

    private static final int PLAN_DAYS = 7;

    private static final List<PlateMealType> REQUIRED_MEAL_TYPES =
        List.of(
            PlateMealType.DESAYUNO,
            PlateMealType.ALMUERZO,
            PlateMealType.MERIENDA,
            PlateMealType.CENA
        );

    private final NutritionPlanRepository nutritionPlanRepository;
    private final UserRepository userRepository;
    private final RecommendedPlateRepository
        recommendedPlateRepository;
    private final NutritionPlanMealRepository
        nutritionPlanMealRepository;

    public NutritionPlanService(
        NutritionPlanRepository nutritionPlanRepository,
        UserRepository userRepository,
        RecommendedPlateRepository recommendedPlateRepository,
        NutritionPlanMealRepository nutritionPlanMealRepository
    ) {
        this.nutritionPlanRepository =
            nutritionPlanRepository;
        this.userRepository = userRepository;
        this.recommendedPlateRepository =
            recommendedPlateRepository;
        this.nutritionPlanMealRepository =
            nutritionPlanMealRepository;
    }

    @Transactional
    public NutritionPlanResponse generateWeeklyPlan(
        Integer userId
    ) {
        User user = userRepository
            .findById(userId)
            .orElseThrow(
                () -> new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "El usuario no existe."
                )
            );

        validateUserObjective(user);

        List<RecommendedPlate> activePlates =
            recommendedPlateRepository
                .findByActiveTrueOrderByNameAsc();

        Map<PlateMealType, List<RecommendedPlate>>
            platesByMealType =
                classifyPlatesByMealType(activePlates);

        validateCatalog(platesByMealType);

        deactivatePreviousPlans(userId);

        LocalDate startDate =
            calculatePlanStartDate(LocalDate.now());

        LocalDate endDate =
            startDate.plusDays(PLAN_DAYS - 1);

        NutritionPlan plan = new NutritionPlan();

        plan.setUser(user);
        plan.setStartDate(startDate);
        plan.setEndDate(endDate);
        plan.setUserObjective(user.getObjective());
        plan.setStatus(NutritionPlanStatus.ACTIVE);
        plan.setGenerationMethod(
            NutritionPlanGenerationMethod.RULES
        );

        Map<PlateMealType, Integer> selectionIndexes =
            new EnumMap<>(PlateMealType.class);

        Map<Integer, Integer> plateUsageCount =
            new HashMap<>();

        for (PlateMealType mealType : REQUIRED_MEAL_TYPES) {
            selectionIndexes.put(mealType, 0);
        }

        for (int dayIndex = 0;
             dayIndex < PLAN_DAYS;
             dayIndex++) {

            NutritionPlanDay planDay =
                createPlanDay(
                    startDate.plusDays(dayIndex),
                    dayIndex + 1
                );

            for (int mealIndex = 0;
                 mealIndex < REQUIRED_MEAL_TYPES.size();
                 mealIndex++) {

                PlateMealType mealType =
                    REQUIRED_MEAL_TYPES.get(mealIndex);

                RecommendedPlate selectedPlate =
                    selectPlate(
                        platesByMealType.get(mealType),
                        mealType,
                        selectionIndexes,
                        plateUsageCount
                    );

                NutritionPlanMeal planMeal =
                    createPlanMeal(
                        selectedPlate,
                        mealType,
                        mealIndex + 1,
                        user.getObjective()
                    );

                planDay.addMeal(planMeal);
            }

            plan.addDay(planDay);
        }

        NutritionPlan savedPlan =
            nutritionPlanRepository.save(plan);

        validateGeneratedPlan(savedPlan);

        return toResponse(savedPlan);
    }

    @Transactional(readOnly = true)
    public NutritionPlanResponse getActivePlan(
        Integer userId
    ) {
        NutritionPlan plan =
            nutritionPlanRepository
                .findFirstByUserIdAndStatusOrderByCreatedAtDesc(
                    userId,
                    NutritionPlanStatus.ACTIVE
                )
                .orElseThrow(
                    () -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "El usuario no tiene un plan activo."
                    )
                );

        return toResponse(plan);
    }

    @Transactional
    public NutritionPlanResponse replacePlanMeal(
        Integer userId,
        Integer mealId
    ) {
        User user = userRepository
            .findById(userId)
            .orElseThrow(
                () -> new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "El usuario no existe."
                )
            );

        validateUserObjective(user);

        NutritionPlan activePlan =
            nutritionPlanRepository
                .findFirstByUserIdAndStatusOrderByCreatedAtDesc(
                    userId,
                    NutritionPlanStatus.ACTIVE
                )
                .orElseThrow(
                    () -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "El usuario no tiene un plan activo."
                    )
                );

        NutritionPlanMeal planMeal =
            nutritionPlanMealRepository
                .findById(mealId)
                .orElseThrow(
                    () -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "La comida seleccionada no existe."
                    )
                );

        validateMealBelongsToActivePlan(
            activePlan,
            planMeal
        );

        RecommendedPlate replacementPlate =
            selectReplacementPlate(
                activePlan,
                planMeal
            );

        planMeal.setRecommendedPlate(
            replacementPlate
        );

        planMeal.setReason(
            buildSelectionReason(
                replacementPlate,
                planMeal.getMealType(),
                activePlan.getUserObjective()
            )
        );

        resetRecommendationForDay(
            planMeal.getNutritionPlanDay()
        );

        nutritionPlanMealRepository.save(planMeal);

        return toResponse(activePlan);
    }

    private void validateMealBelongsToActivePlan(
        NutritionPlan activePlan,
        NutritionPlanMeal planMeal
    ) {
        NutritionPlanDay planDay =
            planMeal.getNutritionPlanDay();

        if (
            planDay == null
            || planDay.getNutritionPlan() == null
            || !activePlan.getId().equals(
                planDay.getNutritionPlan().getId()
            )
        ) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "La comida seleccionada no pertenece "
                    + "al plan activo del usuario."
            );
        }
    }

    private RecommendedPlate selectReplacementPlate(
        NutritionPlan activePlan,
        NutritionPlanMeal currentMeal
    ) {
        List<RecommendedPlate> candidates =
            recommendedPlateRepository
                .findByActiveTrueOrderByNameAsc()
                .stream()
                .filter(
                    plate ->
                        plate.getAllowedMealTypes() != null
                        && plate.getAllowedMealTypes()
                            .contains(
                                currentMeal.getMealType()
                            )
                )
                .filter(
                    plate ->
                        !plate.getId().equals(
                            currentMeal
                                .getRecommendedPlate()
                                .getId()
                        )
                )
                .toList();

        if (candidates.isEmpty()) {
            throw new ResponseStatusException(
                HttpStatus.CONFLICT,
                "No existe otro plato activo compatible "
                    + "con "
                    + formatMealType(
                        currentMeal.getMealType()
                    )
                    + "."
            );
        }

        Map<Integer, Integer> plateUsageCount =
            calculatePlateUsage(activePlan);

        return candidates
            .stream()
            .min(
                Comparator
                    .comparingInt(
                        (RecommendedPlate plate) ->
                            plateUsageCount
                                .getOrDefault(
                                    plate.getId(),
                                    0
                                )
                    )
                    .thenComparing(
                        RecommendedPlate::getName,
                        String.CASE_INSENSITIVE_ORDER
                    )
            )
            .orElseThrow(
                () -> new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "No se pudo seleccionar un plato "
                        + "alternativo."
                )
            );
    }

    private Map<Integer, Integer> calculatePlateUsage(
        NutritionPlan activePlan
    ) {
        Map<Integer, Integer> plateUsageCount =
            new HashMap<>();

        for (NutritionPlanDay day : activePlan.getDays()) {
            for (NutritionPlanMeal meal : day.getMeals()) {
                Integer plateId =
                    meal.getRecommendedPlate().getId();

                plateUsageCount.merge(
                    plateId,
                    1,
                    Integer::sum
                );
            }
        }

        return plateUsageCount;
    }

    private void resetRecommendationForDay(
        NutritionPlanDay planDay
    ) {
        planDay.setDailyRecommendation(null);
        planDay.setRecommendationStatus(
            DailyRecommendationStatus.PENDING
        );
        planDay.setRecommendationMethod(null);
        planDay.setRecommendationGeneratedAt(null);
    }

    private void validateUserObjective(User user) {
        String objective = user.getObjective();

        if (objective == null || objective.trim().isEmpty()) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El usuario debe seleccionar un objetivo "
                    + "antes de generar el plan."
            );
        }
    }

    private Map<PlateMealType, List<RecommendedPlate>>
            classifyPlatesByMealType(
                List<RecommendedPlate> activePlates
            ) {

        Map<PlateMealType, List<RecommendedPlate>> result =
            new EnumMap<>(PlateMealType.class);

        for (PlateMealType mealType : REQUIRED_MEAL_TYPES) {
            result.put(mealType, new ArrayList<>());
        }

        for (RecommendedPlate plate : activePlates) {
            if (plate.getAllowedMealTypes() == null) {
                continue;
            }

            for (PlateMealType mealType :
                    REQUIRED_MEAL_TYPES) {

                if (
                    plate.getAllowedMealTypes()
                        .contains(mealType)
                ) {
                    result.get(mealType).add(plate);
                }
            }
        }

        for (List<RecommendedPlate> plates :
                result.values()) {

            plates.sort(
                Comparator.comparing(
                    RecommendedPlate::getName,
                    String.CASE_INSENSITIVE_ORDER
                )
            );
        }

        return result;
    }

    private void validateCatalog(
        Map<PlateMealType, List<RecommendedPlate>>
            platesByMealType
    ) {
        for (PlateMealType mealType :
                REQUIRED_MEAL_TYPES) {

            List<RecommendedPlate> candidates =
                platesByMealType.get(mealType);

            if (candidates == null || candidates.isEmpty()) {
                throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "No existen platos activos compatibles con "
                        + mealType.name() + "."
                );
            }
        }
    }

    private void deactivatePreviousPlans(
        Integer userId
    ) {
        List<NutritionPlan> activePlans =
            nutritionPlanRepository
                .findByUserIdAndStatusOrderByCreatedAtDesc(
                    userId,
                    NutritionPlanStatus.ACTIVE
                );

        for (NutritionPlan activePlan : activePlans) {
            activePlan.setStatus(
                NutritionPlanStatus.INACTIVE
            );
        }

        if (!activePlans.isEmpty()) {
            nutritionPlanRepository.saveAll(activePlans);
            nutritionPlanRepository.flush();
        }
    }

    private LocalDate calculatePlanStartDate(
        LocalDate currentDate
    ) {
        if (
            currentDate.getDayOfWeek()
                == DayOfWeek.MONDAY
        ) {
            return currentDate;
        }

        return currentDate.with(
            TemporalAdjusters.next(DayOfWeek.MONDAY)
        );
    }

    private NutritionPlanDay createPlanDay(
        LocalDate date,
        int displayOrder
    ) {
        NutritionPlanDay day =
            new NutritionPlanDay();

        day.setPlanDate(date);
        day.setDisplayOrder(displayOrder);

        day.setDailyRecommendation(null);

        day.setRecommendationStatus(
            DailyRecommendationStatus.PENDING
        );

        day.setRecommendationMethod(null);
        day.setRecommendationGeneratedAt(null);

        return day;
    }

    private RecommendedPlate selectPlate(
        List<RecommendedPlate> candidates,
        PlateMealType mealType,
        Map<PlateMealType, Integer> selectionIndexes,
        Map<Integer, Integer> plateUsageCount
    ) {
        int startIndex =
            selectionIndexes.getOrDefault(
                mealType,
                0
            );

        RecommendedPlate selectedPlate = null;
        int selectedIndex = startIndex;
        int lowestUsage = Integer.MAX_VALUE;

        for (int offset = 0;
             offset < candidates.size();
             offset++) {

            int candidateIndex =
                (startIndex + offset)
                    % candidates.size();

            RecommendedPlate candidate =
                candidates.get(candidateIndex);

            int usageCount =
                plateUsageCount.getOrDefault(
                    candidate.getId(),
                    0
                );

            if (usageCount < lowestUsage) {
                lowestUsage = usageCount;
                selectedPlate = candidate;
                selectedIndex = candidateIndex;
            }
        }

        if (selectedPlate == null) {
            throw new ResponseStatusException(
                HttpStatus.CONFLICT,
                "No se pudo seleccionar un plato para "
                    + mealType.name() + "."
            );
        }

        plateUsageCount.merge(
            selectedPlate.getId(),
            1,
            Integer::sum
        );

        selectionIndexes.put(
            mealType,
            (selectedIndex + 1)
                % candidates.size()
        );

        return selectedPlate;
    }

    private NutritionPlanMeal createPlanMeal(
        RecommendedPlate plate,
        PlateMealType mealType,
        int displayOrder,
        String objective
    ) {
        NutritionPlanMeal planMeal =
            new NutritionPlanMeal();

        planMeal.setMealType(mealType);
        planMeal.setRecommendedPlate(plate);
        planMeal.setDisplayOrder(displayOrder);

        planMeal.setReason(
            buildSelectionReason(
                plate,
                mealType,
                objective
            )
        );

        return planMeal;
    }

    private String buildSelectionReason(
        RecommendedPlate plate,
        PlateMealType mealType,
        String objective
    ) {
        String foodGroupsText =
            plate.getFoodGroups() == null
                || plate.getFoodGroups().isEmpty()
                    ? "distintos alimentos"
                    : plate.getFoodGroups()
                        .stream()
                        .map(this::formatFoodGroup)
                        .sorted()
                        .reduce(
                            (first, second) ->
                                first + ", " + second
                        )
                        .orElse("distintos alimentos");

        return "Se seleccionó para "
            + formatMealType(mealType)
            + " porque es compatible con ese momento "
            + "del día e incluye "
            + foodGroupsText
            + ". La elección acompaña el objetivo "
            + formatObjective(objective)
            + " mediante una propuesta general y variada.";
    }

    private void validateGeneratedPlan(
        NutritionPlan plan
    ) {
        if (plan.getDays() == null
            || plan.getDays().size() != PLAN_DAYS) {

            throw new IllegalStateException(
                "El plan generado no contiene siete días."
            );
        }

        for (NutritionPlanDay day : plan.getDays()) {
            if (
                day.getMeals() == null
                || day.getMeals().size()
                    != REQUIRED_MEAL_TYPES.size()
            ) {
                throw new IllegalStateException(
                    "Cada día debe contener cuatro comidas."
                );
            }

            for (PlateMealType requiredType :
                    REQUIRED_MEAL_TYPES) {

                long occurrences =
                    day.getMeals()
                        .stream()
                        .filter(
                            meal ->
                                meal.getMealType()
                                    == requiredType
                        )
                        .count();

                if (occurrences != 1) {
                    throw new IllegalStateException(
                        "Cada día debe contener exactamente "
                            + "una comida de tipo "
                            + requiredType.name()
                            + "."
                    );
                }
            }
        }
    }

    private NutritionPlanResponse toResponse(
        NutritionPlan plan
    ) {
        NutritionPlanResponse response =
            new NutritionPlanResponse();

        response.setId(plan.getId());
        response.setUserId(plan.getUser().getId());
        response.setStartDate(plan.getStartDate());
        response.setEndDate(plan.getEndDate());
        response.setUserObjective(
            plan.getUserObjective()
        );
        response.setStatus(plan.getStatus());
        response.setGenerationMethod(
            plan.getGenerationMethod()
        );
        response.setCreatedAt(plan.getCreatedAt());
        response.setUpdatedAt(plan.getUpdatedAt());

        List<NutritionPlanDayResponse> dayResponses =
            plan.getDays()
                .stream()
                .sorted(
                    Comparator.comparing(
                        NutritionPlanDay::getDisplayOrder
                    )
                )
                .map(this::toDayResponse)
                .toList();

        response.setDays(dayResponses);

        return response;
    }

    private NutritionPlanDayResponse toDayResponse(
        NutritionPlanDay day
    ) {
        NutritionPlanDayResponse response =
            new NutritionPlanDayResponse();

        response.setId(day.getId());
        response.setPlanDate(day.getPlanDate());
        response.setDisplayOrder(
            day.getDisplayOrder()
        );
        response.setDailyRecommendation(
            day.getDailyRecommendation()
        );
        response.setRecommendationStatus(
            day.getRecommendationStatus()
        );
        response.setRecommendationMethod(
            day.getRecommendationMethod()
        );
        response.setRecommendationGeneratedAt(
            day.getRecommendationGeneratedAt()
        );

        List<NutritionPlanMealResponse> mealResponses =
            day.getMeals()
                .stream()
                .sorted(
                    Comparator.comparing(
                        NutritionPlanMeal::getDisplayOrder
                    )
                )
                .map(this::toMealResponse)
                .toList();

        response.setMeals(mealResponses);

        return response;
    }

    private NutritionPlanMealResponse toMealResponse(
        NutritionPlanMeal meal
    ) {
        RecommendedPlate plate =
            meal.getRecommendedPlate();

        NutritionPlanMealResponse response =
            new NutritionPlanMealResponse();

        response.setId(meal.getId());
        response.setMealType(meal.getMealType());
        response.setRecommendedPlateId(
            plate.getId()
        );
        response.setPlateName(plate.getName());
        response.setDescription(
            plate.getDescription()
        );
        response.setPortion(plate.getPortion());
        response.setEstimatedCalories(
            plate.getEstimatedCalories()
        );
        response.setEstimatedProtein(
            plate.getEstimatedProtein()
        );
        response.setPreparationTimeMinutes(
            plate.getPreparationTimeMinutes()
        );
        response.setProcessingLevel(
            plate.getProcessingLevel()
        );

        if (plate.getFoodGroups() != null) {
            response.setFoodGroups(
                new java.util.HashSet<>(
                    plate.getFoodGroups()
                )
            );
        }

        response.setReason(meal.getReason());
        response.setDisplayOrder(
            meal.getDisplayOrder()
        );

        return response;
    }

    private String formatMealType(
        PlateMealType mealType
    ) {
        return switch (mealType) {
            case DESAYUNO -> "el desayuno";
            case ALMUERZO -> "el almuerzo";
            case MERIENDA -> "la merienda";
            case CENA -> "la cena";
            case COLACION -> "la colación";
        };
    }

    private String formatObjective(
        String objective
    ) {
        return switch (objective) {
            case "BAJAR_PESO" ->
                "de mejorar hábitos para bajar de peso";
            case "MANTENER_PESO" ->
                "de mantener el peso";
            case "GANAR_MASA" ->
                "de acompañar la ganancia de masa";
            case "HABITOS_SALUDABLES" ->
                "de incorporar hábitos saludables";
            default ->
                "seleccionado por el usuario";
        };
    }

    private String formatFoodGroup(
        FoodGroup foodGroup
    ) {
        return foodGroup
            .name()
            .toLowerCase()
            .replace('_', ' ');
    }
}