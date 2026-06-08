package nutri.cam.api;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.openai.client.OpenAIClient;
import com.openai.client.okhttp.OpenAIOkHttpClient;

@Configuration
public class OpenAiConfig {

    @Bean
    public OpenAIClient openAIClient() {
        return OpenAIOkHttpClient.fromEnv();
    }
}