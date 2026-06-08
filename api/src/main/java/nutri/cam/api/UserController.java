package nutri.cam.api;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;


@RestController
@CrossOrigin("*")
public class UserController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserController(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/register")
    public ResponseEntity<User> register(@RequestBody User user) {

        String normalizedEmail = user.getEmail().trim().toLowerCase();

        if (userRepository.existsByEmail(normalizedEmail)) {
            return ResponseEntity
                    .status(HttpStatus.CONFLICT)
                    .build();
        }

        String password = user.getPassword();

        boolean validPassword =
                password != null
                && password.length() >= 6
                && password.matches(".*[A-Za-z].*")
                && password.matches(".*[0-9].*");

        if (!validPassword) {
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .build();
        }

        user.setEmail(normalizedEmail);
        user.setPassword(passwordEncoder.encode(password));

        User savedUser = userRepository.save(user);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(savedUser);
    }

    @PostMapping("/login")
    public ResponseEntity<User> login(@RequestBody User loginRequest) {

        if (loginRequest.getEmail() == null
                || loginRequest.getEmail().isBlank()
                || loginRequest.getPassword() == null
                || loginRequest.getPassword().isBlank()) {

            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .build();
        }

        String normalizedEmail = loginRequest
                .getEmail()
                .trim()
                .toLowerCase();

        User existingUser = userRepository.findByEmail(normalizedEmail);

        if (existingUser == null) {
            return ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .build();
        }

        boolean passwordMatches = passwordEncoder.matches(
                loginRequest.getPassword(),
                existingUser.getPassword()
        );

        if (!passwordMatches) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .build();
        }

        return ResponseEntity.ok(existingUser);
    }

    @PutMapping("/update/{id}")
    public User updateUser(@PathVariable Integer id, @RequestBody User updatedUser) {
        User user = userRepository.findById(id).orElse(null);

        if (user == null) return null;

        user.setName(updatedUser.getName());
        user.setSurname(updatedUser.getSurname());
        user.setBirthDate(updatedUser.getBirthDate());
        user.setObjective(updatedUser.getObjective());

        return userRepository.save(user);
    }


}
