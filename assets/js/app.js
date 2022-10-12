// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let Hooks = {};
Hooks.DraggableHand = {
  mounted() {
    dragItem = document.querySelector("#hand");
    centerItem = document.querySelector("#ball");
    circleItem = document.querySelector("#back_circle");
    digitalTimer = document.querySelector("#digital_timer");

    o = {
      active: false,
      currentX: 0,
      currentY: 0,
      dragItem,
      centerItem,
      circleItem,
      digitalTimer,
      deg: 0,
    };
    this.el.addEventListener("touchstart", (e) => dragStart(e, o), false);
    this.el.addEventListener("touchend", (e) => dragEnd(e, this, o), false);
    this.el.addEventListener("touchmove", (e) => drag(e, o), false);

    this.el.addEventListener("mousedown", (e) => dragStart(e, o), false);
    this.el.addEventListener("mouseup", (e) => dragEnd(e, this, o), false);
    this.el.addEventListener("mousemove", (e) => drag(e, o), false);
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

function dragStart(e, o) {
  console.log(e);
  console.log(centerItem);

  if (e.target.id == "hand_bar") {
    o.active = true;
  }
}

function dragEnd(e, hook, o) {
  // console.log(e);
  // console.log(o.deg / 6);
  if (o.active) {
    hook.pushEvent("update-timer", { time: o.deg / 6 });
  }
  o.active = false;
}

function drag(e, o) {
  if (o.active) {
    e.preventDefault();
    let currentX, currentY;
    if (e.type === "touchmove") {
      currentX = e.touches[0].clientX;
      currentY = e.touches[0].clientY;
    } else {
      currentX = e.clientX;
      currentY = e.clientY;
    }
    let { x, y, width, height } = o.centerItem.getBoundingClientRect();
    let cx = width / 2 + x;
    let cy = height / 2 + y;
    // console.log(x, y, currentX, currentY);
    o.deg = rotate(currentX, cx, currentY, cy, e.target);
    let percent = (o.deg / 360) * 100;
    o.dragItem.setAttribute("style", "--tw-rotate: " + (o.deg + 180) + "deg;");
    o.circleItem.setAttribute(
      "style",
      "background: conic-gradient(#5B74A9A0 " + percent + "%, #5B74A933 0);"
    );
    updateDigitalTime(o.digitalTimer, (o.deg / 6) * 60);
    // console.log(deg, percent);
  }
}

function rotate(x, ox, y, oy, el) {
  let rad = Math.atan2(y - oy, x - ox);
  return ((rad * 180) / Math.PI + 90 + 360) % 360;
}

function updateDigitalTime(el, seconds) {
  el.textContent =
    String(Math.floor(seconds / 60)).padStart(2, "0") +
    ":" +
    String(Math.floor(seconds % 60)).padStart(2, "0");
}

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) => topbar.show());
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
