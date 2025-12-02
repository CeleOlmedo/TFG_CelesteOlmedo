package nutri.cam.api;

import java.time.LocalDate;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import lombok.Data;

@Entity
@Data

public class User {

    @Id
    @GeneratedValue
    
    private Integer id;

    private String name;
    private String surname;
    private LocalDate birthDate;

    private String email;
    private String password;



}



