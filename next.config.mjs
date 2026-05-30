/** @type {import('next').NextConfig} */
const nextConfig = {
  // Dasturlash rejimidagi Next.js "N" (Dev Tools) belgisini yashirish
  devIndicators: false,
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "images.unsplash.com" },
      { protocol: "https", hostname: "i.pravatar.cc" },
    ],
  },
};

export default nextConfig;
