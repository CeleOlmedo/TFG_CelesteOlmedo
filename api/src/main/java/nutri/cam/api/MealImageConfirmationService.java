package nutri.cam.api;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class MealImageConfirmationService {

    private final MealImageAnalysisRepository
        analysisRepository;

    private final MealRepository mealRepository;

    private final UserRepository userRepository;

    public MealImageConfirmationService(
        MealImageAnalysisRepository analysisRepository,
        MealRepository mealRepository,
        UserRepository userRepository
    ) {
        this.analysisRepository = analysisRepository;
        this.mealRepository = mealRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public MealImageAnalysisResponse confirmAnalysis(
        Integer analysisId,
        MealImageConfirmationRequest request
    ) {
        validateRequest(analysisId, request);

        MealImageAnalysis analysis =
            analysisRepository
                .findByIdAndUserId(
                    analysisId,
                    request.getUserId()
                )
                .orElseThrow(
                    () -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "No se encontró el análisis de imagen."
                    )
                );

        validateAnalysisStatus(analysis);

        Meal meal = new Meal();

        meal.setUserId(request.getUserId());

        meal.setMealName(
            request.getMealName().trim()
        );

        meal.setMealType(
            normalizeMealType(
                request.getMealType()
            )
        );

        meal.setQuantity(
            request.getQuantity().trim()
        );

        meal.setMealDate(
            request.getMealDate() == null
                ? LocalDate.now()
                : request.getMealDate()
        );

        meal.setRegistrationSource(
            MealRegistrationSource.IMAGE
        );

        meal.setRecommendedPlate(null);

        meal.setFoodGroups(
            new HashSet<>(
                request.getFoodGroups()
            )
        );

        Meal savedMeal =
            mealRepository.save(meal);

        analysis.setMeal(savedMeal);

        analysis.setStatus(
            MealImageAnalysisStatus.CONFIRMED
        );

        analysis.setConfirmedAt(
            LocalDateTime.now()
        );

        MealImageAnalysis savedAnalysis =
            analysisRepository.save(analysis);

        return toResponse(savedAnalysis);
    }

    private void validateRequest(
        Integer analysisId,
        MealImageConfirmationRequest request
    ) {
        if (analysisId == null) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El identificador del análisis es obligatorio."
            );
        }

        if (request == null) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "La solicitud es obligatoria."
            );
        }

        if (request.getUserId() == null) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El usuario es obligatorio."
            );
        }

        if (!userRepository.existsById(
            request.getUserId()
        )) {
            throw new ResponseStatusException(
                HttpStatus.NOT_FOUND,
                "No se encontró el usuario."
            );
        }

        if (isBlank(request.getMealName())) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El nombre de la comida es obligatorio."
            );
        }

        if (request.getMealName().trim().length() > 200) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El nombre de la comida no puede superar "
                    + "los 200 caracteres."
            );
        }

        if (isBlank(request.getMealType())) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El tipo de comida es obligatorio."
            );
        }

        validateMealType(request.getMealType());

        if (isBlank(request.getQuantity())) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "La cantidad es obligatoria."
            );
        }

        if (request.getQuantity().trim().length() > 100) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "La cantidad no puede superar "
                    + "los 100 caracteres."
            );
        }

        if (request.getFoodGroups() == null
                || request.getFoodGroups().isEmpty()) {

            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "Debés seleccionar al menos un "
                    + "grupo alimentario."
            );
        }
    }

    private void validateAnalysisStatus(
        MealImageAnalysis analysis
    ) {
        if (analysis.getStatus()
                == MealImageAnalysisStatus.CONFIRMED
            || analysis.getMeal() != null) {

            throw new ResponseStatusException(
                HttpStatus.CONFLICT,
                "El análisis ya fue confirmado."
            );
        }

        if (analysis.getStatus()
                != MealImageAnalysisStatus.ANALYZED) {

            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "Solo se pueden confirmar análisis "
                    + "completados correctamente."
            );
        }
    }

    private void validateMealType(
        String mealType
    ) {
        try {
            PlateMealType.valueOf(
                normalizeMealType(mealType)
            );
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El tipo de comida no es válido."
            );
        }
    }

    private String normalizeMealType(
        String mealType
    ) {
        return mealType
            .trim()
            .toUpperCase();
    }

    private boolean isBlank(String value) {
        return value == null
            || value.trim().isEmpty();
    }

    private MealImageAnalysisResponse toResponse(
        MealImageAnalysis analysis
    ) {
        MealImageAnalysisResponse response =
            new MealImageAnalysisResponse();

        response.setId(analysis.getId());
        response.setUserId(analysis.getUserId());

        response.setSuggestedMealName(
            analysis.getSuggestedMealName()
        );

        response.setDetectedFoods(
            new HashSet<>(
                analysis.getDetectedFoods()
            )
        );

        response.setFoodGroups(
            new HashSet<>(
                analysis.getFoodGroups()
            )
        );

        response.setStatus(
            analysis.getStatus()
        );

        response.setWarning(
            analysis.getWarning()
        );

        response.setCreatedAt(
            analysis.getCreatedAt()
        );

        response.setConfirmedAt(
            analysis.getConfirmedAt()
        );

        if (analysis.getMeal() != null) {
            response.setMealId(
                analysis.getMeal().getId()
            );
        }

        return response;
    }
}