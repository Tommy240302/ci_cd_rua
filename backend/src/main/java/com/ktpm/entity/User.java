package com.ktpm.entity;

import com.google.api.services.storage.Storage;
import jakarta.persistence.*;
import jakarta.transaction.Transactional;
import lombok.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.*;


@Table(name="users")
@Entity
@Builder
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class User implements UserDetails {

    @Id
    @Column(length = 100)
    private String email;
    private String password;
    private String displayName;
    private Boolean isEnabled;
    private Integer age;
    private String gender;
    private String phone;
    private String avatar;


    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY)
    private List<Deck> decks;


    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return null;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return this.email;
    }


    @Override
    public boolean isEnabled() {
        return this.isEnabled;
    }


    public User(String email) {
        this.email = email;
    }
}
