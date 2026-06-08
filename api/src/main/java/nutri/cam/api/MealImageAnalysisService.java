package nutri.cam.api;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Base64;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.type.TypeReference;

@Service
public class MealImageAnalysisService {

    private static final long MAX_FILE_SIZE =
        8L * 1024L * 1024L;

    private static final Set<String> ALLOWED_CONTENT_TYPES =
        Set.of(
            "image/jpeg",
            "image/png",
            "image/webp"
        );

    private final MealImageAnalysisRepository analysisRepository;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    private final String apiKey;
    private final String model;
    private final boolean aiEnabled;

    public MealImageAnalysisService(
        MealImageAnalysisRepository analysisRepository,
        UserRepository userRepository,
        ObjectMapper objectMapper,
        @Value("${OPENAI_API_KEY:}") String apiKey,
        @Value("${nutricam.ai.model}") String model,
        @Value("${nutricam.ai.enabled}") boolean aiEnabled
    ) {
        this.analysisRepository = analysisRepository;
        this.userRepository = userRepository;
        this.objectMapper = objectMapper;
        this.apiKey = apiKey;
        this.model = model;
        this.aiEnabled = aiEnabled;

        this.httpClient = HttpClient
            .newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .build();
    }

    @Transactional
    public MealImageAnalysisResponse analyze(
        Integer userId,
        MultipartFile image
    ) {
        validateUser(userId);
        validateImage(image);

        MealImageAnalysis analysis =
            createPendingAnalysis(userId, image);

        analysis = analysisRepository.save(analysis);

        try {
            AiMealImageAnalysisOutput aiOutput =
                analyzeWithOpenAi(image);

            applyAiResult(analysis, aiOutput);

            analysis.setStatus(
                MealImageAnalysisStatus.ANALYZED
            );

            MealImageAnalysis savedAnalysis =
                analysisRepository.save(analysis);

            return toResponse(savedAnalysis);
        } catch (Exception exception) {
            analysis.setStatus(
                MealImageAnalysisStatus.FAILED
            );

            analysis.setWarning(
                limitText(
                    "No se pudo analizar la imagen: "
                        + safeMessage(exception),
                    500
                )
            );

            analysisRepository.save(analysis);

            throw new ResponseStatusException(
                HttpStatus.SERVICE_UNAVAILABLE,
                "No se pudo analizar la imagen.",
                exception
            );
        }
    }

