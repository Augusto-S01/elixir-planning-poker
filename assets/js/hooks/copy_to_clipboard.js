export const CopyToClipboard = {
  mounted() {
    this.handleEvent("copy_to_clipboard", ({ text }) => {
        navigator.clipboard.writeText(text)
        tooltip = document.getElementById("copy-room-link-tooltip");
        tooltip.setAttribute("data-tip", "Copied!");

        setTimeout(() => {
          tooltip.setAttribute("data-tip", "Copy room link");
        }, 1000);
    })


  }
};