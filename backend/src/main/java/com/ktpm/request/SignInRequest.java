package com.ktpm.request;


import lombok.Builder;
import lombok.Getter;

@Builder
@Getter
public class SignInRequest {
    private String email;
    private String password;
    private Boolean isRemember;
}
