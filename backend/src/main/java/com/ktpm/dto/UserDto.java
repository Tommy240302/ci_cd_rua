package com.ktpm.dto;

import com.ktpm.entity.User;
import lombok.*;
import org.springframework.data.jpa.repository.query.JSqlParserUtils;

import java.nio.file.Paths;
import java.util.*;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
public class UserDto {
    private String email;
    private String displayName;
    private Boolean isEnabled;
    private List<String> roles;
    private String avatar;
    private String gender;
    private String phone;
    private Integer age;

    public UserDto(User user) {

        roles = new ArrayList<>();
        avatar = user.getAvatar();
        email = user.getEmail();
        displayName = user.getDisplayName();
        isEnabled = user.getIsEnabled();
        gender = user.getGender();
        phone = user.getPhone();
        age= user.getAge();
    }
}
    