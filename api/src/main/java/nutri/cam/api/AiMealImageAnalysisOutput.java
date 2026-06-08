package nutri.cam.api;

import java.util.Set;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class AiMealImageAnalysisOutput {

    private String suggestedMealName;

    private Set<String> detectedFoods;

    private Set<String> foodGroups;

    private String warning;

    private boolean valid;
}