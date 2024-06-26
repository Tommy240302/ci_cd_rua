package com.ktpm.response;

import lombok.*;


@Builder
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Response {
    private Object data;
    private String message;
    private boolean success;
}
