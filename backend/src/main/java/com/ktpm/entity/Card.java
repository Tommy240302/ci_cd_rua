package com.ktpm.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.Date;

@Table(name="cards")
@Entity
@Builder
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Card {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    private Integer id;

    @Column(nullable = false)
    private String term;

    @Column(nullable = false)
    private String definition;
    private String image;
    private String example;
    private Boolean isFavourite;
    private Boolean isRemembered;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_deck", nullable = false)
    private Deck deck;
}