package com.ktpm.service;


import com.ktpm.util.Helper;
import com.ktpm.dao.UserDao;
import com.ktpm.dto.UserDto;
import com.ktpm.entity.User;

import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserDao userDao;
    private final Helper helper;
    private final FirebaseStorageService firebaseStorageService;
    private final PasswordEncoder passwordEncoder;

    // update thông tin theo.  name, gender, age, phone, dataOfBirth, avatar
    public UserDto updateUser(String displayName, String gender, Integer age, String phone, String dataOfBirth, MultipartFile avatar) throws IOException {
        // kiểm tra thông tin nào cập nhập thì cập nhập. thông tin còn lại hông quan tâm
        User user = helper.getUser();
        if (displayName!= null) {
            user.setDisplayName(displayName);
        }
        if (gender != null) {
            user.setGender(gender);
        }
        if (age != null) {
            user.setAge(age);
        }
        if (phone != null) {
            user.setPhone(phone);
        }


        if (avatar != null) {
            String url =  firebaseStorageService.save("avatar", avatar);
            user.setAvatar(url);
        }

        return new UserDto(userDao.save(user));
    }


    public UserDto getInfoUser() {
        return new UserDto(helper.getUser());
    }
    public UserDto getInfoOtherUser(String email) {
        User user = userDao.findById(email).orElseThrow();
        return new UserDto(user);
    }


    public User loadUserByEmail(String email) {
        return userDao.findById(email)
                .orElseThrow(() -> new UsernameNotFoundException("not found user!"));
    }

    public void changePW(String newPW) {
        User user = helper.getUser();
        user.setPassword(passwordEncoder.encode(newPW));
        userDao.save(user);
    }
}
