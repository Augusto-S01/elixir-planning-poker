export const DealCards = {
  mounted() {
    this.handleEvent("deal_cards_animation", () => {
      this.animateCards();
    });
  },

  animateCards() {
    const cards = document.querySelectorAll(".player-card");
    if (!cards.length) return;

    cards.forEach((card, i) => {
      card.classList.add("card-deal-animation");

      
      card.style.animationDelay = `${i * 120}ms`;
      
     
      card.addEventListener("animationend", () => {
        card.classList.remove("card-deal-animation");
        card.style.animationDelay = "";
      }, { once: true });
    });
  }
};

