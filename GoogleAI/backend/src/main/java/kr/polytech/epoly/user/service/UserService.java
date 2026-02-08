// user/service/UserService.java — 사용자 서비스
package kr.polytech.epoly.user.service;

import kr.polytech.epoly.user.entity.User;
import kr.polytech.epoly.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public User findById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("사용자를 찾을 수 없습니다: " + id));
    }

    public User findByUserId(String userId) {
        return userRepository.findByUserId(userId)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("사용자를 찾을 수 없습니다: " + userId));
    }

    public List<User> findByUserType(String userType) {
        return userRepository.findByUserType(userType);
    }

    public List<User> searchUsers(String keyword) {
        return userRepository.searchByKeyword(keyword);
    }

    @Transactional
    public User createUser(User user) {
        if (userRepository.existsByUserId(user.getUserId())) {
            throw new IllegalArgumentException("이미 존재하는 사용자 ID입니다: " + user.getUserId());
        }
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        return userRepository.save(user);
    }

    @Transactional
    public User updateUser(Long id, User updated) {
        User user = findById(id);
        user.setName(updated.getName());
        user.setEmail(updated.getEmail());
        user.setPhone(updated.getPhone());
        user.setDepartment(updated.getDepartment());
        user.setCampus(updated.getCampus());
        return userRepository.save(user);
    }

    @Transactional
    public void deactivateUser(Long id) {
        User user = findById(id);
        user.setStatus("INACTIVE");
        userRepository.save(user);
    }

    public long countActiveByType(String userType) {
        return userRepository.countByUserTypeAndActive(userType);
    }
}
