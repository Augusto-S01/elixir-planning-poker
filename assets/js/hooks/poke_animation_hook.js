export const PokeAnimationHook = {
  mounted() {
    this.handleEvent("poke_animation", (payload) => {
      this.animatePoke(payload)
    })
  },

animatePoke({ from, to }) {
  const container = this.el
  const fromAvatar = document.getElementById(`avatar-${from}`)
  const toAvatar = document.getElementById(`avatar-${to}`)
  if (!container || !fromAvatar || !toAvatar) return

  const C = container.getBoundingClientRect()
  const F = fromAvatar.getBoundingClientRect()
  const T = toAvatar.getBoundingClientRect()

  const startX = F.left + F.width/2 - C.left
  const startY = F.top  + F.height/2 - C.top

  const hitX = T.left + T.width/2 - C.left + (Math.random() - 0.5) * 30
  const hitY = T.top  + T.height/2 - C.top  + (Math.random() - 0.5) * 30

  const size = 14 + Math.random() * 10

  const ball = document.createElement("div")
  ball.classList.add("paper-ball")
  ball.style.position = "absolute"
  ball.style.width = `${size}px`
  ball.style.height = `${size}px`
  ball.style.left = `${startX}px`
  ball.style.top = `${startY}px`
  ball.style.pointerEvents = "none"

  ball.innerHTML = `
    <svg viewBox="0 0 24 24">
      <path
        d="M4 10.5 9 3l6 1 4 6-2 8-7 3-6-5z"
        fill="#f5f5f5"
        stroke="#d4d4d4"
        stroke-width="1.2"
        stroke-linejoin="round"
      />
    </svg>
  `
  container.appendChild(ball)

  const dx = hitX - startX
  const dy = hitY - startY
  const distance = Math.sqrt(dx*dx + dy*dy)

  const steps = 60
  const windStrength = (Math.random() - 0.5) * 80  

  const arc = Math.min(80, distance * 0.35)


  const keyframes = []

  for (let i = 0; i <= steps; i++) {
    const t = i / steps

    
    const baseX = startX + dx * t
    const baseY = startY + dy * t

    const parabola = -4 * Math.pow(t - 0.5, 2) + 1

    const curveY = baseY - parabola * arc

    const wind = windStrength * Math.sin(t * Math.PI)

    const rot = t * 400 + Math.sin(t * 10) * 5

    keyframes.push({
      transform: `translate(${(baseX + wind) - startX}px, ${(curveY) - startY}px) rotate(${rot}deg)`
    })
  }

  const impactAngle = Math.atan2(dy, dx)

  const fleeDist = 25 + Math.random() * 40

  const fleeX = hitX + Math.cos(impactAngle) * fleeDist
  const fleeY = hitY + Math.sin(impactAngle) * (fleeDist * 0.6)

  const bounce = [
    { transform: `translate(${dx}px, ${dy}px) scale(1.3, 0.6)` },
    { transform: `translate(${dx}px, ${dy - 8}px) scale(.8, 1.2)` },
    { transform: `translate(${fleeX - startX}px, ${fleeY - startY}px) scale(1)` }
  ]

  const animation = ball.animate(
    [...keyframes, ...bounce],
    {
      duration: 1000,
      easing: "ease-out",
      fill: "forwards"
    }
  )

  animation.onfinish = () => {
  ball.animate(
    [
      { opacity: 1 },
      { opacity: 0.3 },
      { opacity: 1 },
      { opacity: 0.3 },
      { opacity: 1 },
      { opacity: 0 }
    ],
    {
      duration: 300,
      easing: "linear",
      fill: "forwards"
    }
  ).onfinish = () => ball.remove()
}

}

}
