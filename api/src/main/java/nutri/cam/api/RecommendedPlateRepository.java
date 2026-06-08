package nutri.cam.api;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface RecommendedPlateRepository
        extends JpaRepository<RecommendedPlate, Integer> {

    List<RecommendedPlate> findByActiveTrue();

    List<RecommendedPlate> findByActiveTrueOrderByNameAsc();
}