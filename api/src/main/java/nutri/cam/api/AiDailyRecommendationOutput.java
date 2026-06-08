package nutri.cam.api;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonClassDescription;
import com.fasterxml.jackson.annotation.JsonPropertyDescription;

@JsonClassDescription(
    "Recomendación alimentaria diaria general, segura y no clínica, "
        + "basada en las GAPA, el objetivo del usuario y sus registros."
)
public class AiDailyRecommendationOutput {

    @JsonPropertyDescription(
        "Recomendación breve en español rioplatense, de entre "
            + "40 y 100 palabras. Debe ser clara, empática, práctica "
            + "y no debe incluir diagnósticos, tratamientos, dietas "
            + "terapéuticas, suplementación ni prescripción calórica."
    )
    public String recommendation;

    @JsonPropertyDescription(
        "Observaciones estructuradas que justifican la recomendación. "
            + "Utilizar únicamente códigos breves en mayúsculas."
    )
    public List<String> observations;

    @JsonPropertyDescription(
        "Indica si la recomendación es una orientación general segura "
            + "y no contiene contenido médico o extremo."
    )
    public boolean safe;
}