    private void validateUser(Integer userId) {
        if (userId == null) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El identificador del usuario es obligatorio."
            );
        }

        if (!userRepository.existsById(userId)) {
            throw new ResponseStatusException(
                HttpStatus.NOT_FOUND,
                "No se encontró el usuario."
            );
        }
    }

    private void validateImage(MultipartFile image) {
        if (image == null || image.isEmpty()) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "Debés seleccionar una imagen."
            );
        }

        String contentType = image.getContentType();

        if (contentType == null ||
            !ALLOWED_CONTENT_TYPES.contains(contentType)) {

            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "El archivo debe ser una imagen JPG, PNG o WEBP."
            );
        }

        if (image.getSize() > MAX_FILE_SIZE) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST,
                "La imagen no puede superar los 8 MB."
            );
        }
    }

    private MealImageAnalysis createPendingAnalysis(
        Integer userId,
        MultipartFile image
    ) {
        MealImageAnalysis analysis =
            new MealImageAnalysis();

        analysis.setUserId(userId);

        analysis.setOriginalFileName(
            normalizeFileName(
                image.getOriginalFilename()
            )
        );

        analysis.setContentType(
            image.getContentType()
        );

        analysis.setFileSize(
            image.getSize()
        );

        analysis.setStatus(
            MealImageAnalysisStatus.PENDING
        );

        return analysis;
    }

    private AiMealImageAnalysisOutput analyzeWithOpenAi(
        MultipartFile image
    ) throws Exception {
        if (!aiEnabled) {
            throw new IllegalStateException(
                "La integración con IA está deshabilitada."
            );
        }

        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException(
                "OPENAI_API_KEY no está configurada."
            );
        }

        String base64 =
            Base64.getEncoder()
                .encodeToString(image.getBytes());

        String dataUrl =
            "data:"
                + image.getContentType()
                + ";base64,"
                + base64;

        Map<String, Object> schema =
            buildJsonSchema();

        Map<String, Object> body =
            Map.of(
                "model",
                model,
                "store",
                false,
                "input",
                List.of(
                    Map.of(
                        "role",
                        "user",
                        "content",
                        List.of(
                            Map.of(
                                "type",
                                "input_text",
                                "text",
                                buildPrompt()
                            ),
                            Map.of(
                                "type",
                                "input_image",
                                "image_url",
                                dataUrl
                            )
                        )
                    )
                ),
                "text",
                Map.of(
                    "format",
                    Map.of(
                        "type",
                        "json_schema",
                        "name",
                        "meal_image_analysis",
                        "strict",
                        true,
                        "schema",
                        schema
                    )
                )
            );

        String requestBody =
            objectMapper.writeValueAsString(body);

        HttpRequest request =
            HttpRequest
                .newBuilder()
                .uri(
                    URI.create(
                        "https://api.openai.com/v1/responses"
                    )
                )
                .timeout(Duration.ofSeconds(60))
                .header(
                    "Authorization",
                    "Bearer " + apiKey
                )
                .header(
                    "Content-Type",
                    "application/json"
                )
                .POST(
                    HttpRequest.BodyPublishers
                        .ofString(requestBody)
                )
                .build();

        HttpResponse<String> response =
            httpClient.send(
                request,
                HttpResponse.BodyHandlers.ofString()
            );

        if (response.statusCode() < 200 ||
            response.statusCode() >= 300) {

            throw new IllegalStateException(
                "OpenAI respondió con código "
                    + response.statusCode()
                    + ": "
                    + response.body()
            );
        }

        String outputText =
            extractOutputText(response.body());

        AiMealImageAnalysisOutput result =
            objectMapper.readValue(
                outputText,
                AiMealImageAnalysisOutput.class
            );

        validateAiOutput(result);

        return result;
    }

    private Map<String, Object> buildJsonSchema() {
        return Map.of(
            "type",
            "object",
            "additionalProperties",
            false,
            "properties",
            Map.of(
                "suggestedMealName",
                Map.of(
                    "type",
                    "string"
                ),
                "detectedFoods",
                Map.of(
                    "type",
                    "array",
                    "items",
                    Map.of(
                        "type",
                        "string"
                    )
                ),
                "foodGroups",
                Map.of(
                    "type",
                    "array",
                    "items",
                    Map.of(
                        "type",
                        "string",
                        "enum",
                        List.of(
                            "FRUTAS",
                            "VERDURAS",
                            "LEGUMBRES",
                            "CEREALES_Y_DERIVADOS",
                            "PAPA_BATATA_MANDIOCA",
                            "LECHE_YOGUR_Y_QUESO",
                            "CARNES",
                            "PESCADOS",
                            "HUEVOS",
                            "FRUTOS_SECOS_Y_SEMILLAS",
                            "ACEITES_Y_GRASAS",
                            "AZUCARES_Y_DULCES"
                        )
                    )
                ),
                "warning",
                Map.of(
                    "type",
                    "string"
                ),
                "valid",
                Map.of(
                    "type",
                    "boolean"
                )
            ),
            "required",
            List.of(
                "suggestedMealName",
                "detectedFoods",
                "foodGroups",
                "warning",
                "valid"
            )
        );
    }

    private String buildPrompt() {
        return """
            Analizá la imagen de una comida para NutriCam.

            Tu tarea es identificar únicamente lo que sea visible
            con un grado razonable de certeza.

            Reglas obligatorias:

            - Escribí en español.
            - Proponé un nombre breve para la comida.
            - Enumerá los alimentos visibles.
            - Seleccioná solamente grupos alimentarios permitidos.
            - No inventes ingredientes ocultos.
            - No estimes cantidades.
            - No estimes porciones.
            - No estimes calorías.
            - No realices diagnósticos.
            - No indiques tratamientos.
            - No recomiendes suplementos.
            - Si la imagen no permite identificar una comida,
              valid debe ser false.
            - Si existe incertidumbre, explicala brevemente
              en warning.
            - Si no hay advertencias, warning debe ser
              una cadena vacía.
            """;
    }

    private String extractOutputText(
        String responseBody
    ) throws Exception {
        JsonNode root =
            objectMapper.readTree(responseBody);

        JsonNode output =
            root.path("output");

        if (!output.isArray()) {
            throw new IllegalStateException(
                "OpenAI no devolvió output."
            );
        }

        for (JsonNode item : output) {
            if (!"message".equals(
                item.path("type").asText()
            )) {
                continue;
            }

            JsonNode content =
                item.path("content");

            if (!content.isArray()) {
                continue;
            }

            for (JsonNode contentItem : content) {
                if ("output_text".equals(
                    contentItem
                        .path("type")
                        .asText()
                )) {
                    String text =
                        contentItem
                            .path("text")
                            .asText();

                    if (!text.isBlank()) {
                        return text;
                    }
                }
            }
        }

        throw new IllegalStateException(
            "OpenAI no devolvió texto estructurado."
        );
    }

    private void validateAiOutput(
        AiMealImageAnalysisOutput output
    ) {
        if (output == null) {
            throw new IllegalStateException(
                "El análisis recibido está vacío."
            );
        }

        if (!output.isValid()) {
            throw new IllegalStateException(
                "La imagen no contiene una comida identificable."
            );
        }

        if (output.getSuggestedMealName() == null ||
            output.getSuggestedMealName().isBlank()) {

            throw new IllegalStateException(
                "La IA no devolvió un nombre sugerido."
            );
        }

        if (output.getDetectedFoods() == null ||
            output.getDetectedFoods().isEmpty()) {

            throw new IllegalStateException(
                "La IA no detectó alimentos."
            );
        }
    }

    private void applyAiResult(
        MealImageAnalysis analysis,
        AiMealImageAnalysisOutput output
    ) {
        analysis.setSuggestedMealName(
            limitText(
                output.getSuggestedMealName().trim(),
                200
            )
        );

        Set<String> detectedFoods =
            new HashSet<>();

        for (String food : output.getDetectedFoods()) {
            if (food != null && !food.isBlank()) {
                detectedFoods.add(
                    limitText(food.trim(), 150)
                );
            }
        }

        analysis.setDetectedFoods(detectedFoods);

        Set<FoodGroup> foodGroups =
            new HashSet<>();

        if (output.getFoodGroups() != null) {
            for (String group : output.getFoodGroups()) {
                try {
                    foodGroups.add(
                        FoodGroup.valueOf(group)
                    );
                } catch (IllegalArgumentException ignored) {
                    // Se ignoran valores ajenos al enum.
                }
            }
        }

        analysis.setFoodGroups(foodGroups);

        analysis.setWarning(
            limitText(
                output.getWarning(),
                500
            )
        );
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
            analysis.getDetectedFoods()
        );

        response.setFoodGroups(
            analysis.getFoodGroups()
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

    private String normalizeFileName(
        String fileName
    ) {
        if (fileName == null ||
            fileName.isBlank()) {

            return "imagen";
        }

        String normalized =
            fileName
                .replace("\\", "/");

        int lastSlash =
            normalized.lastIndexOf('/');

        if (lastSlash >= 0) {
            normalized =
                normalized.substring(
                    lastSlash + 1
                );
        }

        return limitText(normalized, 255);
    }

    private String limitText(
        String value,
        int maxLength
    ) {
        if (value == null) {
            return null;
        }

        String normalized = value.trim();

        if (normalized.length() <= maxLength) {
            return normalized;
        }

        return normalized.substring(
            0,
            maxLength
        );
    }

    private String safeMessage(
        Exception exception
    ) {
        String message =
            exception.getMessage();

        if (message == null ||
            message.isBlank()) {

            return exception
                .getClass()
                .getSimpleName();
        }

        return message;
    }
}