package nutri.cam.api;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/meal-images")
@CrossOrigin(origins = "*")
public class MealImageAnalysisController {

    private final MealImageAnalysisService
        mealImageAnalysisService;

    private final MealImageConfirmationService
        mealImageConfirmationService;

    public MealImageAnalysisController(
        MealImageAnalysisService mealImageAnalysisService,
        MealImageConfirmationService mealImageConfirmationService
    ) {
        this.mealImageAnalysisService =
            mealImageAnalysisService;

        this.mealImageConfirmationService =
            mealImageConfirmationService;
    }

    @PostMapping(
        value = "/analyze",
        consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<MealImageAnalysisResponse>
        analyzeImage(
            @RequestParam Integer userId,
            @RequestParam("image") MultipartFile image
        ) {

        MealImageAnalysisResponse response =
            mealImageAnalysisService.analyze(
                userId,
                image
            );

        return ResponseEntity.ok(response);
    }

    @PostMapping("/{analysisId}/confirm")
    public ResponseEntity<MealImageAnalysisResponse>
        confirmAnalysis(
            @PathVariable Integer analysisId,
            @RequestBody
                MealImageConfirmationRequest request
        ) {

        MealImageAnalysisResponse response =
            mealImageConfirmationService
                .confirmAnalysis(
                    analysisId,
                    request
                );

        return ResponseEntity.ok(response);
    }
}