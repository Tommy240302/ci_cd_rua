package com.ktpm.dto;

import com.ktpm.entity.Card;
import lombok.*;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
public class CardDto {
    private Integer id;
    private String term;
    private String definition;
    private String image;
    private String example;
    private Boolean isFavourite;
    private Boolean isRemembered;
    private DeckOfCard deck;

    public CardDto(Card card){
        this.id = card.getId();
        this.term = card.getTerm();
        this.definition = card.getDefinition();
        this.image = card.getImage();
        this.example = card.getExample();
        this.isFavourite = card.getIsFavourite();
        this.isRemembered = card.getIsRemembered();
        this.deck = new DeckOfCard(card.getDeck());
    }
}