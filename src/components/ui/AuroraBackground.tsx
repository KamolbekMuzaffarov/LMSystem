// Layer 1: living mesh-gradient ("aurora"). Sits behind all glass and makes it feel alive.
export function AuroraBackground() {
  return (
    <div className="pointer-events-none fixed inset-0 -z-10 overflow-hidden bg-ink">
      {/* deep base wash — multi-stop for a rich, expensive sense of depth */}
      <div className="absolute inset-0 bg-[radial-gradient(140%_120%_at_50%_-15%,#1b1640_0%,#120e28_36%,#0a0a14_62%,#06060e_100%)]" />

      {/* top spotlight beam — the "stage light" that reads as premium */}
      <div className="absolute left-1/2 top-0 h-[55vh] w-[85vw] -translate-x-1/2 bg-[radial-gradient(closest-side,rgba(167,139,250,0.20),rgba(167,139,250,0)_72%)]" />

      {/* slow-rotating conic sheen — iridescent shimmer, the costly detail */}
      <div className="absolute left-1/2 top-1/2 h-[170vmax] w-[170vmax] -translate-x-1/2 -translate-y-1/2 animate-aurora-spin opacity-[0.10] blur-[110px] bg-[conic-gradient(from_0deg_at_50%_50%,transparent_0deg,#7c3aed_55deg,transparent_130deg,#2563eb_200deg,transparent_270deg,#c026d3_330deg,transparent_360deg)]" />

      {/* drifting color blobs — refined, restrained opacities */}
      <div className="absolute -left-[15%] top-[-10%] h-[58vw] w-[58vw] rounded-full bg-aurora-violet/30 blur-[130px] animate-aurora-drift" />
      <div className="absolute right-[-12%] top-[6%] h-[50vw] w-[50vw] rounded-full bg-aurora-blue/28 blur-[140px] animate-aurora-drift-slow" />
      <div className="absolute bottom-[-18%] left-[16%] h-[54vw] w-[54vw] rounded-full bg-aurora-pink/24 blur-[150px] animate-aurora-drift [animation-delay:-8s]" />
      <div className="absolute bottom-[-6%] right-[4%] h-[40vw] w-[40vw] rounded-full bg-aurora-fuchsia/22 blur-[130px] animate-aurora-drift-slow [animation-delay:-14s]" />
      <div className="absolute left-[40%] top-[34%] h-[34vw] w-[34vw] rounded-full bg-aurora-cyan/16 blur-[140px] animate-aurora-drift [animation-delay:-4s]" />

      {/* fine grid overlay — masked to fade at the edges (the Linear/Vercel signature) */}
      <div className="bg-grid absolute inset-0" />

      {/* vignette to keep the edges grounded and the center luminous */}
      <div className="absolute inset-0 bg-[radial-gradient(125%_125%_at_50%_42%,transparent_48%,rgba(4,4,10,0.78)_100%)]" />
    </div>
  );
}
