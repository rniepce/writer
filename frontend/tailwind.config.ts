import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        serif: ['var(--font-serif)', 'Georgia', 'serif'],
        sans: ['var(--font-sans)', 'Helvetica', 'sans-serif'],
      },
      colors: {
        paper: {
            bg: 'var(--paper-bg)',
            text: 'var(--paper-text)',
        },
        nebula: {
            bg: 'var(--nebula-bg)',
            text: 'var(--nebula-text)',
            accent: 'var(--nebula-accent)',
        },
        ui: {
            glass: 'rgba(255, 255, 255, 0.7)',
            darkGlass: 'rgba(0, 0, 0, 0.7)',
        }
      },
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
      }
    },
  },
  plugins: [],
};
export default config;
