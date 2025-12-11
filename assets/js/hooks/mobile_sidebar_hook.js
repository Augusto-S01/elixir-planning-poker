export const MobileSidebar = {
  mounted() {
    this.pointerMoveFn = this.onPointerMove.bind(this);
    this.pointerUpFn = this.onPointerUp.bind(this);
    this.sidebarPointerDownFn = this.onSidebarPointerDown.bind(this);
    this.handlePointerDownFn = this.onHandlePointerDown.bind(this);
    this.handleClickFn = this.onHandleClick.bind(this);
    this.resizeFn = this.onResize.bind(this);

    this.isDragging = false;
    this.suppressNextClick = false;

    this.updateOpenState();
    this.sidebarWidth = this.el.getBoundingClientRect().width;

    this.el.style.willChange = "transform";


    if (this.isMobile()) {
      this.snap({ animate: false });
    } else {
      this.el.style.transition = "";
      this.el.style.transform = "";
    }

    this.el.addEventListener("pointerdown", this.sidebarPointerDownFn);

    this.bindHandle();

    window.addEventListener("resize", this.resizeFn);

  },

  updated() {
    const prev = this.isOpen;
    this.updateOpenState();


    if (this.isMobile()) {
      this.sidebarWidth = this.el.getBoundingClientRect().width;
      if (prev !== this.isOpen) {
        this.snap({ animate: true });
      }
    } else {
      this.el.style.transition = "";
      this.el.style.transform = "";
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


  isMobile() {
    return window.innerWidth < 768;
  },

  updateOpenState() {
    this.isOpen = this.el.dataset.mobileOpen === "true";
  },

  onResize() {
    if (!this.isMobile()) {
      this.el.style.transition = "";
      this.el.style.transform = "";
      return;
    }

    this.sidebarWidth = this.el.getBoundingClientRect().width;
    this.snap({ animate: false });
  },

  snap({ animate } = { animate: true }) {
    if (!this.isMobile()) return;

    const width = this.sidebarWidth || this.el.getBoundingClientRect().width;
    const offset = this.isOpen ? 0 : width;

    this.el.style.transition = animate ? "transform 250ms ease-out" : "none";
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
      this.handle.style.touchAction = "none";
      this.handle.addEventListener("pointerdown", this.handlePointerDownFn);
      this.handle.addEventListener("click", this.handleClickFn, true);
    }
  },

  startDrag(startX) {
    if (!this.isMobile()) return;

    this.isDragging = true;
    this.startX = startX;
    this.sidebarWidth = this.el.getBoundingClientRect().width;

    this.startOpen = this.isOpen;
    this.startOffset = this.startOpen ? 0 : this.sidebarWidth;
    this.currentOffset = this.startOffset;

    this.el.style.transition = "none";

    this.el.style.transform = `translateX(${this.startOffset}px)`;

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

    this.el.style.transition = "transform 200ms ease-out";

    const finalOffset = shouldOpen ? 0 : this.sidebarWidth;
    this.el.style.transform = `translateX(${finalOffset}px)`;

    if (shouldOpen !== this.startOpen) {
      this.pushEvent("toggle-mobile-sidebar", {});
    }
  },


  onSidebarPointerDown(ev) {
    if (!this.isMobile()) return;
    if (!this.isOpen) return;

    const rect = this.el.getBoundingClientRect();
    const xFromRight = rect.right - ev.clientX;

    if (xFromRight > 40) return;

    ev.preventDefault();
    ev.stopPropagation();
    this.startDrag(ev.clientX);
  },

  onHandlePointerDown(ev) {
    if (!this.isMobile()) return;
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
  }
};
