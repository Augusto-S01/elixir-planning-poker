export const MobileSidebar = {
  mounted() {
    console.log("[MobileSidebar] mounted");
    console.log("[MobileSidebar] initial dataset:", this.el);

    this.el.style.display ="none"; // evita flash visual

    this.pointerMoveFn = this.onPointerMove.bind(this);
    this.pointerUpFn = this.onPointerUp.bind(this);
    this.sidebarPointerDownFn = this.onSidebarPointerDown.bind(this);
    this.handlePointerDownFn = this.onHandlePointerDown.bind(this);
    this.handleClickFn = this.onHandleClick.bind(this);
    this.resizeFn = this.onResize.bind(this);

    this.isDragging = false;
    this.suppressNextClick = false;
    this.sidebarWidth = this.el.getBoundingClientRect().width;

    this.updateOpenState();
    // this.applySnapFromState();
    this.firstUpdated();
    

    // drag para fechar: na própria sidebar (quando aberta)
    this.el.addEventListener("pointerdown", this.sidebarPointerDownFn);

    // drag para abrir: no puxador
    this.bindHandle();

    window.addEventListener("resize", this.resizeFn);

    this.el.style.willChange = "transform";
    this.el.style.display ="flex"; // mostra só depois de tudo pronto
    console.log("[MobileSidebar] mounted complete");
    console.log("[MobileSidebar] final classList:", this.el.classList);
  },
  firstUpdated() {
    console.log("[MobileSidebar] firstUpdated");
    if (!this.isMobile()) {
      this.el.style.transition = "";
      this.el.style.transform = "";
      return;
    }
    this.sidebarWidth = this.el.getBoundingClientRect().width;
    this.el.style.display ="none";

  },
    updated() {
    const prev = this.isOpen;
    this.updateOpenState();

    console.log("[MobileSidebar] updated", { prev, now: this.isOpen, dataset: this.el.dataset.mobileOpen });

    if (prev !== this.isOpen) {
        console.log("[MobileSidebar] state changed, snapping...");
        this.applySnapFromState();
    }

    this.bindHandle();
    },


  destroyed() {
    window.removeEventListener("resize", this.resizeFn);

    this.el.removeEventListener("pointerdown", this.sidebarPointerDownFn);
    document.removeEventListener("pointermove", this.pointerMoveFn);
    document.removeEventListener("pointerup", this.pointerUpFn);

    if (this.handle) {
      this.handle.removeEventListener("pointerdown", this.handlePointerDownFn);
      this.handle.removeEventListener("click", this.handleClickFn, true);
    }
  },

  // --- helpers de estado ---

  isMobile() {
    return window.innerWidth < 768;
  },

  updateOpenState() {
    this.isOpen = this.el.dataset.mobileOpen === "true";
  },

  onResize() {
    this.sidebarWidth = this.el.getBoundingClientRect().width;
    this.applySnapFromState();
  },

  applySnapFromState() {
    // em desktop deixa sem transform (sidebar fixa na direita)
    console.log("[MobileSidebar] applying snap from state", { isOpen: this.isOpen });
    if (!this.isMobile()) {
      this.el.style.transition = "";
      this.el.style.transform = "";
      return;
    }


    this.sidebarWidth = this.el.getBoundingClientRect().width;

    // animação suave quando estado muda via click
    this.el.style.transition = "transform 250ms ease-out";

    const offset = this.isOpen ? 0 : this.sidebarWidth;
    this.el.style.transform = `translateX(${offset}px)`;
  },

  bindHandle() {
    const newHandle = document.getElementById("mobile-sidebar-handle");

    if (newHandle === this.handle) return;

    if (this.handle) {
      this.handle.removeEventListener("pointerdown", this.handlePointerDownFn);
      this.handle.removeEventListener("click", this.handleClickFn, true);
    }

    this.handle = newHandle;

    if (this.handle) {
      this.handle.addEventListener("pointerdown", this.handlePointerDownFn);
      this.handle.addEventListener("click", this.handleClickFn, true);
    }
  },

  // --- lógica de drag ---

  startDrag(startX) {
    if (!this.isMobile()) return;

    this.isDragging = true;
    this.startX = startX;
    this.sidebarWidth = this.el.getBoundingClientRect().width;

    this.startOpen = this.isOpen;
    this.startOffset = this.startOpen ? 0 : this.sidebarWidth;
    this.currentOffset = this.startOffset;

    // sem animação durante o drag
    this.el.style.transition = "none";

    document.addEventListener("pointermove", this.pointerMoveFn);
    document.addEventListener("pointerup", this.pointerUpFn);
  },

  onPointerMove(ev) {
    if (!this.isDragging) return;

    const delta = ev.clientX - this.startX;
    let pos = this.startOffset + delta;

    if (pos < 0) pos = 0;
    if (pos > this.sidebarWidth) pos = this.sidebarWidth;

    this.currentOffset = pos;
    this.el.style.transform = `translateX(${pos}px)`;
  },

  onPointerUp(ev) {
    if (!this.isDragging) return;

    this.isDragging = false;

    document.removeEventListener("pointermove", this.pointerMoveFn);
    document.removeEventListener("pointerup", this.pointerUpFn);

    const delta = ev.clientX - this.startX;
    const pos = this.currentOffset ?? this.startOffset;
    const threshold = this.sidebarWidth / 2;

    const shouldOpen = pos < threshold;

    if (Math.abs(delta) > 6) {
      this.suppressNextClick = true;
    }

    // volta a animação
    this.el.style.transition = "transform 200ms ease-out";

    // atualiza visualmente já, pra sensação ficar boa
    const finalOffset = shouldOpen ? 0 : this.sidebarWidth;
    this.el.style.transform = `translateX(${finalOffset}px)`;

    if (shouldOpen !== this.startOpen) {
      // sincroniza estado com LiveView
      this.pushEvent("toggle-mobile-sidebar", {});
    }
  },

  // --- handlers específicos ---

  // drag para abrir: no handle
  onHandlePointerDown(ev) {
    console.log("[MobileSidebar] handle pointerdown");
    ev.preventDefault();
    ev.stopPropagation();
    this.startDrag(ev.clientX);
  },

  onHandleClick(ev) {
    if (this.suppressNextClick) {
      ev.preventDefault();
      ev.stopPropagation();
      this.suppressNextClick = false;
      return;
    }
    // se não teve drag, o click passa e LiveView trata
  },

  // drag para fechar: na borda direita da própria sidebar quando aberta
  onSidebarPointerDown(ev) {
    if (!this.isMobile()) return;
    if (!this.isOpen) return;

    const xFromRight = window.innerWidth - ev.clientX;
    if (xFromRight > 60) {
      // não é na borda → deixa rolar scroll/click normal
      return;
    }

    console.log("[MobileSidebar] sidebar edge pointerdown");
    ev.preventDefault();
    ev.stopPropagation();
    this.startDrag(ev.clientX);
  }
};